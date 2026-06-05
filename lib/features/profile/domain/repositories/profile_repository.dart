import '../profile_model.dart';

abstract class ProfileRepository {
  /// Fetches the current user's profile from API
  /// Returns cached profile if API fails but cache exists
  Future<void> fetchMyProfile();

  /// Returns the currently cached profile
  Future<ProfileModel?> getCachedProfile();

  /// Updates the user's profile with the given parameters
  /// At least one parameter must be provided (non-null)
  Future<void> updateProfile({
    String? displayName,
    String? phoneNumber,
    String? userName,
    String? profilePhotoPath,
  });

  /// Gets the current profile state as a stream for reactive updates
  Stream<ProfileModel?> watchProfile();

  /// Syncs any pending profile updates
  Future<void> syncProfile();
}
