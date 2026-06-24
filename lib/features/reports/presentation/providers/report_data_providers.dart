import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_providers.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/data_sources/report_local_data_source.dart';
import '../../data/data_sources/report_remote_data_source.dart';
import '../../data/repositories/report_repository_impl.dart';
import '../../domain/repositories/report_repository.dart';
import '../../domain/report_model.dart';

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

/// Fetches a single report by ID. Family provider — re-fetched per unique ID.
/// Throws [ApiException] on 403/404 so the UI can render appropriate error states.
final reportDetailProvider = FutureProvider.family<ReportModel?, String>((
  ref,
  id,
) async {
  return ref.read(reportRepositoryProvider).getReport(id);
});
