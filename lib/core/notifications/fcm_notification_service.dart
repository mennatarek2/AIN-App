import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'local_notification_service.dart';
import 'push_notification_service.dart';

/// Top-level background handler — must be a top-level function.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[FCM] Background message: ${message.messageId}');
}

class FcmNotificationService implements PushNotificationService {
  FcmNotificationService();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  bool _firebaseAvailable = false;

  /// Called when a foreground/background message should refresh the inbox.
  VoidCallback? onMessageReceived;

  /// Called when FCM rotates the device token.
  Future<void> Function(String token)? onTokenRefresh;

  static const AndroidNotificationChannel _defaultChannel =
      AndroidNotificationChannel(
        'fcm_default',
        'General Notifications',
        description: 'Push notifications from Ai-N',
        importance: Importance.high,
      );

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await Firebase.initializeApp();
      _firebaseAvailable = true;
    } catch (e) {
      debugPrint('[FCM] Firebase init failed: $e');
      await _initializeLocalFallback();
      _isInitialized = true;
      return;
    }

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    await _localPlugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    final androidImpl = _localPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidImpl?.createNotificationChannel(_defaultChannel);

    await requestPermissions();

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

    _messaging.onTokenRefresh.listen((token) {
      onTokenRefresh?.call(token);
      onMessageReceived?.call();
    });

    _isInitialized = true;
  }

  Future<void> _initializeLocalFallback() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    await _localPlugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );
  }

  @override
  Future<void> requestPermissions() async {
    if (!_firebaseAvailable) return;

    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final androidImpl = _localPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidImpl?.requestNotificationsPermission();
  }

  Future<String?> getDeviceToken() async {
    if (!_firebaseAvailable) return null;

    try {
      return await _messaging.getToken();
    } catch (e) {
      debugPrint('[FCM] getToken failed: $e');
      return null;
    }
  }

  Future<void> deleteDeviceToken() async {
    if (!_firebaseAvailable) return;

    try {
      await _messaging.deleteToken();
    } catch (e) {
      debugPrint('[FCM] deleteToken failed: $e');
    }
  }

  @override
  Future<void> showReportNotification({
    required String title,
    required String body,
    String? reportId,
  }) async {
    await showLocalNotification(
      title: title,
      body: body,
      payload: reportId != null ? 'report:$reportId' : null,
    );
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      'fcm_default',
      'General Notifications',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localPlugin.show(
      DateTime.now().microsecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: payload,
    );
  }

  void _onForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification != null) {
      showLocalNotification(
        title: notification.title ?? 'إشعار جديد',
        body: notification.body ?? '',
        payload: _payloadFromData(message.data),
      );
    }
    onMessageReceived?.call();
  }

  void _onMessageOpenedApp(RemoteMessage message) {
    _navigateFromPayload(_payloadFromData(message.data));
    onMessageReceived?.call();
  }

  void _onLocalNotificationTap(NotificationResponse response) {
    _navigateFromPayload(response.payload);
  }

  String? _payloadFromData(Map<String, dynamic> data) {
    if (data.containsKey('reportId')) {
      return 'report:${data['reportId']}';
    }
    if (data.containsKey('sosId')) {
      return 'sos:${data['sosId']}';
    }
    return null;
  }

  void _navigateFromPayload(String? payload) {
    if (payload == null || payload.isEmpty) return;

    final navigator = appNavigatorKey.currentState;
    if (navigator == null) return;

    if (payload.startsWith('report:')) {
      final reportId = payload.substring('report:'.length);
      if (reportId.isNotEmpty) {
        navigator.pushNamed('/report', arguments: reportId);
      }
    } else if (payload.startsWith('sos:')) {
      navigator.pushNamed('/sos');
    }
  }
}
