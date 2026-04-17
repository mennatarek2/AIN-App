import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ain_graduation_project/core/network/connectivity_service.dart';
import 'package:ain_graduation_project/features/reports/data/data_sources/report_local_data_source.dart';
import 'package:ain_graduation_project/features/reports/data/data_sources/report_remote_data_source.dart';
import 'package:ain_graduation_project/features/reports/data/repositories/report_repository_impl.dart';
import 'package:ain_graduation_project/features/reports/domain/report_model.dart';

class _FakeConnectivityService extends ConnectivityService {
  _FakeConnectivityService(this._online);

  bool _online;

  set online(bool value) => _online = value;

  @override
  Future<bool> isOnline() async => _online;
}

class _FakeReportRemoteDataSource extends ReportRemoteDataSource {
  _FakeReportRemoteDataSource({this.failuresBeforeSuccess = 0});

  int failuresBeforeSuccess;
  int attemptCount = 0;

  @override
  Future<void> submitReport(ReportModel report) async {
    attemptCount++;
    if (attemptCount <= failuresBeforeSuccess) {
      throw Exception('forced remote failure');
    }
  }
}

ReportModel _report({required String id, bool isSynced = false}) {
  return ReportModel(
    id: id,
    title: 'Test Report $id',
    description: 'Description',
    submittedAgo: 'now',
    fullDescription: 'Description',
    reportType: 'Safety',
    imagePath: 'assets/images/report_image.png',
    progressIndex: 0,
    statusLabel: 'Submitted',
    statusColor: const Color(0xFF2A9AF4),
    latitude: 30.0,
    longitude: 31.0,
    locationAddress: 'Cairo',
    isSynced: isSynced,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ReportRepositoryImpl', () {
    late ReportLocalDataSource localDataSource;
    late _FakeConnectivityService connectivity;
    late _FakeReportRemoteDataSource remoteDataSource;
    late ReportRepositoryImpl repository;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      localDataSource = ReportLocalDataSource();
      connectivity = _FakeConnectivityService(false);
      remoteDataSource = _FakeReportRemoteDataSource();
      repository = ReportRepositoryImpl(
        localDataSource: localDataSource,
        remoteDataSource: remoteDataSource,
        connectivityService: connectivity,
      );
    });

    test('creates unsynced report when offline', () async {
      final created = await repository.createReport(_report(id: 'r-1'));

      expect(created.isSynced, isFalse);
      expect(created.localId, isNotNull);

      final cached = await localDataSource.readReports();
      expect(cached, hasLength(1));
      expect(cached.first.isSynced, isFalse);
      expect(cached.first.localId, created.localId);
    });

    test('syncs unsynced reports when online', () async {
      await localDataSource.saveReports([
        _report(id: 'r-2').copyWith(localId: 'local-r2', isSynced: false),
      ]);

      connectivity.online = true;

      final synced = await repository.syncUnsyncedReports();
      final cached = await localDataSource.readReports();

      expect(synced, hasLength(1));
      expect(synced.first.isSynced, isTrue);
      expect(cached.first.isSynced, isTrue);
    });

    test('retries remote submission and eventually succeeds', () async {
      remoteDataSource = _FakeReportRemoteDataSource(failuresBeforeSuccess: 2);
      repository = ReportRepositoryImpl(
        localDataSource: localDataSource,
        remoteDataSource: remoteDataSource,
        connectivityService: connectivity,
      );

      await localDataSource.saveReports([
        _report(id: 'r-3').copyWith(localId: 'local-r3', isSynced: false),
      ]);

      connectivity.online = true;
      final synced = await repository.syncUnsyncedReports();

      expect(synced, hasLength(1));
      expect(remoteDataSource.attemptCount, 3);

      final cached = await localDataSource.readReports();
      expect(cached.first.isSynced, isTrue);
    });

    test('keeps report unsynced when retries are exhausted', () async {
      remoteDataSource = _FakeReportRemoteDataSource(failuresBeforeSuccess: 5);
      repository = ReportRepositoryImpl(
        localDataSource: localDataSource,
        remoteDataSource: remoteDataSource,
        connectivityService: connectivity,
      );

      await localDataSource.saveReports([
        _report(id: 'r-4').copyWith(localId: 'local-r4', isSynced: false),
      ]);

      connectivity.online = true;
      final synced = await repository.syncUnsyncedReports();

      expect(synced, isEmpty);
      expect(remoteDataSource.attemptCount, 3);

      final cached = await localDataSource.readReports();
      expect(cached.first.isSynced, isFalse);
    });
  });
}
