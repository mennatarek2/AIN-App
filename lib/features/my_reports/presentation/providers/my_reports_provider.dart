import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../notifications/presentation/providers/notifications_provider.dart';
import '../../../reports/domain/report_model.dart';
import '../../../reports/domain/repositories/report_repository.dart';
import '../../../reports/presentation/providers/report_data_providers.dart';

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
  MyReportsNotifier({
    required this.onReportStatusChanged,
    required ReportRepository reportRepository,
  }) : _reportRepository = reportRepository,
       super(_initialState()) {
    _hydrateReports();
  }

  final Future<void> Function({
    required String reportTitle,
    required String statusLabel,
  })
  onReportStatusChanged;
  final ReportRepository _reportRepository;

  static MyReportsState _initialState() {
    return MyReportsState(
      reports: _defaultReports,
      searchQuery: '',
      filterEnabled: false,
    );
  }

  static const List<MyReport> _defaultReports = [
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
      isSynced: true,
      localId: 'seed-report-1',
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
      isSynced: true,
      localId: 'seed-report-2',
    ),
  ];

  void setSearchQuery(String value) {
    state = state.copyWith(searchQuery: value.trim());
  }

  void toggleFilter() {
    state = state.copyWith(filterEnabled: !state.filterEnabled);
  }

  Future<void> addReportFromSubmission({
    required String title,
    required String description,
    required String reportType,
    required double latitude,
    required double longitude,
    String? locationAddress,
  }) async {
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
      isSynced: false,
    );

    final stored = await _reportRepository.createReport(report);
    final updatedReports = _replaceOrInsert(state.reports, stored);
    state = state.copyWith(reports: updatedReports);
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
    unawaited(_reportRepository.updateReport(updated));

    unawaited(
      onReportStatusChanged(
        reportTitle: updated.title,
        statusLabel: statusLabel,
      ),
    );
  }

  Future<void> syncPendingReports() async {
    await _reportRepository.syncUnsyncedReports();
    final refreshed = await _reportRepository.getCachedReports();
    if (!mounted || refreshed.isEmpty) return;
    state = state.copyWith(reports: refreshed);
  }

  Future<void> _hydrateReports() async {
    final reports = await _reportRepository.hydrateReports(
      fallback: _defaultReports,
    );
    if (!mounted || reports.isEmpty) return;
    state = state.copyWith(reports: reports);
  }

  List<MyReport> _replaceOrInsert(List<MyReport> reports, MyReport report) {
    final index = reports.indexWhere(
      (entry) => entry.localId == report.localId || entry.id == report.id,
    );

    if (index == -1) {
      return [report, ...reports];
    }

    final nextReports = [...reports];
    nextReports[index] = report;
    return nextReports;
  }
}

final myReportsProvider =
    StateNotifierProvider<MyReportsNotifier, MyReportsState>((ref) {
      final notifications = ref.read(notificationsProvider.notifier);
      final reportRepository = ref.read(reportRepositoryProvider);

      final notifier = MyReportsNotifier(
        onReportStatusChanged: ({required reportTitle, required statusLabel}) {
          return notifications.notifyReportStatusChanged(
            reportTitle: reportTitle,
            statusLabel: statusLabel,
          );
        },
        reportRepository: reportRepository,
      );

      return notifier;
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
