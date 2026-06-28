import '../../domain/repositories/notification_repository.dart';
import '../data_sources/notification_remote_data_source.dart';
import '../models/notification_model.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl(this._remoteDataSource);

  final NotificationRemoteDataSource _remoteDataSource;

  @override
  Future<List<NotificationModel>> fetchNotifications({
    int pageIndex = 1,
    int pageSize = 20,
  }) {
    return _remoteDataSource.fetchNotifications(
      page: pageIndex,
      pageSize: pageSize,
    );
  }

  @override
  Future<int> fetchUnreadCount() => _remoteDataSource.fetchUnreadCount();

  @override
  Future<void> markAsRead(String id) => _remoteDataSource.markAsRead(id);

  @override
  Future<void> markAllAsRead() => _remoteDataSource.markAllAsRead();

  @override
  Future<void> deleteNotification(String id) => _remoteDataSource.delete(id);

  @override
  Future<void> clearAll() => _remoteDataSource.clearAll();

  @override
  Future<void> registerDeviceToken({
    required String token,
    required String platform,
  }) {
    return _remoteDataSource.registerDeviceToken(
      token: token,
      platform: platform,
    );
  }

  @override
  Future<void> deleteDeviceToken({required String token}) {
    return _remoteDataSource.deleteDeviceToken(token: token);
  }
}
