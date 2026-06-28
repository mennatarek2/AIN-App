import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/state/auth_state_simple.dart';
import '../../features/notifications/presentation/providers/notifications_provider.dart';
import '../realtime/signalr_notification_service.dart';
import 'fcm_notification_service.dart';

/// Bootstraps push notifications for authenticated users:
///   1. Initializes FCM / local notification service
///   2. Registers device token with backend
///   3. Loads notifications inbox
///   4. Wires SignalR notification hub → inbox + badge
class NotificationBootstrap {
  NotificationBootstrap(this._ref);

  final Ref _ref;
  StreamSubscription<dynamic>? _notificationSub;
  StreamSubscription<dynamic>? _unreadSub;

  Future<void> onAuthenticated() async {
    final pushService = _ref.read(pushNotificationServiceProvider);
    await pushService.initialize();

    if (pushService is FcmNotificationService) {
      final fcm = pushService;
      final manager = _ref.read(deviceTokenManagerProvider);
      await manager.registerCurrentToken(fcm);

      fcm.isRealtimeConnected = () =>
          _ref.read(signalRNotificationServiceProvider).isConnected;

      fcm.onMessageReceived = () {
        _ref.read(notificationsProvider.notifier).refreshUnreadCount();
        if (!(fcm.isRealtimeConnected?.call() ?? false)) {
          _ref.read(notificationsProvider.notifier).refresh();
        }
      };

      fcm.onTokenRefresh = (token) => manager.registerToken(token);
    }

    final userLocal = _ref.read(userLocalDataSourceProvider);
    final signalR = _ref.read(signalRNotificationServiceProvider);
    try {
      await signalR.connect(
        () => userLocal.getCachedToken().then((t) => t ?? ''),
      );
    } catch (e) {
      debugPrint('[NotificationBootstrap] SignalR connect failed: $e');
    }

    await _wireSignalRNotifications();
    await _ref.read(notificationsProvider.notifier).loadInitial();
  }

  Future<void> _wireSignalRNotifications() async {
    await _notificationSub?.cancel();
    await _unreadSub?.cancel();

    final signalR = _ref.read(signalRNotificationServiceProvider);
    final notifier = _ref.read(notificationsProvider.notifier);
    final pushService = _ref.read(pushNotificationServiceProvider);

    _notificationSub = signalR.onNotification.listen((notification) async {
      notifier.prependNotification(notification);

      if (pushService is FcmNotificationService) {
        await pushService.showLocalFromModel(notification);
      }
    });

    _unreadSub = signalR.onUnreadCount.listen(notifier.setUnreadCount);
  }

  Future<void> onUnauthenticated() async {
    await _notificationSub?.cancel();
    await _unreadSub?.cancel();
    _notificationSub = null;
    _unreadSub = null;

    final manager = _ref.read(deviceTokenManagerProvider);
    await manager.unregisterCachedToken();

    final pushService = _ref.read(pushNotificationServiceProvider);
    if (pushService is FcmNotificationService) {
      await pushService.deleteDeviceToken();
    }

    await _ref.read(signalRNotificationServiceProvider).disconnect();
  }
}

final notificationBootstrapProvider = Provider<NotificationBootstrap>((ref) {
  return NotificationBootstrap(ref);
});

/// Wires auth state → notification bootstrap (register token / load inbox).
final notificationAuthListenerProvider = Provider<void>((ref) {
  ref.listen<AuthState>(authNotifierProvider, (previous, next) async {
    final bootstrap = ref.read(notificationBootstrapProvider);

    if (next is AuthAuthenticated) {
      await bootstrap.onAuthenticated();
    } else if (next is AuthUnauthenticated) {
      await bootstrap.onUnauthenticated();
    }
  });
});
