import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_providers.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/data_sources/report_local_data_source.dart';
import '../../data/data_sources/report_remote_data_source.dart';
import '../../data/repositories/report_repository_impl.dart';
import '../../domain/repositories/report_repository.dart';

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});

final connectivityStatusProvider = StreamProvider<bool>((ref) {
  return ref.watch(connectivityServiceProvider).onlineStatusStream;
});

final reportLocalDataSourceProvider = Provider<ReportLocalDataSource>((ref) {
  return ReportLocalDataSource();
});

final reportRemoteDataSourceProvider = Provider<ReportRemoteDataSource>((ref) {
  final userLocal = ref.watch(userLocalDataSourceProvider);
  return ReportRemoteDataSource(
    ref.watch(apiClientProvider),
    readToken: userLocal.getCachedToken,
  );
});

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepositoryImpl(
    localDataSource: ref.watch(reportLocalDataSourceProvider),
    remoteDataSource: ref.watch(reportRemoteDataSourceProvider),
    connectivityService: ref.watch(connectivityServiceProvider),
  );
});
