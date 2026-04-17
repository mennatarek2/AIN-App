import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class CachedLocationData {
  const CachedLocationData({
    required this.latitude,
    required this.longitude,
    this.address,
    required this.updatedAt,
  });

  final double latitude;
  final double longitude;
  final String? address;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory CachedLocationData.fromJson(Map<String, dynamic> json) {
    return CachedLocationData(
      latitude: double.tryParse(json['latitude']?.toString() ?? '') ?? 0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '') ?? 0,
      address: json['address']?.toString(),
      updatedAt:
          DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class LocationLocalDataSource {
  static const _cacheKey = 'last_known_location_cache_v1';

  Future<void> saveLastKnownLocation({
    required double latitude,
    required double longitude,
    String? address,
  }) async {
    final prefs = await _safeGetPrefs();
    if (prefs == null) return;

    final payload = CachedLocationData(
      latitude: latitude,
      longitude: longitude,
      address: address,
      updatedAt: DateTime.now(),
    );

    await prefs.setString(_cacheKey, jsonEncode(payload.toJson()));
  }

  Future<CachedLocationData?> getLastKnownLocation() async {
    final prefs = await _safeGetPrefs();
    if (prefs == null) return null;

    final raw = prefs.getString(_cacheKey);
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final location = CachedLocationData.fromJson(
        Map<String, dynamic>.from(decoded),
      );

      if (location.latitude == 0 && location.longitude == 0) {
        return null;
      }
      return location;
    } catch (_) {
      return null;
    }
  }

  Future<SharedPreferences?> _safeGetPrefs() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (_) {
      return null;
    }
  }
}
