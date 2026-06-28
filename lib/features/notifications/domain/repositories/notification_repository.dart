import '../../data/models/notification_model.dart';

abstract class NotificationRepository {
  Future<List<NotificationModel>> fetchNotifications({
    int pageIndex = 1,
    int pageSize = 20,
  });

  Future<int> fetchUnreadCount();

  Future<void> markAsRead(String id);

  Future<void> markAllAsRead();

  Future<void> deleteNotification(String id);

  Future<void> clearAll();

  Future<void> registerDeviceToken({
    required String token,
    required String platform,
  });

  Future<void> deleteDeviceToken({required String token});
}
