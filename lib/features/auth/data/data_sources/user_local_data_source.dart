import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';

class UserLocalDataSource {
  static const _userCacheKey = 'auth_cached_user_v1';
  static const _tokenCacheKey = 'auth_cached_token_v1';

  Future<void> saveSession({
    required UserModel user,
    required String token,
  }) async {
    final prefs = await _safeGetPrefs();
    if (prefs == null) return;

    await prefs.setString(_userCacheKey, jsonEncode(user.toJson()));
    await prefs.setString(_tokenCacheKey, token);
  }

  Future<UserModel?> getCachedUser() async {
    final prefs = await _safeGetPrefs();
    if (prefs == null) return null;

    final rawUser = prefs.getString(_userCacheKey);
    if (rawUser == null || rawUser.isEmpty) return null;

    try {
      final decoded = jsonDecode(rawUser);
      if (decoded is! Map) return null;
      return UserModel.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return null;
    }
  }

  Future<String?> getCachedToken() async {
    final prefs = await _safeGetPrefs();
    if (prefs == null) return null;

    final token = prefs.getString(_tokenCacheKey);
    if (token == null || token.trim().isEmpty) {
      return null;
    }
    return token;
  }

  Future<bool> hasValidSession() async {
    final user = await getCachedUser();
    final token = await getCachedToken();
    return user != null && token != null;
  }

  Future<void> clearSession() async {
    final prefs = await _safeGetPrefs();
    if (prefs == null) return;

    await prefs.remove(_userCacheKey);
    await prefs.remove(_tokenCacheKey);
  }

  Future<SharedPreferences?> _safeGetPrefs() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (_) {
      return null;
    }
  }
}
