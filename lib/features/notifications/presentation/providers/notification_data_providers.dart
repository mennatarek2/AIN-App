import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/data_sources/notification_remote_data_source.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../domain/repositories/notification_repository.dart';

final notificationRemoteDataSourceProvider =
    Provider<NotificationRemoteDataSource>((ref) {
      final userLocal = ref.watch(userLocalDataSourceProvider);
      return NotificationRemoteDataSource(
        ref.watch(apiClientProvider),
        readToken: userLocal.getCachedToken,
      );
    });

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepositoryImpl(
    ref.watch(notificationRemoteDataSourceProvider),
  );
});
