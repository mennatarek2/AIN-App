import '../report_model.dart';

abstract class ReportRepository {
  Future<List<ReportModel>> hydrateReports({
    List<ReportModel> fallback = const [],
  });

  Future<List<ReportModel>> getCachedReports();

  Future<ReportModel> createReport(ReportModel report);

  Future<void> updateReport(ReportModel report);

  Future<List<ReportModel>> syncUnsyncedReports();

  Future<List<ReportModel>> fetchPublicReports({
    int pageNumber = 1,
    int pageSize = 10,
    String? categoryId,
    String? status,
    String? search,
  });

  Future<List<ReportModel>> fetchVisibleReports({
    int pageNumber = 1,
    int pageSize = 20,
  });

  /// Fetch a single report by ID (authenticated — allows confidential access for owner).
  Future<ReportModel?> getReport(String id);

  /// Update the visibility of a report (owner only).
  Future<void> updateVisibility(String id, String visibility);

  /// Permanently delete a report (owner only). Returns 204 on success.
  Future<void> deleteReport(String id);

  /// Fetch only the authenticated user's own submitted reports.
  Future<List<ReportModel>> fetchMyReports({
    int pageNumber = 1,
    int pageSize = 10,
    String? statusFilter,
  });

  /// Submit a new report with upload progress tracking.
  Future<ReportModel> submitReportWithProgress(
    ReportModel report, {
    void Function(double)? onProgress,
    List<String>? attachmentPaths,
  });
}
