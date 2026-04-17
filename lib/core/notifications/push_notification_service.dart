abstract class PushNotificationService {
  Future<void> initialize();

  Future<void> requestPermissions();

  Future<void> showReportNotification({
    required String title,
    required String body,
  });
}
