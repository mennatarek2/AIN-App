import '../profile_model.dart';
import '../repositories/profile_repository.dart';

/// Use case for fetching the current user's profile from the API.
///
/// Responsibilities:
/// - Fetch profile data from the API
/// - Return cached profile if API fails but cache exists
/// - Handle errors and exceptions
/// - Ensure authentication token is valid
class GetProfileUseCase {
  const GetProfileUseCase(this._repository);

  final ProfileRepository _repository;

  /// Fetch profile from API and update cache
  ///
  /// Throws [Exception] if token is missing
  /// Throws [Exception] if API request fails after retries
  Future<void> call() => _repository.fetchMyProfile();

  /// Get cached profile without making API request
  Future<ProfileModel?> getCached() => _repository.getCachedProfile();
}
