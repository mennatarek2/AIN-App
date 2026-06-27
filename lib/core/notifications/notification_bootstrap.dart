import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/state/auth_state_simple.dart';
import '../../features/notifications/presentation/providers/notifications_provider.dart';
import 'fcm_notification_service.dart';

/// Bootstraps push notifications for authenticated users:
///   1. Initializes FCM / local notification service
///   2. Registers device token with backend
///   3. Loads notifications inbox
class NotificationBootstrap {
  NotificationBootstrap(this._ref);

  final Ref _ref;

  Future<void> onAuthenticated() async {
    final pushService = _ref.read(pushNotificationServiceProvider);
    await pushService.initialize();

    if (pushService is FcmNotificationService) {
      final fcm = pushService;
      final manager = _ref.read(deviceTokenManagerProvider);
      await manager.registerCurrentToken(fcm);

      fcm.onMessageReceived = () {
        _ref.read(notificationsProvider.notifier).refresh();
        _ref.read(notificationsProvider.notifier).refreshUnreadCount();
      };

      fcm.onTokenRefresh = (token) => manager.registerToken(token);
    }

    await _ref.read(notificationsProvider.notifier).loadInitial();
  }

  Future<void> onUnauthenticated() async {
    final pushService = _ref.read(pushNotificationServiceProvider);

    if (pushService is FcmNotificationService) {
      await pushService.deleteDeviceToken();
    }
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
