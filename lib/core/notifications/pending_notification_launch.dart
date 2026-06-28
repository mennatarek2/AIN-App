import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';

import 'notification_payload_codec.dart';

/// Defers navigation from a cold-start notification tap until the navigator exists.
class PendingNotificationLaunch {
  PendingNotificationLaunch._();

  static RemoteMessage? _pendingMessage;

  static void store(RemoteMessage message) {
    _pendingMessage = message;
  }

  static void handleIfNeeded() {
    final message = _pendingMessage;
    if (message == null) return;
    _pendingMessage = null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(const Duration(milliseconds: 300), () {
        NotificationPayloadCodec.route(
          NotificationPayloadCodec.fromData(message.data),
        );
      });
    });
  }
}
