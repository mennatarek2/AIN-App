import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/connectivity_service.dart';
import '../../../../core/network/api_providers.dart';
import '../../../../core/widgets/cached_app_image.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/state/auth_state_simple.dart';
import '../../data/data_sources/profile_local_data_source.dart';
import '../../data/profile_remote_data_source.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../domain/profile_model.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/use_cases/use_cases.dart';

// ─── Trust badge ──────────────────────────────────────────────────────────────

enum TrustBadge {
  newcomer,    // 0–19   🌱 gray
  contributor, // 20–49  ⭐ blue
  trusted,     // 50–99  🛡️ emerald
  guardian;    // 100+   👑 gold

  static TrustBadge fromPoints(int points) {
    if (points >= 100) return TrustBadge.guardian;
    if (points >= 50)  return TrustBadge.trusted;
    if (points >= 20)  return TrustBadge.contributor;
    return TrustBadge.newcomer;
  }

  static TrustBadge fromString(String? raw) {
    return switch ((raw ?? '').toLowerCase()) {
      'guardian'    => TrustBadge.guardian,
      'trusted'     => TrustBadge.trusted,
      'contributor' => TrustBadge.contributor,
      _             => TrustBadge.newcomer,
    };
  }

  String get label => switch (this) {
    TrustBadge.newcomer    => 'مستخدم جديد',
    TrustBadge.contributor => 'مساهم',
    TrustBadge.trusted     => 'موثوق',
    TrustBadge.guardian    => 'حارس',
  };

  String get emoji => switch (this) {
    TrustBadge.newcomer    => '🌱',
    TrustBadge.contributor => '⭐',
    TrustBadge.trusted     => '🛡️',
    TrustBadge.guardian    => '👑',
  };

  Color get color => switch (this) {
    TrustBadge.newcomer    => const Color(0xFF697184),
    TrustBadge.contributor => const Color(0xFF3B82F6),
    TrustBadge.trusted     => const Color(0xFF10B981),
    TrustBadge.guardian    => const Color(0xFFF59E0B),
  };

  /// Progress toward the next tier [0.0 – 1.0] per backend contract.
  double progressFor(int points) {
    if (points >= 100) return 1.0;

    final (currentMin, nextThreshold) = switch (points) {
      >= 50 => (50, 100),
      >= 20 => (20, 50),
      _ => (0, 20),
    };

    return (points - currentMin) / (nextThreshold - currentMin);
  }

  int pointsToNext(int points) {
    if (points >= 100) return 0;

    final nextThreshold = switch (points) {
      >= 50 => 100,
      >= 20 => 50,
      _ => 20,
    };

    return nextThreshold - points;
  }
}

// ─── TrustInfo (from GET /api/social/me/trust) ───────────────────────────────

class TrustInfo {
  const TrustInfo({
    this.trustPoints = 0,
    this.badge = TrustBadge.newcomer,
    this.totalReports = 0,
    this.resolvedReports = 0,
    this.pendingReports = 0,
  });

  final int trustPoints;
  final TrustBadge badge;
  final int totalReports;
  final int resolvedReports;
  final int pendingReports;

  factory TrustInfo.fromJson(Map<String, dynamic> json) {
    final points = _parseInt(json['trustPoints'] ?? json['points'] ?? json['trust'] ?? 0);
    final badge  = TrustBadge.fromString(json['badge']?.toString()) ;
    final total    = _parseInt(json['totalReports'] ?? json['total'] ?? 0);
    final resolved = _parseInt(json['resolvedReports'] ?? json['resolved'] ?? 0);
    final pending  = _parseInt(json['pendingReports'] ?? json['pending'] ?? json['underReview'] ?? 0);
    return TrustInfo(
      trustPoints:    points,
      badge:          badge,
      totalReports:   total,
      resolvedReports: resolved,
      pendingReports: pending,
    );
  }

  static int _parseInt(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }
}


