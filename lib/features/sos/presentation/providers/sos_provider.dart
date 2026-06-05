import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/sos_remote_data_source.dart';

final sosRemoteDataSourceProvider = Provider<SosRemoteDataSource>((ref) {
  final userLocal = ref.watch(userLocalDataSourceProvider);
  return SosRemoteDataSource(
    ref.watch(apiClientProvider),
    readToken: userLocal.getCachedToken,
  );
});
