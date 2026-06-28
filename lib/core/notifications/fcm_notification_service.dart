import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../features/notifications/data/models/notification_model.dart';
import 'notification_channels.dart';
import 'notification_payload_codec.dart';
import 'pending_notification_launch.dart';
import 'push_notification_service.dart';

/// Top-level background handler — required by Firebase.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Notification payload messages are shown automatically in the system tray.
}

class FcmNotificationService implements PushNotificationService {
  FcmNotificationService();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  bool _firebaseAvailable = false;
  final Set<String> _recentBannerIds = {};

  /// When true, SignalR handles foreground delivery — skip FCM local banners.
  bool Function()? isRealtimeConnected;

  VoidCallback? onMessageReceived;
  Future<void> Function(String token)? onTokenRefresh;

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

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    await _localPlugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    await createNotificationChannels();
    await requestPermissions();

    final token = await getDeviceToken();
    if (token != null) {
      onTokenRefresh?.call(token);
    }

    _messaging.onTokenRefresh.listen((token) {
      onTokenRefresh?.call(token);
    });

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      PendingNotificationLaunch.store(initial);
    }

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

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

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
      payload: reportId != null ? '/reports/$reportId' : null,
    );
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
    int priority = 1,
    String? notificationId,
  }) async {
    if (notificationId != null && _recentBannerIds.contains(notificationId)) {
      return;
    }

    await initialize();

    final channelId = channelIdForPriority(priority);
    final isCritical = priority >= 3;
    final isHigh = priority >= 2;

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelNameForId(channelId),
      importance: isCritical ? Importance.max : Importance.high,
      priority: isCritical ? Priority.max : Priority.high,
      playSound: true,
      enableVibration: isHigh,
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

    final showId = notificationId != null
        ? notificationId.hashCode.abs() % 2147483647
        : DateTime.now().microsecondsSinceEpoch.remainder(100000);

    await _localPlugin.show(showId, title, body, details, payload: payload);

    if (notificationId != null) {
      _recentBannerIds.add(notificationId);
      Future<void>.delayed(const Duration(seconds: 30), () {
        _recentBannerIds.remove(notificationId);
      });
    }
  }

  Future<void> showLocalFromModel(NotificationModel notification) async {
    await showLocalNotification(
      title: notification.title,
      body: notification.body,
      payload: NotificationPayloadCodec.fromModel(notification),
      priority: notification.priority,
      notificationId: notification.id,
    );
  }

  void _onForegroundMessage(RemoteMessage message) {
    final realtimeActive = isRealtimeConnected?.call() ?? false;

    if (!realtimeActive) {
      final notification = message.notification;
      final priority =
          int.tryParse(message.data['priority']?.toString() ?? '') ?? 1;
      final id = message.data['id']?.toString();

      if (notification != null) {
        showLocalNotification(
          title: notification.title ?? 'إشعار جديد',
          body: notification.body ?? '',
          payload: NotificationPayloadCodec.fromData(message.data),
          priority: priority,
          notificationId: id,
        );
      }
    }

    onMessageReceived?.call();
  }

  void _onMessageOpenedApp(RemoteMessage message) {
    _handleTap(message);
    onMessageReceived?.call();
  }

  void _onLocalNotificationTap(NotificationResponse response) {
    NotificationPayloadCodec.route(response.payload);
  }

  void _handleTap(RemoteMessage message) {
    NotificationPayloadCodec.route(NotificationPayloadCodec.fromData(message.data));
  }
}