/// UI representation of user profile
///
/// Contains all user profile information needed for the UI.
class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.username,
    this.ssn = '',
    required this.isVerified,
    required this.points,
    this.badge = 'Newcomer',
    this.profilePhotoUrl,
  });

  factory UserProfile.fromModel(ProfileModel model) {
    return UserProfile(
      id: model.id,
      name: model.displayName,
      email: model.email,
      phone: model.phoneNumber,
      username: model.userName,
      ssn: model.ssn,
      isVerified: model.isVerified,
      points: model.trustPoints,
      badge: model.badge,
      profilePhotoUrl: model.profilePhotoUrl,
    );
  }

  final String id;
  final String name;
  final String email;
  final String phone;
  final String username;
  final String ssn;
  final bool isVerified;
  final int points;
  /// Badge from API: 'Newcomer' | 'Contributor' | 'Trusted' | 'Guardian'
  final String badge;
  final String? profilePhotoUrl;

  int get pointsToNextLevel {
    if (points < 20)  return 20 - points;
    if (points < 50)  return 50 - points;
    if (points < 100) return 100 - points;
    return 0;
  }

  String get level {
    return switch (badge.toLowerCase()) {
      'guardian'    => 'حارس',
      'trusted'     => 'موثوق',
      'contributor' => 'مساهم',
      _             => 'مستخدم جديد',
    };
  }

  Color get levelDotColor {
    return switch (badge.toLowerCase()) {
      'guardian'    => const Color(0xFFF59E0B),
      'trusted'     => const Color(0xFF10B981),
      'contributor' => const Color(0xFF3B82F6),
      _             => const Color(0xFF697184),
    };
  }

  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? username,
    String? ssn,
    bool? isVerified,
    int? points,
    String? badge,
    String? profilePhotoUrl,
    bool clearPhoto = false,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      username: username ?? this.username,
      ssn: ssn ?? this.ssn,
      isVerified: isVerified ?? this.isVerified,
      points: points ?? this.points,
      badge: badge ?? this.badge,
      profilePhotoUrl:
          clearPhoto ? null : (profilePhotoUrl ?? this.profilePhotoUrl),
    );
  }

  @override
  String toString() =>
      'UserProfile(id: $id, name: $name, points: $points, badge: $badge, photoUrl: $profilePhotoUrl)';
}

/// Notifier for managing profile state
///
/// Responsibilities:
/// - Fetch profile from API on app start
/// - Handle profile updates
/// - Manage loading/error states
/// - Provide methods for UI to modify profile
class ProfileNotifier extends StateNotifier<AsyncValue<UserProfile>> {
  ProfileNotifier({
    required ProfileRepository repository,
    required GetProfileUseCase getProfileUseCase,
    required UpdateProfileUseCase updateProfileUseCase,
  }) : _getProfileUseCase = getProfileUseCase,
       _updateProfileUseCase = updateProfileUseCase,
       super(const AsyncValue.loading()) {
    _initialize();
  }

  final GetProfileUseCase _getProfileUseCase;
  final UpdateProfileUseCase _updateProfileUseCase;

  /// Initialize profile by loading cache; API fetch runs after auth is ready.
  Future<void> _initialize() async {
    try {
      print('[ProfileNotifier] Initializing profile');

      final cached = await _getProfileUseCase.getCached();
      if (cached != null) {
        print('[ProfileNotifier] Loaded cached profile, photoUrl: ${cached.profilePhotoUrl}');
        state = AsyncValue.data(UserProfile.fromModel(cached));
      } else {
        state = const AsyncValue.loading();
      }
    } catch (e, st) {
      print('[ProfileNotifier] Error during initialization: $e');
      state = AsyncValue.error(e, st);
    }
  }

  /// Fetch profile from API
  Future<void> _fetchProfile() async {
    try {
      print('[ProfileNotifier] Fetching profile from API');
      state = const AsyncValue.loading();

      await _getProfileUseCase();

      final profile = await _getProfileUseCase.getCached();
      if (profile != null) {
        print('[ProfileNotifier] Profile fetched successfully');
        print('[ProfileNotifier] Profile photo URL: ${profile.profilePhotoUrl}');
        state = AsyncValue.data(UserProfile.fromModel(profile));
      } else {
        throw Exception('Profile is empty');
      }
    } catch (e, st) {
      print('[ProfileNotifier] Error fetching profile: $e');
      state = AsyncValue.error(e, st);
    }
  }

  /// Refresh profile from API
  Future<void> refresh() async {
    print('[ProfileNotifier] Refreshing profile');
    await _fetchProfile();
  }

