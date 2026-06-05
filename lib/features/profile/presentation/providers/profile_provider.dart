import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/connectivity_service.dart';
import '../../../../core/network/api_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/state/auth_state_simple.dart';
import '../../data/data_sources/profile_local_data_source.dart';
import '../../data/profile_remote_data_source.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../domain/profile_model.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/use_cases/use_cases.dart';

/// UI representation of user profile
///
/// Contains all user profile information needed for the UI.
///
/// Default values for new accounts:
/// - trustPoints: 50
/// - level: 1
class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.username,
    required this.isVerified,
    required this.points,
    this.profilePhotoUrl,
  });

  factory UserProfile.fromModel(ProfileModel model) {
    return UserProfile(
      id: model.id,
      name: model.displayName,
      email: model.email,
      phone: model.phoneNumber,
      username: model.userName,
      isVerified: model.isVerified,
      points: model.points,
      profilePhotoUrl: model.profilePhotoUrl,
    );
  }

  final String id;
  final String name;
  final String email;
  final String phone;
  final String username;
  final bool isVerified;
  final int points;

  /// The profile photo URL from the API (absolute URL or null)
  final String? profilePhotoUrl;

  int get pointsToNextLevel {
    if (points < 100) return 100 - points;
    if (points < 200) return 200 - points;
    if (points < 300) return 300 - points;
    return 0;
  }

  // Calculate level dynamically based on points
  String get level {
    if (points < 100) return 'مستخدم جديد';
    if (points < 200) return 'مساهم';
    if (points < 300) return 'موثق';
    return 'متميز';
  }

  Color get levelDotColor {
    if (points < 100) return const Color(0xFF697184);
    if (points < 200) return const Color(0xFF498EF4);
    if (points < 300) return const Color(0xFF14B57A);
    return const Color(0xFFF59E0B);
  }

  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? username,
    bool? isVerified,
    int? points,
    String? profilePhotoUrl,
    bool clearPhoto = false,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      username: username ?? this.username,
      isVerified: isVerified ?? this.isVerified,
      points: points ?? this.points,
      profilePhotoUrl:
          clearPhoto ? null : (profilePhotoUrl ?? this.profilePhotoUrl),
    );
  }

  @override
  String toString() =>
      'UserProfile(id: $id, name: $name, points: $points, photoUrl: $profilePhotoUrl)';
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

  /// Initialize profile by fetching from cache or API
  Future<void> _initialize() async {
    try {
      print('[ProfileNotifier] Initializing profile');

      // Try to get cached profile first
      final cached = await _getProfileUseCase.getCached();
      if (cached != null) {
        print('[ProfileNotifier] Loaded cached profile, photoUrl: ${cached.profilePhotoUrl}');
        state = AsyncValue.data(UserProfile.fromModel(cached));
      }

      // Fetch latest from API
      await _fetchProfile();
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

  /// Update username
  ///
  /// Updates local state immediately, then syncs to API
  Future<void> updateUsername(String username) async {
    final current = state.value;
    if (current == null) return;

    print('[ProfileNotifier] Updating username to: $username');
    state = AsyncValue.data(current.copyWith(username: username));

    try {
      await _updateProfileUseCase(userName: username);
    } catch (e) {
      print('[ProfileNotifier] Error updating username: $e');
      // Revert on failure
      state = AsyncValue.data(current);
    }
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
    String? userName,
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
        username: userName ?? current.username,
        // Show local preview if photo is being updated
        profilePhotoUrl: profilePhotoPath ?? current.profilePhotoUrl,
      ),
    );

    try {
      await _updateProfileUseCase(
        displayName: displayName,
        phoneNumber: phoneNumber,
        userName: userName,
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
      ref.listen<AuthState>(authNotifierProvider, (previous, next) {
        // Refresh profile when transitioning to authenticated state
        final wasAuthenticated = previous is AuthAuthenticated;
        final nowAuthenticated = next is AuthAuthenticated;
        if (!wasAuthenticated && nowAuthenticated) {
          print('[ProfileProvider] Auth state changed to authenticated, refreshing profile');
          notifier.refresh();
        }
      });

      return notifier;
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
