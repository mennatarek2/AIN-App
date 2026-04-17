import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../notifications/presentation/providers/notifications_provider.dart';
import '../../../reports/domain/report_model.dart';

typedef MyReport = ReportModel;

class MyReportsState {
  const MyReportsState({
    required this.reports,
    required this.searchQuery,
    required this.filterEnabled,
  });

  final List<MyReport> reports;
  final String searchQuery;
  final bool filterEnabled;

  MyReportsState copyWith({
    List<MyReport>? reports,
    String? searchQuery,
    bool? filterEnabled,
  }) {
    return MyReportsState(
      reports: reports ?? this.reports,
      searchQuery: searchQuery ?? this.searchQuery,
      filterEnabled: filterEnabled ?? this.filterEnabled,
    );
  }
}

class MyReportsNotifier extends StateNotifier<MyReportsState> {
  MyReportsNotifier({required this.onReportStatusChanged})
    : super(_initialState()) {
    _loadPersistedReports();
  }

  final Future<void> Function({
    required String reportTitle,
    required String statusLabel,
  })
  onReportStatusChanged;

  static const _reportsCacheKey = 'my_reports_cache_v1';

  static MyReportsState _initialState() {
    return MyReportsState(
      reports: const [
        MyReport(
          id: 'report-1',
          title: 'حفرة في الطريق',
          description: 'حفرة في الطريق تهدد سلامة المركبات',
          submittedAgo: 'منذ 3 أيام',
          fullDescription:
              'يوجد حفرة كبيرة في الطريق الرئيسي تهدد سلامة المركبات والمشاة',
          reportType: 'مشاكل الطرق',
          imagePath: 'assets/images/report_image.png',
          progressIndex: 2,
          statusLabel: 'قيد المعالجة',
          statusColor: Color(0xFF2A9AF4),
          latitude: 30.0452,
          longitude: 31.2338,
          locationAddress: 'Nasr City, Cairo',
        ),
        MyReport(
          id: 'report-2',
          title: 'إنارة معطلة',
          description: 'أعمدة الإنارة في الشارع معطلة',
          submittedAgo: 'منذ 5 أيام',
          fullDescription: 'أعمدة الإنارة في الشارع معطلة منذ أسبوع',
          reportType: 'الكهرباء والإنارة',
          imagePath: 'assets/images/report_image.png',
          progressIndex: 1,
          statusLabel: 'قيد المراجعة',
          statusColor: Color(0xFFF3B61F),
          latitude: 30.0383,
          longitude: 31.2211,
          locationAddress: 'Maadi, Cairo',
        ),
      ],
      searchQuery: '',
      filterEnabled: false,
    );
  }

  void setSearchQuery(String value) {
    state = state.copyWith(searchQuery: value.trim());
  }

  void toggleFilter() {
    state = state.copyWith(filterEnabled: !state.filterEnabled);
  }

  void addReportFromSubmission({
    required String title,
    required String description,
    required String reportType,
    required double latitude,
    required double longitude,
    String? locationAddress,
  }) {
    final report = MyReport(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      description: description,
      submittedAgo: 'الآن',
      fullDescription: description,
      reportType: reportType,
      imagePath: 'assets/images/report_image.png',
      progressIndex: 0,
      statusLabel: 'تم الاستلام',
      statusColor: const Color(0xFF2A9AF4),
      latitude: latitude,
      longitude: longitude,
      locationAddress: locationAddress,
    );

    state = state.copyWith(reports: [report, ...state.reports]);
    _persistCurrentReports();
  }

  void updateReportStatus({
    required String reportId,
    required String statusLabel,
    required int progressIndex,
    required Color statusColor,
  }) {
    final index = state.reports.indexWhere((report) => report.id == reportId);
    if (index == -1) return;

    final existing = state.reports[index];
    final updated = existing.copyWith(
      statusLabel: statusLabel,
      progressIndex: progressIndex,
      statusColor: statusColor,
      submittedAgo: existing.submittedAgo,
    );

    final reports = [...state.reports];
    reports[index] = updated;

    state = state.copyWith(reports: reports);
    _persistCurrentReports();

    unawaited(
      onReportStatusChanged(
        reportTitle: updated.title,
        statusLabel: statusLabel,
      ),
    );
  }

  void _persistCurrentReports() {
    unawaited(_persistReports(state.reports));
  }

  Future<void> _loadPersistedReports() async {
    final prefs = await _safeGetPrefs();
    if (prefs == null) return;

    final rawJson = prefs.getString(_reportsCacheKey);
    if (rawJson == null || rawJson.isEmpty) {
      await _persistReports(state.reports);
      return;
    }

    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is! List) return;

      final reports = decoded
          .whereType<Map>()
          .map((item) => MyReport.fromJson(Map<String, dynamic>.from(item)))
          .where((report) => report.id.isNotEmpty && report.title.isNotEmpty)
          .toList();

      if (reports.isEmpty || !mounted) return;
      state = state.copyWith(reports: reports);
    } catch (_) {
      // Keep defaults if persisted payload is malformed.
    }
  }

  Future<void> _persistReports(List<MyReport> reports) async {
    final prefs = await _safeGetPrefs();
    if (prefs == null) return;

    final payload = reports.map((report) => report.toJson()).toList();
    await prefs.setString(_reportsCacheKey, jsonEncode(payload));
  }

  Future<SharedPreferences?> _safeGetPrefs() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (_) {
      return null;
    }
  }
}

final myReportsProvider =
    StateNotifierProvider<MyReportsNotifier, MyReportsState>((ref) {
      final notifications = ref.read(notificationsProvider.notifier);

      return MyReportsNotifier(
        onReportStatusChanged: ({required reportTitle, required statusLabel}) {
          return notifications.notifyReportStatusChanged(
            reportTitle: reportTitle,
            statusLabel: statusLabel,
          );
        },
      );
    });

final filteredMyReportsProvider = Provider<List<MyReport>>((ref) {
  final state = ref.watch(myReportsProvider);
  final query = state.searchQuery;

  if (query.isEmpty) {
    return state.reports;
  }

  return state.reports
      .where(
        (report) =>
            report.title.contains(query) || report.reportType.contains(query),
      )
      .toList();
});
