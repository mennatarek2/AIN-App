import 'package:shared_preferences/shared_preferences.dart';

/// Persists the last registered FCM device token for logout cleanup.
abstract final class DeviceTokenStorage {
  static const _cachedTokenKey = 'fcm_device_token_v1';

  static Future<String?> readCachedToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_cachedTokenKey);
  }

  static Future<void> cacheToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cachedTokenKey, token);
  }

  static Future<void> clearCachedToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cachedTokenKey);
  }
}
