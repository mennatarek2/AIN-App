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
    int pageSize = 20,
  });

  Future<List<ReportModel>> fetchVisibleReports({
    int pageNumber = 1,
    int pageSize = 20,
  });
}
