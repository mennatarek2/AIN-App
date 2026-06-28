import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';

import 'notification_payload_codec.dart';
import 'push_notification_service.dart';

// ─── Global navigator key ─────────────────────────────────────────────────────
/// Used to navigate from notification tap callbacks, which execute outside the
/// normal widget tree lifecycle.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class LocalNotificationService implements PushNotificationService {
  LocalNotificationService();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  bool _isAvailable = true;

  // ── Channels ──────────────────────────────────────────────────────────────

  static const AndroidNotificationChannel _reportsChannel =
      AndroidNotificationChannel(
        'reports_updates',
        'Report Updates',
        description: 'Notifications for report submission and status updates',
        importance: Importance.high,
      );

  static const AndroidNotificationChannel _sosChannel =
      AndroidNotificationChannel(
        'sos_alerts',
        'نداء طوارئ',
        description: 'Notifications for active SOS alerts in your communities',
        importance: Importance.max,
        enableVibration: true,
        playSound: true,
      );

  // ── Initialize ────────────────────────────────────────────────────────────

  @override
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
      await _plugin.initialize(
        settings,
        onDidReceiveNotificationResponse: _onNotificationTap,
      );

      final androidImpl = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidImpl?.createNotificationChannel(_reportsChannel);
      await androidImpl?.createNotificationChannel(_sosChannel);

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

  // ── Tap handler ───────────────────────────────────────────────────────────

  void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;

    if (payload.startsWith('sos:')) return;

    NotificationPayloadCodec.route(payload);
  }

  // ── Permissions ───────────────────────────────────────────────────────────

  @override
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

  // ── Report notifications ──────────────────────────────────────────────────

  @override
  Future<void> showReportNotification({
    required String title,
    required String body,
    String? reportId,
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
      await _plugin.show(
        id,
        title,
        body,
        details,
        payload: reportId != null ? 'report:$reportId' : null,
      );
    } on MissingPluginException catch (_) {
      _isAvailable = false;
    }
  }

  // ── SOS notifications ─────────────────────────────────────────────────────

  Future<void> showSOSAlert({
    required String sosId,
    required String severity,
    String? message,
    String? communityName,
  }) async {
    await initialize();
    if (!_isAvailable) return;

    final severityLabel = _severityLabel(severity);
    final body = message?.isNotEmpty == true
        ? '$severityLabel — $message'
        : severityLabel;

    final androidDetails = AndroidNotificationDetails(
      'sos_alerts',
      'نداء طوارئ',
      channelDescription:
          'Notifications for active SOS alerts in your communities',
      importance: Importance.max,
      priority: Priority.high,
      color: const Color(0xFFEF4444),
      enableVibration: true,
      playSound: true,
      ticker: 'نداء طوارئ',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final id = sosId.hashCode.abs() % 2147483647;
    try {
      await _plugin.show(
        id,
        '🚨 نداء طوارئ جديد',
        body,
        details,
        payload: 'sos:$sosId',
      );
    } on MissingPluginException catch (_) {
      _isAvailable = false;
    }
  }

  Future<void> showSOSResolved({
    required String sosId,
    required String resolvedBy,
  }) async {
    await initialize();
    if (!_isAvailable) return;

    const androidDetails = AndroidNotificationDetails(
      'sos_alerts',
      'نداء طوارئ',
      importance: Importance.high,
      priority: Priority.high,
      color: Color(0xFF22C55E),
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final id = (sosId.hashCode.abs() + 1) % 2147483647;
    try {
      await _plugin.show(
        id,
        '✅ تم حل نداء الطوارئ',
        'تم الحل بواسطة: $resolvedBy',
        details,
        payload: 'sos:$sosId',
      );
    } on MissingPluginException catch (_) {
      _isAvailable = false;
    }
  }

  Future<void> cancelNotification(int id) async {
    if (!_isAvailable) return;
    try {
      await _plugin.cancel(id);
    } catch (_) {}
  }

  String _severityLabel(String severity) {
    return switch (severity.toLowerCase()) {
      'high' => 'مستوى عالٍ',
      'critical' => 'حرج',
      _ => 'عادي',
    };
  }
}
