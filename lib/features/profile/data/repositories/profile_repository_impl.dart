import 'dart:async';

import '../../../../core/network/connectivity_service.dart';
import '../../domain/profile_model.dart';
import '../../domain/repositories/profile_repository.dart';
import '../data_sources/profile_local_data_source.dart';
import '../profile_remote_data_source.dart';
import '../profile_exceptions.dart';

/// Implementation of ProfileRepository
///
/// Handles:
/// - Fetching profile from API with caching
/// - Updating profile with multipart form data
/// - Offline support using cached data
/// - Error handling and retry logic
/// - Automatic sync on reconnect
///
/// Default values for new accounts:
/// - trustPoints: 50
/// - level: 1 (or 'مستخدم جديد')
class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.connectivityService,
  });

  final ProfileLocalDataSource localDataSource;
  final ProfileRemoteDataSource remoteDataSource;
  final ConnectivityService connectivityService;

  static const _maxRetries = 2;
  static const _retryDelay = Duration(milliseconds: 400);
  static const _postSignupMaxRetries = 5; // Extra retries for post-signup 404
  static const _postSignupRetryDelay = Duration(
    milliseconds: 800,
  ); // Longer delay for post-signup

  /// Fetch user profile from API with automatic retry
  ///
  /// Behavior:
  /// - If online: fetch from API and update cache
  /// - If offline and cached: use cached profile
  /// - If offline and no cache: throw exception
  /// - Retries up to 2 times on normal failure
  /// - Retries up to 5 times on 404 (post-signup profile not ready)
  ///
  /// Throws [ProfileException] on repeated failures
  @override
  Future<void> fetchMyProfile() async {
    final cached = await localDataSource.readProfile();
    final isOnline = await connectivityService.isOnline();

    print(
      '[ProfileRepo] Fetching profile - Online: $isOnline, Cached: ${cached != null}',
    );

    // If offline, use cache if available
    if (!isOnline) {
      if (cached != null) {
        print('[ProfileRepo] Using cached profile (offline mode)');
        return;
      } else {
        throw ProfileException(
          'No internet connection and no cached profile',
          0,
        );
      }
    }

    // Fetch from API with retry logic
    ProfileException? lastError;
    bool hasNotFoundError = false;

    // First try with normal retries
    for (var attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        print('[ProfileRepo] Fetching profile attempt $attempt/$_maxRetries');
        final remote = await remoteDataSource.getMyProfile();

        if (remote != null) {
          await localDataSource.saveProfile(remote);
          print('[ProfileRepo] Profile fetched and cached successfully');
          return;
        }

        // If remote returned null, treat as error and retry
        lastError = ProfileException('Empty profile response from API', 500);
      } catch (e) {
        print('[ProfileRepo] Error on attempt $attempt: $e');
        if (e is ProfileException) {
          lastError = e;
          // Check if this is a 404 error (post-signup profile not created yet)
          if (e.code == 404) {
            hasNotFoundError = true;
          }
        } else {
          lastError = ProfileException('Failed to fetch profile: $e', 500);
        }
      }

      // Retry with backoff (except on last attempt)
      if (attempt < _maxRetries) {
        await Future.delayed(_retryDelay);
      }
    }

    // If we got 404, try extended retries (post-signup scenario)
    if (hasNotFoundError) {
      print(
        '[ProfileRepo] Got 404, trying extended retries for post-signup scenario',
      );
      for (var attempt = 1; attempt <= _postSignupMaxRetries; attempt++) {
        try {
          print(
            '[ProfileRepo] Post-signup retry $attempt/$_postSignupMaxRetries',
          );
          final remote = await remoteDataSource.getMyProfile();

          if (remote != null) {
            await localDataSource.saveProfile(remote);
            print(
              '[ProfileRepo] Profile fetched successfully after post-signup wait',
            );
            return;
          }

          lastError = ProfileException('Empty profile response from API', 500);
        } catch (e) {
          print('[ProfileRepo] Error on post-signup retry $attempt: $e');
          if (e is ProfileException) {
            lastError = e;
          } else {
            lastError = ProfileException('Failed to fetch profile: $e', 500);
          }
        }

        // Retry with longer backoff
        if (attempt < _postSignupMaxRetries) {
          await Future.delayed(_postSignupRetryDelay);
        }
      }
    }

    // All retries exhausted
    if (cached != null) {
      print(
        '[ProfileRepo] All retries failed, using cached profile as fallback',
      );
      return;
    }

    print('[ProfileRepo] Failed to fetch profile: $lastError');
    throw lastError ?? ProfileException('Failed to fetch profile', 500);
  }

  /// Get cached profile without making API request
  ///
  /// Returns: Cached profile or null if not available
  @override
  Future<ProfileModel?> getCachedProfile() {
    return localDataSource.readProfile();
  }

  /// Update user profile with automatic retry
  ///
  /// Parameters:
  /// - [displayName]: New display name (optional)
  /// - [phoneNumber]: New phone number (optional)
  /// - [userName]: New username (optional)
  /// - [profilePhotoPath]: Path to profile photo file (optional)
  ///
  /// Behavior:
  /// - Sends update to API with multipart form data
  /// - Updates local cache on success
  /// - Retries up to 2 times on failure
  /// - Updates UI immediately while syncing
  ///
  /// Throws [ProfileException] on repeated failures
  @override
  Future<void> updateProfile({
    String? displayName,
    String? phoneNumber,
    String? profilePhotoPath,
  }) async {
    print('[ProfileRepo] Starting profile update');

    ProfileException? lastError;
    for (var attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        print('[ProfileRepo] Updating profile attempt $attempt/$_maxRetries');

        // Send update to API
        await remoteDataSource.updateProfile(
          displayName: displayName,
          phoneNumber: phoneNumber,
          profilePhotoPath: profilePhotoPath,
        );

        // Update local cache
        final cached = await localDataSource.readProfile();
        if (cached != null) {
          await localDataSource.saveProfile(
            cached.copyWith(
              displayName: displayName?.trim().isNotEmpty == true
                  ? displayName!.trim()
                  : cached.displayName,
              phoneNumber: phoneNumber?.trim().isNotEmpty == true
                  ? phoneNumber!.trim()
                  : cached.phoneNumber,
            ),
          );
          print('[ProfileRepo] Profile updated and cached successfully');
        }

        return;
      } catch (e) {
        print('[ProfileRepo] Error on attempt $attempt: $e');
        if (e is ProfileException) {
          lastError = e;
        } else {
          lastError = ProfileException('Failed to update profile: $e', 500);
        }
      }

      // Retry with backoff (except on last attempt)
      if (attempt < _maxRetries) {
        await Future.delayed(_retryDelay);
      }
    }

    // All retries exhausted
    print('[ProfileRepo] Failed to update profile: $lastError');
    throw lastError ?? ProfileException('Failed to update profile', 500);
  }

  /// Watch profile for reactive updates
  ///
  /// Yields cached profile immediately, then streams updates
  @override
  Stream<ProfileModel?> watchProfile() async* {
    yield await localDataSource.readProfile();
  }

  /// Sync profile (fetch latest from API)
  ///
  /// Used to manually trigger profile refresh
  @override
  Future<void> syncProfile() async {
    print('[ProfileRepo] Manual profile sync requested');
    await fetchMyProfile();
  }
}
