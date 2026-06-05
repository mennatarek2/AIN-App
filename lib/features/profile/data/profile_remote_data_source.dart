import 'dart:io';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import 'profile_exceptions.dart';
import '../domain/profile_model.dart';

/// API model for profile data from server
/// Extends ProfileModel to add API-specific functionality
class ProfileApiModel extends ProfileModel {
  const ProfileApiModel({
    required super.id,
    required super.displayName,
    required super.email,
    required super.phoneNumber,
    required super.userName,
    super.isVerified = false,
    super.points = 50, // Default: 50 trust points for new accounts
    super.profilePhotoUrl,
  });

  /// Parse profile data from API response
  ///
  /// Handles multiple response formats:
  /// - Direct profile object
  /// - Nested under 'data', 'result', or 'profile' keys
  /// - Missing or null fields default to empty strings/0
  ///
  /// Default values for new accounts:
  /// - points: 50 (trust points)
  /// - isVerified: false
  factory ProfileApiModel.fromApiJson(Map<String, dynamic> json) {
    // Log raw API response for debugging
    print('[ProfileApiModel] Raw API JSON keys: ${json.keys.toList()}');
    print('[ProfileApiModel] Raw API JSON: $json');

    // Extract points with default value of 50 for new accounts
    final pointsValue = json['points'];
    int points;
    if (pointsValue is int) {
      points = pointsValue;
    } else if (pointsValue is String) {
      points = int.tryParse(pointsValue) ?? 50;
    } else {
      points = 50; // Default for new accounts
    }

    // Extract and resolve profile photo URL
    // Try all possible field names the API might use
    final rawPhotoUrl = _extractPhotoUrl(json);
    final resolvedPhotoUrl = _resolvePhotoUrl(rawPhotoUrl);
    print('[ProfileApiModel] Raw photo URL from API: $rawPhotoUrl');
    print('[ProfileApiModel] Resolved photo URL: $resolvedPhotoUrl');

    return ProfileApiModel(
      id: json['id']?.toString() ?? '',
      displayName:
          json['displayName']?.toString() ?? json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      userName:
          json['userName']?.toString() ?? json['username']?.toString() ?? '',
      isVerified: json['isVerified'] == true,
      points: points,
      profilePhotoUrl:
          resolvedPhotoUrl?.trim().isNotEmpty == true ? resolvedPhotoUrl : null,
    );
  }

  /// Extract photo URL from JSON trying multiple field names
  static String? _extractPhotoUrl(Map<String, dynamic> json) {
    // Try all possible field names the backend may use
    final candidates = [
      json['profilePhotoUrl'],
      json['profilePhoto'],
      json['profilePictureUrl'],
      json['profilePicture'],
      json['avatarUrl'],
      json['avatar'],
      json['photoUrl'],
      json['imageUrl'],
      json['picture'],
    ];

    for (final candidate in candidates) {
      if (candidate is String && candidate.trim().isNotEmpty) {
        return candidate.trim();
      }
    }
    return null;
  }

  /// Resolve a photo URL — prepend base URL if it is a relative path
  static String? _resolvePhotoUrl(String? url) {
    if (url == null || url.trim().isEmpty) return null;

    final trimmed = url.trim();

    // Already an absolute URL — return as-is
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }

    // Relative path — prepend the API base URL
    final base = ApiConfig.baseUrl.endsWith('/')
        ? ApiConfig.baseUrl.substring(0, ApiConfig.baseUrl.length - 1)
        : ApiConfig.baseUrl;
    final path = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    return '$base$path';
  }
}

class ProfileRemoteDataSource {
  ProfileRemoteDataSource(this._client, {required this.readToken});

  final ApiClient _client;
  final Future<String?> Function() readToken;

  /// Get required auth token or throw exception
  ///
  /// Throws [ProfileException] if token is missing or invalid
  Future<String> _requiredToken() async {
    final token = await readToken();
    if (token == null || token.trim().isEmpty) {
      throw ProfileException(
        'Authentication required. Please login again.',
        401,
      );
    }
    return token;
  }