  /// Update user display name
  ///
  /// Updates local state immediately, then syncs to API
  Future<void> updateName(String name) async {
    final current = state.value;
    if (current == null) return;

    print('[ProfileNotifier] Updating name to: $name');
    state = AsyncValue.data(current.copyWith(name: name));

    try {
      await _updateProfileUseCase(displayName: name);
    } catch (e) {
      print('[ProfileNotifier] Error updating name: $e');
      // Revert on failure
      state = AsyncValue.data(current);
    }
  }

  /// Update user phone number
  ///
  /// Updates local state immediately, then syncs to API
  Future<void> updatePhone(String phone) async {
    final current = state.value;
    if (current == null) return;

    print('[ProfileNotifier] Updating phone to: $phone');
    state = AsyncValue.data(current.copyWith(phone: phone));

    try {
      await _updateProfileUseCase(phoneNumber: phone);
    } catch (e) {
      print('[ProfileNotifier] Error updating phone: $e');
      // Revert on failure
      state = AsyncValue.data(current);
    }
  }

  /// Update username locally only (read-only from API).
  Future<void> updateUsername(String username) async {
    final current = state.value;
    if (current == null) return;

    print('[ProfileNotifier] Username is read-only from API');
    state = AsyncValue.data(current.copyWith(username: username));
  }

  /// Update profile photo
  ///
  /// Parameters:
  /// - [photoPath]: Local file path to image (jpg/png)
  ///
  /// Shows local preview immediately, uploads to API, then fetches
  /// the server-returned URL to keep the state fresh.
  Future<void> updateProfilePhoto(String photoPath) async {
    final current = state.value;
    if (current == null) return;

    print('[ProfileNotifier] Updating profile photo: $photoPath');

    // Optimistic UI: show local file path immediately for instant preview
    state = AsyncValue.data(current.copyWith(profilePhotoUrl: photoPath));

    try {
      await _updateProfileUseCase(profilePhotoPath: photoPath);
      // Refresh to get the server-returned URL
      await _fetchProfile();
      print('[ProfileNotifier] Profile photo updated, new URL: ${state.value?.profilePhotoUrl}');
    } catch (e) {
      print('[ProfileNotifier] Error updating profile photo: $e');
      // Revert on failure
      state = AsyncValue.data(current);
      rethrow;
    }
  }

  /// Update multiple profile fields at once
  ///
  /// Parameters:
  /// - [displayName]: New display name (optional)
  /// - [phoneNumber]: New phone number (optional)
  /// - [userName]: New username (optional)
  /// - [profilePhotoPath]: Path to profile photo file (optional)
  ///
  /// Shows optimistic UI updates, then syncs to API and refreshes.
  Future<void> updateProfileData({
    String? displayName,
    String? phoneNumber,
    String? profilePhotoPath,
  }) async {
    final current = state.value;
    if (current == null) return;

    print('[ProfileNotifier] Updating profile data');
    print('[ProfileNotifier] Photo path: $profilePhotoPath');

    // Optimistic local update (text fields)
    state = AsyncValue.data(
      current.copyWith(
        name: displayName ?? current.name,
        phone: phoneNumber ?? current.phone,
        profilePhotoUrl: profilePhotoPath ?? current.profilePhotoUrl,
      ),
    );

    try {
      await _updateProfileUseCase(
        displayName: displayName,
        phoneNumber: phoneNumber,
        profilePhotoPath: profilePhotoPath,
      );

      // Refresh from API to get the real server-returned photo URL
      await _fetchProfile();
      print('[ProfileNotifier] Profile updated, photo URL: ${state.value?.profilePhotoUrl}');
    } catch (e) {
      print('[ProfileNotifier] Error updating profile: $e');
      // Revert on failure
      state = AsyncValue.data(current);
      rethrow;
    }
  }

  /// Add points to user's trust score
  void addPoints(int points) {
    final current = state.value;
    if (current == null) return;

    final newTotal = (current.points + points).clamp(0, 999999);
    print('[ProfileNotifier] Adding $points points (new total: $newTotal)');
    state = AsyncValue.data(current.copyWith(points: newTotal));
  }

  /// Subtract points from user's trust score
  void subtractPoints(int points) {
    addPoints(-points);
  }

