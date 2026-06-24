import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/network/auth_token_utils.dart';
import '../models/user_model.dart';

class UserLocalDataSource {
  static const _userCacheKey = 'auth_cached_user_v1';
  static const _tokenCacheKey = 'auth_cached_token_v1';
  static const _signupTokenKey = 'auth_cached_signup_token_v1';
  static const _refreshTokenKey = 'auth_cached_refresh_token_v1';
  static const _pendingRegistrationKey = 'auth_pending_registration_v1';
  static const _forgotPasswordTokenKey = 'auth_forgot_password_token_v1';
  static const _forgotPasswordEmailKey = 'auth_forgot_password_email_v1';

  Future<void> saveSession({
    required UserModel user,
    required String token,
    String? refreshToken,
  }) async {
    final prefs = await _safeGetPrefs();
    if (prefs == null) return;

    final normalizedToken = AuthTokenUtils.normalize(token) ?? token;

    await prefs.setString(_userCacheKey, jsonEncode(user.toJson()));
    await prefs.setString(_tokenCacheKey, normalizedToken);
    if (refreshToken != null && refreshToken.trim().isNotEmpty) {
      await prefs.setString(
        _refreshTokenKey,
        AuthTokenUtils.normalize(refreshToken) ?? refreshToken.trim(),
      );
    }
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
    return AuthTokenUtils.normalize(token) ?? token;
  }

  Future<String?> getCachedRefreshToken() async {
    final prefs = await _safeGetPrefs();
    if (prefs == null) return null;

    final token = prefs.getString(_refreshTokenKey);
    if (token == null || token.trim().isEmpty) return null;
    return token;
  }

  Future<void> saveSignupToken(String token) async {
    final prefs = await _safeGetPrefs();
    if (prefs == null) return;
    await prefs.setString(
      _signupTokenKey,
      AuthTokenUtils.normalize(token) ?? token.trim(),
    );
  }

  Future<String?> getSignupToken() async {
    final prefs = await _safeGetPrefs();
    if (prefs == null) return null;

    final token = prefs.getString(_signupTokenKey);
    if (token == null || token.trim().isEmpty) return null;
    return AuthTokenUtils.normalize(token) ?? token;
  }

  Future<void> savePendingRegistration({
    required String email,
    required String name,
    required String phoneNumber,
    String? ssn,
  }) async {
    final prefs = await _safeGetPrefs();
    if (prefs == null) return;

    await prefs.setString(
      _pendingRegistrationKey,
      jsonEncode({
        'email': email.trim(),
        'name': name.trim(),
        'phoneNumber': phoneNumber.trim(),
        if (ssn != null && ssn.trim().isNotEmpty) 'ssn': ssn.trim(),
      }),
    );
  }

  Future<Map<String, String>?> getPendingRegistration() async {
    final prefs = await _safeGetPrefs();
    if (prefs == null) return null;

    final raw = prefs.getString(_pendingRegistrationKey);
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return decoded.map(
        (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> clearPendingRegistration() async {
    final prefs = await _safeGetPrefs();
    if (prefs == null) return;
    await prefs.remove(_pendingRegistrationKey);
  }

  Future<void> saveForgotPasswordToken(String token) async {
    final prefs = await _safeGetPrefs();
    if (prefs == null) return;
    await prefs.setString(
      _forgotPasswordTokenKey,
      AuthTokenUtils.normalize(token) ?? token.trim(),
    );
  }

  Future<String?> getForgotPasswordToken() async {
    final prefs = await _safeGetPrefs();
    if (prefs == null) return null;

    final token = prefs.getString(_forgotPasswordTokenKey);
    if (token == null || token.trim().isEmpty) return null;
    return AuthTokenUtils.normalize(token) ?? token;
  }

  Future<void> saveForgotPasswordEmail(String email) async {
    final prefs = await _safeGetPrefs();
    if (prefs == null) return;
    await prefs.setString(_forgotPasswordEmailKey, email.trim());
  }

  Future<String?> getForgotPasswordEmail() async {
    final prefs = await _safeGetPrefs();
    if (prefs == null) return null;

    final email = prefs.getString(_forgotPasswordEmailKey);
    if (email == null || email.trim().isEmpty) return null;
    return email.trim();
  }

  Future<void> clearForgotPasswordEmail() async {
    final prefs = await _safeGetPrefs();
    if (prefs == null) return;
    await prefs.remove(_forgotPasswordEmailKey);
  }

  Future<void> clearForgotPasswordToken() async {
    final prefs = await _safeGetPrefs();
    if (prefs == null) return;
    await prefs.remove(_forgotPasswordTokenKey);
  }

  Future<void> clearSignupToken() async {
    final prefs = await _safeGetPrefs();
    if (prefs == null) return;
    await prefs.remove(_signupTokenKey);
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
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_signupTokenKey);
    await prefs.remove(_pendingRegistrationKey);
    await prefs.remove(_forgotPasswordTokenKey);
    await prefs.remove(_forgotPasswordEmailKey);
  }

  Future<SharedPreferences?> _safeGetPrefs() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (_) {
      return null;
    }
  }
}
