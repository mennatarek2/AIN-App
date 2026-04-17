import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';

class LocalNotificationService {
  LocalNotificationService();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  bool _isAvailable = true;

  static const AndroidNotificationChannel _reportsChannel =
      AndroidNotificationChannel(
        'reports_updates',
        'Report Updates',
        description: 'Notifications for report submission and status updates',
        importance: Importance.high,
      );

  Future<void> initialize() async {
    if (_isInitialized || !_isAvailable) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    try {
      await _plugin.initialize(settings);

      final androidImpl = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidImpl?.createNotificationChannel(_reportsChannel);

      await requestPermissions();
      _isInitialized = true;
    } on MissingPluginException catch (_) {
      _isAvailable = false;
      debugPrint(
        'Local notifications plugin is unavailable. '
        'Run a full app restart after adding the plugin.',
      );
    }
  }

  Future<void> requestPermissions() async {
    if (!_isAvailable) return;

    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidImpl?.requestNotificationsPermission();

    final iosImpl = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    await iosImpl?.requestPermissions(alert: true, badge: true, sound: true);

    final macosImpl = _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >();
    await macosImpl?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> showReportNotification({
    required String title,
    required String body,
  }) async {
    await initialize();
    if (!_isAvailable) return;

    const androidDetails = AndroidNotificationDetails(
      'reports_updates',
      'Report Updates',
      channelDescription:
          'Notifications for report submission and status updates',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final id = DateTime.now().millisecondsSinceEpoch.remainder(2147483647);
    try {
      await _plugin.show(id, title, body, details);
    } on MissingPluginException catch (_) {
      _isAvailable = false;
      debugPrint(
        'Local notifications plugin is unavailable during show(). '
        'Run a full app restart after adding the plugin.',
      );
    }
  }
}