  /// Apply report outcome (resolved = +10 points, rejected = -10 points)
  void applyReportOutcome({required bool resolved}) {
    final delta = resolved ? 10 : -10;
    print(
      '[ProfileNotifier] Report outcome: ${resolved ? 'resolved' : 'rejected'} ($delta points)',
    );
    addPoints(delta);
  }
}

// ==============================================================================
// PROVIDERS
// ==============================================================================

/// Local data source provider
final profileLocalDataSourceProvider = Provider<ProfileLocalDataSource>((ref) {
  return ProfileLocalDataSource();
});

/// Remote data source provider
final profileRemoteDataSourceProvider = Provider<ProfileRemoteDataSource>((
  ref,
) {
  final userLocal = ref.watch(userLocalDataSourceProvider);
  return ProfileRemoteDataSource(
    ref.watch(apiClientProvider),
    readToken: userLocal.getCachedToken,
  );
});

/// Repository provider
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepositoryImpl(
    localDataSource: ref.watch(profileLocalDataSourceProvider),
    remoteDataSource: ref.watch(profileRemoteDataSourceProvider),
    connectivityService: ConnectivityService(),
    userLocalDataSource: ref.watch(userLocalDataSourceProvider),
  );
});

/// Get profile use case provider
final getProfileUseCaseProvider = Provider<GetProfileUseCase>((ref) {
  return GetProfileUseCase(ref.watch(profileRepositoryProvider));
});

/// Update profile use case provider
final updateProfileUseCaseProvider = Provider<UpdateProfileUseCase>((ref) {
  return UpdateProfileUseCase(ref.watch(profileRepositoryProvider));
});

/// Profile async notifier provider
///
/// Manages profile state with AsyncValue
/// Automatically fetches profile on initialization
/// Refreshes when auth state changes (e.g., after signup/login)
final profileAsyncProvider =
    StateNotifierProvider<ProfileNotifier, AsyncValue<UserProfile>>((ref) {
      final notifier = ProfileNotifier(
        repository: ref.watch(profileRepositoryProvider),
        getProfileUseCase: ref.watch(getProfileUseCaseProvider),
        updateProfileUseCase: ref.watch(updateProfileUseCaseProvider),
      );

      // Listen for auth state changes and refresh profile
      // This handles post-signup profile loading, profile picture sync, etc.
      ref.listen<AuthState>(authNotifierProvider, (previous, next) async {
        if (next is! AuthAuthenticated) return;

        final hasSession = await ref
            .read(userLocalDataSourceProvider)
            .hasValidSession();
        if (!hasSession) {
          print(
            '[ProfileProvider] Skipping profile refresh — no valid auth session',
          );
          return;
        }

        final wasAuthenticated = previous is AuthAuthenticated;
        if (!wasAuthenticated || previous is AuthLoading) {
          print(
            '[ProfileProvider] Auth session ready, refreshing profile',
          );
          notifier.refresh();
        }
      });

      Future.microtask(() async {
        if (ref.read(authNotifierProvider) is! AuthAuthenticated) return;
        final hasSession = await ref
            .read(userLocalDataSourceProvider)
            .hasValidSession();
        if (hasSession) {
          notifier.refresh();
        }
      });

      return notifier;
    });

/// Best available profile photo URL (profile API, then auth session).
final profilePhotoUrlProvider = Provider<String?>((ref) {
  final profile = ref.watch(profileProvider);
  final authUser = ref.watch(currentUserProvider);
  final raw = profile?.profilePhotoUrl ?? authUser?.profileImageUrl;
  if (raw == null || raw.trim().isEmpty) return null;
  return CachedAppImage.resolveNetworkUrl(raw.trim());
});

/// Simple profile provider (synchronous)
///
/// Returns current profile value or null if not loaded
final profileProvider = Provider<UserProfile?>((ref) {
  final async = ref.watch(profileAsyncProvider);
  return async.valueOrNull;
});

/// Profile loading state provider
///
/// Returns true if profile is currently loading
final profileLoadingProvider = Provider<bool>((ref) {
  final async = ref.watch(profileAsyncProvider);
  return async.isLoading;
});

/// Profile error provider
///
/// Returns error message if profile fetch failed
final profileErrorProvider = Provider<String?>((ref) {
  final async = ref.watch(profileAsyncProvider);
  return async.maybeWhen(
    error: (error, st) => error.toString(),
    orElse: () => null,
  );
});
