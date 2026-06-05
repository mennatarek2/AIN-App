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
    try {
      // First try to load from local cache
      final cached = await localDataSource.readReports();
      print('[ReportRepository] Cached reports count: ${cached.length}');

      if (cached.isNotEmpty) {
        print('[ReportRepository] Returning ${cached.length} cached reports');
        cached.forEach(
          (r) => print('[ReportRepository]   - ${r.id}: ${r.title}'),
        );
        return cached;
      }

      print('[ReportRepository] No cached reports, trying online...');
      final isOnline = await connectivityService.isOnline();

      if (isOnline) {
        final remote = await fetchVisibleReports();
        print('[ReportRepository] Fetched ${remote.length} remote reports');

        if (remote.isNotEmpty) {
          await localDataSource.saveReports(remote);
          return remote;
        }
      } else {
        print('[ReportRepository] Device is offline');
      }

      // Use fallback if no cached or remote reports
      if (fallback.isNotEmpty) {
        print('[ReportRepository] Using ${fallback.length} fallback reports');
        await localDataSource.saveReports(fallback);
        return fallback;
      }

      print('[ReportRepository] No reports available');
      return const [];
    } catch (e) {
      print('[ReportRepository] Error in hydrateReports: $e');
      if (fallback.isNotEmpty) {
        return fallback;
      }
      return const [];
    }
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
    print(
      '[ReportSync] Creating report (online: $isOnline, reportId: ${enrichedReport.id})',
    );

    if (!isOnline) {
      print('[ReportSync] Device offline - saving report as pending sync');
      final pending = enrichedReport.copyWith(isSynced: false);
      await localDataSource.saveReports([pending, ...reports]);
      return pending;
    }

    try {
      if (_canSync(enrichedReport)) {
        print('[ReportSync] Report can be synced - attempting to submit...');
        // Use the server-returned model (has real attachments from server)
        final serverReport = await _submitWithRetry(enrichedReport, maxAttempts: 2);
        final synced = (serverReport ?? enrichedReport).copyWith(isSynced: true);
        print('[ReportSync] Report marked as synced: ${synced.id}');
        await localDataSource.saveReports([synced, ...reports]);
        return synced;
      } else {
        print(
          '[ReportSync] Report cannot be synced yet (missing required fields)',
        );
      }
      final synced = enrichedReport.copyWith(isSynced: true);
      await localDataSource.saveReports([synced, ...reports]);
      return synced;
    } catch (e) {
      print('[ReportSync] Exception during submission: $e - saving as pending');
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

      if (!_canSync(report)) {
        updated.add(report);
        continue;
      }

      try {
        final serverReport = await _submitWithRetry(report, maxAttempts: 3);
        final synced = (serverReport ?? report).copyWith(isSynced: true);
        updated.add(synced);
        syncedReports.add(synced);
      } catch (_) {
        updated.add(report);
      }
    }

    await localDataSource.saveReports(updated);
    return syncedReports;
  }

  @override
  Future<List<ReportModel>> fetchPublicReports({
    int pageNumber = 1,
    int pageSize = 20,
  }) async {
    try {
      return await remoteDataSource.fetchPublicReports(
        pageNumber: pageNumber,
        pageSize: pageSize,
      );
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<List<ReportModel>> fetchVisibleReports({
    int pageNumber = 1,
    int pageSize = 20,
  }) async {
    try {
      return await remoteDataSource.fetchVisibleReports(
        pageNumber: pageNumber,
        pageSize: pageSize,
      );
    } catch (_) {
      return const [];
    }
  }

  /// Submits a report to the server with retry logic.
  /// Returns the server-updated [ReportModel] (with real attachment URLs)
  /// on success, or rethrows the last exception after all attempts fail.
  Future<ReportModel?> _submitWithRetry(
    ReportModel report, {
    int maxAttempts = 3,
  }) async {
    var attempt = 0;
    while (attempt < maxAttempts) {
      try {
        print(
          '[ReportSync] Attempt ${attempt + 1}/$maxAttempts to submit report: ${report.id}',
        );
        final result = await remoteDataSource.submitReport(report);
        print('[ReportSync] Successfully submitted report: ${report.id}');
        return result;
      } catch (e) {
        print('[ReportSync] Attempt ${attempt + 1} failed: $e');
        attempt++;
        if (attempt >= maxAttempts) {
          print(
            '[ReportSync] All ${maxAttempts} attempts failed for report: ${report.id}',
          );
          rethrow;
        }
        await Future.delayed(Duration(milliseconds: 300 * attempt));
      }
    }
    return null;
  }

  String _generateLocalId() {
    return 'local-${DateTime.now().microsecondsSinceEpoch}';
  }

  bool _canSync(ReportModel report) {
    final hasCategory =
        report.categoryName != null && report.categoryName!.trim().isNotEmpty;
    final hasSubCategoryId =
        report.subCategoryId != null && report.subCategoryId!.trim().isNotEmpty;
    final hasVisibility =
        report.visibility != null && report.visibility!.isNotEmpty;

    if (!hasCategory) {
      print('[ReportSync] Cannot sync: missing categoryName');
    }
    if (!hasSubCategoryId) {
      print('[ReportSync] Cannot sync: missing subCategoryId');
    }
    if (!hasVisibility) {
      print('[ReportSync] Cannot sync: missing visibility');
    }

    return hasCategory && hasSubCategoryId && hasVisibility;
  }
}
