import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final _localNotifications = FlutterLocalNotificationsPlugin();

/// Creates Android notification channels before any FCM messages arrive.
Future<void> createNotificationChannels() async {
  final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();
  if (androidPlugin == null) return;

  await androidPlugin.createNotificationChannel(
    const AndroidNotificationChannel(
      'ain_sos_channel',
      'SOS Alerts',
      description: 'Critical emergency SOS notifications',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    ),
  );

  await androidPlugin.createNotificationChannel(
    const AndroidNotificationChannel(
      'ain_default_channel',
      'General Notifications',
      description: 'Community updates, reports, and system alerts',
      importance: Importance.high,
      playSound: true,
    ),
  );
}

String channelIdForPriority(int priority) =>
    priority >= 3 ? 'ain_sos_channel' : 'ain_default_channel';

String channelNameForId(String channelId) =>
    channelId == 'ain_sos_channel' ? 'SOS Alerts' : 'General Notifications';
