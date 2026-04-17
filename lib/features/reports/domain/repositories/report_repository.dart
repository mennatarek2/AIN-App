import '../report_model.dart';

abstract class ReportRepository {
  Future<List<ReportModel>> hydrateReports({
    List<ReportModel> fallback = const [],
  });

  Future<List<ReportModel>> getCachedReports();

  Future<ReportModel> createReport(ReportModel report);

  Future<void> updateReport(ReportModel report);

  Future<List<ReportModel>> syncUnsyncedReports();
}
