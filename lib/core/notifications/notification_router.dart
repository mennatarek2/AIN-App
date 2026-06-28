import '../../config/routes/app_routes.dart';
import '../../features/notifications/data/models/notification_model.dart';
import 'local_notification_service.dart';

/// Maps backend action URLs and resource metadata to in-app navigation.
/// SOS notifications are intentionally not routed to the SOS screen.
class NotificationRouter {
  static void go(
    String? actionUrl, {
    String? resourceType,
    String? resourceId,
    NotificationType? type,
  }) {
    if (type != null && type.isSos) return;

    if (actionUrl != null && actionUrl.isNotEmpty) {
      _pushByUrl(actionUrl);
      return;
    }

    if (type != null) {
      goForType(type, resourceId: resourceId, resourceType: resourceType);
      return;
    }

    switch (resourceType) {
      case 'SOSAlert':
        return;
      case 'Report':
        _pushReport(resourceId);
      case 'Community':
        _pushCommunity();
    }
  }

  static void goForModel(NotificationModel model) {
    go(
      model.actionUrl,
      resourceType: model.resourceType,
      resourceId: model.resourceId,
      type: model.type,
    );
  }

  static void goForType(
    NotificationType type, {
    String? resourceId,
    String? resourceType,
  }) {
    if (type.isSos) return;

    if (type.isReport) {
      _pushReport(resourceId);
      return;
    }

    if (type.isCommunity) {
      _pushCommunity();
      return;
    }

    switch (type) {
      case NotificationType.trustPointsChanged:
      case NotificationType.accountVerified:
        _pushNamed(AppRoutes.profile);
      case NotificationType.passwordChanged:
        _pushNamed(AppRoutes.changePassword);
      default:
        if (resourceType == 'Report') {
          _pushReport(resourceId);
        } else if (resourceType == 'Community') {
          _pushCommunity();
        }
    }
  }

  static void _pushByUrl(String url) {
    final normalized = url.startsWith('/') ? url : '/$url';

    if (normalized.startsWith('/sos/')) return;

    if (normalized.startsWith('/reports/')) {
      final reportId = normalized.split('/').where((s) => s.isNotEmpty).last;
      _pushReport(reportId);
      return;
    }

    if (normalized.contains('/join-requests') ||
        normalized.startsWith('/community/')) {
      _pushCommunity();
      return;
    }

    _pushNamed(normalized);
  }

  static void _pushReport(String? reportId) {
    if (reportId == null || reportId.isEmpty) return;
    _pushNamed(AppRoutes.reportDetail, arguments: reportId);
  }

  static void _pushCommunity() {
    _pushNamed(AppRoutes.community);
  }

  static void _pushNamed(String route, {Object? arguments}) {
    final navigator = appNavigatorKey.currentState;
    if (navigator == null) return;
    navigator.pushNamed(route, arguments: arguments);
  }
}
