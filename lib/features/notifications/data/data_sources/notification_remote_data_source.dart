import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/notification_model.dart';

class NotificationRemoteDataSource {
  NotificationRemoteDataSource(this._client, {required this.readToken});

  final ApiClient _client;
  final Future<String?> Function() readToken;

  Future<List<NotificationModel>> fetchNotifications({
    int page = 1,
    int pageSize = 20,
  }) async {
    final token = await readToken();
    if (token == null || token.trim().isEmpty) return const [];

    final response = await _client.getJson(
      ApiEndpoints.notifications,
      token: token,
      query: {'page': page, 'pageSize': pageSize},
    );

    return _parseNotificationList(response);
  }

  Future<int> fetchUnreadCount() async {
    final token = await readToken();
    if (token == null || token.trim().isEmpty) return 0;

    final response = await _client.getJson(
      ApiEndpoints.notificationsUnreadCount,
      token: token,
    );

    if (response is int) return response;
    if (response is num) return response.toInt();
    if (response is String) return int.tryParse(response) ?? 0;
    if (response is Map) {
      final count = response['count'] ?? response['unreadCount'];
      if (count is num) return count.toInt();
    }
    return 0;
  }

  Future<void> markAsRead(String id) async {
    final token = await readToken();
    if (token == null || token.trim().isEmpty) {
      throw Exception('Missing auth token');
    }

    await _client.patchEmpty(
      ApiEndpoints.notificationMarkRead(id),
      token: token,
    );
  }

  Future<void> markAllAsRead() async {
    final token = await readToken();
    if (token == null || token.trim().isEmpty) {
      throw Exception('Missing auth token');
    }

    await _client.patchEmpty(
      ApiEndpoints.notificationsReadAll,
      token: token,
    );
  }

  Future<void> delete(String id) async {
    final token = await readToken();
    if (token == null || token.trim().isEmpty) {
      throw Exception('Missing auth token');
    }

    await _client.deleteJson(
      ApiEndpoints.notificationDelete(id),
      token: token,
    );
  }

  Future<void> clearAll() async {
    final token = await readToken();
    if (token == null || token.trim().isEmpty) {
      throw Exception('Missing auth token');
    }

    await _client.deleteJson(
      ApiEndpoints.notificationsClearAll,
      token: token,
    );
  }

  Future<void> registerFcmToken({
    required String token,
    required String platform,
  }) async {
    final authToken = await readToken();
    if (authToken == null || authToken.trim().isEmpty) {
      throw Exception('Missing auth token');
    }

    await _client.postJson(
      ApiEndpoints.notificationsFcmToken,
      token: authToken,
      body: {'token': token, 'platform': platform},
    );
  }

  Future<void> revokeFcmToken({
    required String token,
    required String platform,
  }) async {
    final authToken = await readToken();
    if (authToken == null || authToken.trim().isEmpty) {
      throw Exception('Missing auth token');
    }

    await _client.deleteJson(
      ApiEndpoints.notificationsFcmToken,
      token: authToken,
      body: {'token': token, 'platform': platform},
    );
  }

  /// Backward-compatible aliases.
  Future<void> registerDeviceToken({
    required String token,
    required String platform,
  }) =>
      registerFcmToken(token: token, platform: platform);

  Future<void> deleteDeviceToken({required String token}) async {
    await revokeFcmToken(token: token, platform: 'android');
  }

  List<NotificationModel> _parseNotificationList(dynamic response) {
    final list = _extractList(response);
    if (list == null) return const [];

    return list
        .whereType<Map>()
        .map(
          (item) => NotificationModel.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .where((notification) => notification.id.isNotEmpty)
        .toList();
  }

  List<dynamic>? _extractList(dynamic payload) {
    if (payload is List) return payload;
    if (payload is Map) {
      final candidate =
          payload['data'] ?? payload['items'] ?? payload['result'];
      if (candidate is List) return candidate;

      for (final value in payload.values) {
        final nested = _extractList(value);
        if (nested != null) return nested;
      }
    }
    return null;
  }
}
