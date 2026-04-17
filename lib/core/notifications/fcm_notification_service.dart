import 'package:flutter/foundation.dart';

import 'push_notification_service.dart';

class FcmNotificationService implements PushNotificationService {
  bool _isInitialized = false;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    // TODO(phase-5): Initialize Firebase Messaging and background handlers.
    debugPrint(
      'FCM service scaffold active. '
      'Real Firebase setup will be enabled in Phase 5 backend integration.',
    );

    _isInitialized = true;
  }

  @override
  Future<void> requestPermissions() async {
    // TODO(phase-5): Request FCM permissions and handle denied/provisional states.
  }

  @override
  Future<void> showReportNotification({
    required String title,
    required String body,
  }) async {
    await initialize();

    // TODO(phase-5): Route through Firebase messaging / local fallback behavior.
    debugPrint('FCM scaffold notification: $title - $body');
  }
}
