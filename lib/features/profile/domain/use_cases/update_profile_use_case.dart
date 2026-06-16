import '../repositories/profile_repository.dart';

/// Use case for updating user profile information.
///
/// Responsibilities:
/// - Update profile data (displayName, phoneNumber, userName)
/// - Handle profile photo uploads (multipart/form-data)
/// - Update local cache after successful API call
/// - Handle errors and exceptions
/// - Show immediate UI updates while syncing to API
class UpdateProfileUseCase {
  const UpdateProfileUseCase(this._repository);

  final ProfileRepository _repository;

  /// Update user profile with the given parameters
  ///
  /// Parameters:
  /// - [displayName]: User's display name (optional)
  /// - [phoneNumber]: User's phone number (optional)
  /// - [userName]: User's username (optional)
  /// - [profilePhotoPath]: Path to profile photo file (optional, local path)
  ///
  /// Note: At least one parameter should be provided for meaningful update
  ///
  /// Throws [Exception] if token is missing
  /// Throws [Exception] if API request fails after retries
  Future<void> call({
    String? displayName,
    String? phoneNumber,
    String? profilePhotoPath,
  }) => _repository.updateProfile(
    displayName: displayName,
    phoneNumber: phoneNumber,
    profilePhotoPath: profilePhotoPath,
  );
}
