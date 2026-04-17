import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/report_model.dart';

class ReportLocalDataSource {
  static const _cacheKey = 'my_reports_cache_v2';

  Future<List<ReportModel>> readReports() async {
    final prefs = await _safeGetPrefs();
    if (prefs == null) return const [];

    final raw = prefs.getString(_cacheKey);
    if (raw == null || raw.isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];

      return decoded
          .whereType<Map>()
          .map((item) => ReportModel.fromJson(Map<String, dynamic>.from(item)))
          .where((report) => report.id.isNotEmpty && report.title.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveReports(List<ReportModel> reports) async {
    final prefs = await _safeGetPrefs();
    if (prefs == null) return;

    final payload = reports.map((report) => report.toJson()).toList();
    await prefs.setString(_cacheKey, jsonEncode(payload));
  }

  Future<SharedPreferences?> _safeGetPrefs() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (_) {
      return null;
    }
  }
}
