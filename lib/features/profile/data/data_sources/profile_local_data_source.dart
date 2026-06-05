import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/profile_model.dart';

class ProfileLocalDataSource {
  static const String _profileCacheKey = 'profile_cache';

  /// Save profile to local cache
  Future<void> saveProfile(ProfileModel profile) async {
    final prefs = await _safeGetPrefs();
    if (prefs == null) return;

    final json = _profileToJson(profile);
    await prefs.setString(_profileCacheKey, jsonEncode(json));
  }

  /// Read profile from local cache
  Future<ProfileModel?> readProfile() async {
    final prefs = await _safeGetPrefs();
    if (prefs == null) return null;

    final cached = prefs.getString(_profileCacheKey);
    if (cached == null) return null;
    try {
      final json = jsonDecode(cached) as Map<String, dynamic>;
      return _jsonToProfile(json);
    } catch (_) {
      // Corrupted cache, clear it
      await prefs.remove(_profileCacheKey);
      return null;
    }
  }

  /// Clear profile cache
  Future<void> clearProfile() async {
    final prefs = await _safeGetPrefs();
    if (prefs == null) return;

    await prefs.remove(_profileCacheKey);
  }

  /// Check if profile exists in cache
  Future<bool> hasProfile() async {
    final prefs = await _safeGetPrefs();
    if (prefs == null) return false;

    return prefs.containsKey(_profileCacheKey);
  }

  static Map<String, dynamic> _profileToJson(ProfileModel profile) {
    return {
      'id': profile.id,
      'displayName': profile.displayName,
      'email': profile.email,
      'phoneNumber': profile.phoneNumber,
      'userName': profile.userName,
      'isVerified': profile.isVerified,
      'points': profile.points,
      // Persist the profile photo URL so it survives app restarts
      'profilePhotoUrl': profile.profilePhotoUrl,
    };
  }

  static ProfileModel _jsonToProfile(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      userName: json['userName'] as String? ?? '',
      isVerified: json['isVerified'] as bool? ?? false,
      points: json['points'] as int? ?? 0,
      profilePhotoUrl: json['profilePhotoUrl'] as String?,
    );
  }

  Future<SharedPreferences?> _safeGetPrefs() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (_) {
      return null;
    }
  }
}
