import 'dart:convert';

import '../../features/notifications/data/models/notification_model.dart';
import 'notification_router.dart';

/// Encodes notification tap payloads for [flutter_local_notifications].
class NotificationPayloadCodec {
  static String fromModel(NotificationModel notification) {
    return jsonEncode({
      'actionUrl': notification.actionUrl,
      'resourceId': notification.resourceId,
      'resourceType': notification.resourceType,
      'type': notification.type.value,
    });
  }

  static String fromData(Map<String, dynamic> data) {
    return jsonEncode({
      'actionUrl': data['actionUrl'],
      'resourceId': data['resourceId'],
      'resourceType': data['resourceType'],
      'type': data['type'],
    });
  }

  static void route(String? payload) {
    if (payload == null || payload.isEmpty) return;

    try {
      final map = jsonDecode(payload) as Map<String, dynamic>;
      final typeRaw = map['type'];
      final typeInt = typeRaw is int
          ? typeRaw
          : int.tryParse(typeRaw?.toString() ?? '');

      NotificationRouter.go(
        map['actionUrl'] as String?,
        resourceType: map['resourceType'] as String?,
        resourceId: map['resourceId'] as String?,
        type: typeInt != null ? NotificationType.fromInt(typeInt) : null,
      );
    } catch (_) {
      NotificationRouter.go(payload);
    }
  }
}
