import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

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
    super.trustPoints = 0,
    super.badge = 'Newcomer',
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
    print('[ProfileApiModel] Raw API JSON keys: ${json.keys.toList()}');
    print('[ProfileApiModel] Raw API JSON: $json');

    // API returns 'trustPoints' (not 'points')
    final pointsValue = json['trustPoints'] ?? json['points'];
    int trustPoints;
    if (pointsValue is int) {
      trustPoints = pointsValue;
    } else if (pointsValue is String) {
      trustPoints = int.tryParse(pointsValue) ?? 0;
    } else {
      trustPoints = 0;
    }

    // API returns badge as 'Newcomer' | 'Contributor' | 'Trusted' | 'Guardian'
    final badge = json['badge']?.toString() ?? 'Newcomer';

    final rawPhotoUrl = _extractPhotoUrl(json);
    final resolvedPhotoUrl = _resolvePhotoUrl(rawPhotoUrl);
    print('[ProfileApiModel] trustPoints: $trustPoints, badge: $badge');
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
      trustPoints: trustPoints,
      badge: badge,
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
      // C# [FromForm] requires PascalCase field names
      final fields = <String, String>{};

      if (displayName != null && displayName.trim().isNotEmpty) {
        fields['DisplayName'] = displayName.trim();
        print('[Profile] Updating DisplayName: ${displayName.trim()}');
      }
      if (phoneNumber != null && phoneNumber.trim().isNotEmpty) {
        fields['PhoneNumber'] = phoneNumber.trim();
        print('[Profile] Updating PhoneNumber');
      }

      Map<String, String>? filePaths;
      if (profilePhotoPath != null && profilePhotoPath.trim().isNotEmpty) {
        final file = File(profilePhotoPath);
        if (await file.exists()) {
          // C# [FromForm] expects 'ProfilePhoto' (PascalCase)
          filePaths = {'ProfilePhoto': profilePhotoPath};
          print('[Profile] Uploading ProfilePhoto: $profilePhotoPath');
        } else {
          print('[Profile] Profile photo file does not exist: $profilePhotoPath');
        }
      }

      if (fields.isEmpty && filePaths == null) {
        throw ProfileException('No profile data to update', 400);
      }

      print('[Profile] PUT ${ApiConfig.baseUrl}${ApiEndpoints.updateProfile}');

      // PUT returns AuthResult { isSuccess, user: { displayName, email, token, refreshToken } }
      final response = await _client.putMultipart(
        ApiEndpoints.updateProfile,
        token: token,
        fields: fields.isEmpty ? null : fields,
        filePaths: filePaths,
      );

      // Save new JWT so subsequent requests use updated claims
      await _saveNewToken(response);
      print('[Profile] Profile updated successfully');
    } on ApiException catch (e) {
      throw ProfileException('Failed to update profile: $e', e.statusCode);
    } catch (e) {
      if (e is ProfileException) rethrow;
      throw ProfileException('Failed to update profile: $e');
    }
  }

  /// Extract and persist the new JWT returned by PUT /api/profile/update-profile.
  /// The response shape is: { isSuccess, user: { token, refreshToken, ... } }
  Future<void> _saveNewToken(dynamic response) async {
    try {
      Map<String, dynamic>? map;
      if (response is Map<String, dynamic>) {
        map = response;
      } else if (response is Map) {
        map = Map<String, dynamic>.from(response);
      }
      if (map == null) return;

      final user = map['user'];
      String? newToken;
      if (user is Map) {
        newToken = user['token']?.toString();
      }
      newToken ??= map['token']?.toString();

      if (newToken != null && newToken.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        // Use the exact key the auth layer reads from
        await prefs.setString('auth_cached_token_v1', newToken);
        print('[Profile] Saved new JWT (auth_cached_token_v1)');
      }
    } catch (e) {
      // Non-fatal — profile update succeeded even if token save fails
      print('[Profile] Could not save new token: $e');
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
