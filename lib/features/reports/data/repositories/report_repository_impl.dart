import '../../../../core/network/connectivity_service.dart';
import '../../domain/report_model.dart';
import '../../domain/repositories/report_repository.dart';
import '../data_sources/report_local_data_source.dart';
import '../data_sources/report_remote_data_source.dart';

class ReportRepositoryImpl implements ReportRepository {
  ReportRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.connectivityService,
  });

  final ReportLocalDataSource localDataSource;
  final ReportRemoteDataSource remoteDataSource;
  final ConnectivityService connectivityService;

  @override
  Future<List<ReportModel>> hydrateReports({
    List<ReportModel> fallback = const [],
  }) async {
    final cached = await localDataSource.readReports();
    if (cached.isNotEmpty) {
      return cached;
    }

    if (fallback.isNotEmpty) {
      await localDataSource.saveReports(fallback);
      return fallback;
    }

    return const [];
  }

  @override
  Future<List<ReportModel>> getCachedReports() {
    return localDataSource.readReports();
  }

  @override
  Future<ReportModel> createReport(ReportModel report) async {
    final reports = await localDataSource.readReports();
    final localId = report.localId ?? _generateLocalId();
    final enrichedReport = report.copyWith(localId: localId);

    final isOnline = await connectivityService.isOnline();
    if (!isOnline) {
      final pending = enrichedReport.copyWith(isSynced: false);
      await localDataSource.saveReports([pending, ...reports]);
      return pending;
    }

    try {
      await _submitWithRetry(enrichedReport, maxAttempts: 2);
      final synced = enrichedReport.copyWith(isSynced: true);
      await localDataSource.saveReports([synced, ...reports]);
      return synced;
    } catch (_) {
      final pending = enrichedReport.copyWith(isSynced: false);
      await localDataSource.saveReports([pending, ...reports]);
      return pending;
    }
  }

  @override
  Future<void> updateReport(ReportModel report) async {
    final reports = await localDataSource.readReports();
    final index = reports.indexWhere(
      (entry) => entry.localId == report.localId || entry.id == report.id,
    );

    if (index == -1) {
      await localDataSource.saveReports([report, ...reports]);
      return;
    }

    final updated = [...reports];
    updated[index] = report;
    await localDataSource.saveReports(updated);
  }

  @override
  Future<List<ReportModel>> syncUnsyncedReports() async {
    final isOnline = await connectivityService.isOnline();
    if (!isOnline) {
      return const [];
    }

    final cached = await localDataSource.readReports();
    if (cached.isEmpty) {
      return const [];
    }

    final syncedReports = <ReportModel>[];
    final updated = <ReportModel>[];

    for (final report in cached) {
      if (report.isSynced) {
        updated.add(report);
        continue;
      }

      try {
        await _submitWithRetry(report, maxAttempts: 3);
        final synced = report.copyWith(isSynced: true);
        updated.add(synced);
        syncedReports.add(synced);
      } catch (_) {
        updated.add(report);
      }
    }

    await localDataSource.saveReports(updated);
    return syncedReports;
  }

  Future<void> _submitWithRetry(
    ReportModel report, {
    int maxAttempts = 3,
  }) async {
    var attempt = 0;
    while (attempt < maxAttempts) {
      try {
        await remoteDataSource.submitReport(report);
        return;
      } catch (_) {
        attempt++;
        if (attempt >= maxAttempts) {
          rethrow;
        }
        await Future.delayed(Duration(milliseconds: 300 * attempt));
      }
    }
  }

  String _generateLocalId() {
    return 'local-${DateTime.now().microsecondsSinceEpoch}';
  }
}