  /// Fetch the current user's profile from the API
  ///
  /// Returns: Profile model with user data including profilePhotoUrl
  /// Throws: [ProfileException] if API call fails or token is invalid
  Future<ProfileModel?> getMyProfile() async {
    try {
      final token = await _requiredToken();
      print('[Profile] Fetching profile from API: ${ApiConfig.baseUrl}${ApiEndpoints.myProfile}');

      final response = await _client.getJson(
        ApiEndpoints.myProfile,
        token: token,
      );

      print('[Profile] Raw API response: $response');

      final map = _extractMap(response);
      if (map == null) {
        print('[Profile] Empty profile response from API');
        return null;
      }

      final model = ProfileApiModel.fromApiJson(map);
      print('[Profile] Profile fetched successfully');
      print('[Profile] Profile photo URL: ${model.profilePhotoUrl}');
      return model;
    } on ApiException catch (e) {
      // Preserve API status code for better error handling
      throw ProfileException('Failed to fetch profile: $e', e.statusCode);
    } catch (e) {
      if (e is ProfileException) rethrow;
      throw ProfileException('Failed to fetch profile: $e');
    }
  }

  /// Update user profile with multipart form data
  ///
  /// Supports:
  /// - displayName update
  /// - phoneNumber update
  /// - userName update
  /// - profilePhoto upload (image file)
  ///
  /// Parameters:
  /// - [displayName]: New display name (optional)
  /// - [phoneNumber]: New phone number (optional)
  /// - [userName]: New username (optional)
  /// - [profilePhotoPath]: Local file path to profile image (optional, jpg/png)
  ///
  /// Throws [ProfileException] if API call fails
  Future<void> updateProfile({
    String? displayName,
    String? phoneNumber,
    String? userName,
    String? profilePhotoPath,
  }) async {
    try {
      final token = await _requiredToken();
      final fields = <String, String>{};

      // Add fields if provided and not empty
      if (displayName != null && displayName.trim().isNotEmpty) {
        fields['displayName'] = displayName.trim();
        print('[Profile] Updating displayName: ${displayName.trim()}');
      }
      if (phoneNumber != null && phoneNumber.trim().isNotEmpty) {
        fields['phoneNumber'] = phoneNumber.trim();
        print('[Profile] Updating phoneNumber');
      }
      if (userName != null && userName.trim().isNotEmpty) {
        fields['userName'] = userName.trim();
        print('[Profile] Updating userName');
      }

      Map<String, String>? filePaths;
      if (profilePhotoPath != null && profilePhotoPath.trim().isNotEmpty) {
        final file = File(profilePhotoPath);
        if (await file.exists()) {
          filePaths = {'profilePhoto': profilePhotoPath};
          print('[Profile] Uploading profile photo: $profilePhotoPath');
        } else {
          print(
            '[Profile] Profile photo file does not exist: $profilePhotoPath',
          );
        }
      }

      // At least one field must be provided
      if (fields.isEmpty && filePaths == null) {
        throw ProfileException('No profile data to update', 400);
      }

      print('[Profile] Sending update request to: ${ApiConfig.baseUrl}${ApiEndpoints.updateProfile}');
      print('[Profile] Fields: $fields');
      print('[Profile] Files: $filePaths');

      final response = await _client.putMultipart(
        ApiEndpoints.updateProfile,
        token: token,
        fields: fields.isEmpty ? null : fields,
        filePaths: filePaths,
      );

      print('[Profile] Update API response: $response');
      print('[Profile] Profile updated successfully');
    } on ApiException catch (e) {
      // Preserve API status code for better error handling
      throw ProfileException('Failed to update profile: $e', e.statusCode);
    } catch (e) {
      if (e is ProfileException) rethrow;
      throw ProfileException('Failed to update profile: $e');
    }
  }

  /// Extract profile data from API response
  ///
  /// Handles various response formats:
  /// 1. Direct profile object at root level
  /// 2. Nested under 'data', 'result', or 'profile' keys
  /// 3. Recursively searches for profile-like structure
  ///
  /// Returns: Map with profile fields or null if not found
  Map<String, dynamic>? _extractMap(dynamic payload) {
    if (payload is Map) {
      // Check if this is already a profile object
      if (payload.containsKey('id') || payload.containsKey('email')) {
        return Map<String, dynamic>.from(payload);
      }

      // Check common wrapper keys
      final candidate =
          payload['data'] ?? payload['result'] ?? payload['profile'];
      if (candidate is Map) return Map<String, dynamic>.from(candidate);

      // Recursively search for profile in nested structures
      for (final value in payload.values) {
        final nested = _extractMap(value);
        if (nested != null) return nested;
      }
    }
    return null;
  }
}
