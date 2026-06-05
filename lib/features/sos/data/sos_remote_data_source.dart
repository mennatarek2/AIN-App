import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../domain/sos_alert_model.dart';

class SosRemoteDataSource {
  SosRemoteDataSource(this._client, {required this.readToken});

  final ApiClient _client;
  final Future<String?> Function() readToken;

  Future<void> trigger({
    required String communityId,
    required double latitude,
    required double longitude,
    required String severity,
    int? accuracyMeters,
    String? message,
    int? durationMinutes,
  }) async {
    final token = await readToken();
    await _client.postJson(
      ApiEndpoints.sosTrigger,
      token: token,
      body: {
        'communityId': communityId,
        'latitude': latitude,
        'longitude': longitude,
        'severity': severity,
        if (accuracyMeters != null) 'accuracyMeters': accuracyMeters,
        if (message != null && message.trim().isNotEmpty) 'message': message,
        if (durationMinutes != null) 'durationMinutes': durationMinutes,
      },
    );
  }

  Future<SosAlertModel?> fetchById(String id) async {
    final token = await readToken();
    final response = await _client.getJson(ApiEndpoints.sosById(id), token: token);
    final map = _extractMap(response);
    if (map == null) return null;
    return SosAlertModel.fromApiJson(map);
  }

  Future<List<SosAlertModel>> fetchNearby({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) async {
    final response = await _client.getJson(
      ApiEndpoints.sosNearby,
      query: {
        'latitude': latitude,
        'longitude': longitude,
        'radiusKm': radiusKm,
      },
    );

    final list = _extractList(response);
    if (list == null) return const [];
    return list
        .whereType<Map>()
        .map((item) => SosAlertModel.fromApiJson(Map<String, dynamic>.from(item)))
        .where((item) => item.id.isNotEmpty)
        .toList();
  }

  List<dynamic>? _extractList(dynamic payload) {
    if (payload is List) return payload;
    if (payload is Map) {
      final candidate = payload['data'] ?? payload['items'] ?? payload['result'];
      if (candidate is List) return candidate;
      for (final value in payload.values) {
        final nested = _extractList(value);
        if (nested != null) return nested;
      }
    }
    return null;
  }

  Map<String, dynamic>? _extractMap(dynamic payload) {
    if (payload is Map) {
      if (payload.containsKey('id')) return Map<String, dynamic>.from(payload);
      final candidate = payload['data'] ?? payload['result'];
      if (candidate is Map) return Map<String, dynamic>.from(candidate);
      for (final value in payload.values) {
        final nested = _extractMap(value);
        if (nested != null) return nested;
      }
    }
    return null;
  }
}
