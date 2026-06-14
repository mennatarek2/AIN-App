import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../domain/sos_alert_model.dart';
import 'sos_offline_queue.dart';

// ─── Live State DTO ───────────────────────────────────────────────────────────

class SosLiveStateDto {
  const SosLiveStateDto({
    required this.sosAlertId,
    required this.status,
    required this.severity,
    required this.communityId,
    required this.initiatorUserId,
    this.isInitiatorLocationStale = false,
    this.initiatorLastPingAt,
    this.secondsSinceLastPing = 0,
    this.latestLocation,
    this.recentLocations = const [],
    this.activeMemberCount = 0,
  });

  final String sosAlertId;
  final String status;
  final String severity;
  final String communityId;
  final String initiatorUserId;
  final bool isInitiatorLocationStale;
  final DateTime? initiatorLastPingAt;
  final int secondsSinceLastPing;
  final SosLocationDto? latestLocation;
  final List<SosLocationDto> recentLocations;
  final int activeMemberCount;

  factory SosLiveStateDto.fromJson(Map<String, dynamic> json) {
    return SosLiveStateDto(
      sosAlertId: json['sosAlertId']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Active',
      severity: json['severity']?.toString() ?? 'Medium',
      communityId: json['communityId']?.toString() ?? '',
      initiatorUserId: json['initiatorUserId']?.toString() ?? '',
      isInitiatorLocationStale: json['isInitiatorLocationStale'] == true,
      initiatorLastPingAt: json['initiatorLastPingAt'] != null
          ? DateTime.tryParse(json['initiatorLastPingAt'].toString())
          : null,
      secondsSinceLastPing: _toInt(json['secondsSinceLastPing']),
      latestLocation: json['latestLocation'] != null
          ? SosLocationDto.fromJson(
              Map<String, dynamic>.from(json['latestLocation'] as Map))
          : null,
      recentLocations: _parseLocations(json['recentLocations']),
      activeMemberCount: _toInt(json['activeMemberCount']),
    );
  }

  static int _toInt(dynamic v) {
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }

  static List<SosLocationDto> _parseLocations(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((m) => SosLocationDto.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }
}

class SosLocationDto {
  const SosLocationDto({
    required this.latitude,
    required this.longitude,
    this.accuracyMeters,
    this.altitudeMeters,
    this.recordedAtUtc,
  });

  final double latitude;
  final double longitude;
  final double? accuracyMeters;
  final double? altitudeMeters;
  final DateTime? recordedAtUtc;

  factory SosLocationDto.fromJson(Map<String, dynamic> json) => SosLocationDto(
        latitude: _toDouble(json['latitude']),
        longitude: _toDouble(json['longitude']),
        accuracyMeters: json['accuracyMeters'] != null
            ? _toDouble(json['accuracyMeters'])
            : null,
        altitudeMeters: json['altitudeMeters'] != null
            ? _toDouble(json['altitudeMeters'])
            : null,
        recordedAtUtc: json['recordedAtUtc'] != null
            ? DateTime.tryParse(json['recordedAtUtc'].toString())
            : null,
      );

  static double _toDouble(dynamic v) {
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}

// ─── SOS Remote Data Source ───────────────────────────────────────────────────

class SosRemoteDataSource {
  SosRemoteDataSource(this._client, {required this.readToken});

  final ApiClient _client;
  final Future<String?> Function() readToken;

  /// Exposed for offline queue flush
  ApiClient get apiClient => _client;

  /// Triggers a new SOS alert and returns the created model.
  Future<SosAlertModel?> trigger({
    required String communityId,
    required double latitude,
    required double longitude,
    required int severity,          // ← int, NOT String (API expects 0/1/2/3)
    double? accuracyMeters,
    double? altitudeMeters,
    String? message,
    int? durationMinutes,
  }) async {
    final token = await readToken();
    final response = await _client.postJson(
      ApiEndpoints.sosTrigger,
      token: token,
      body: {
        'communityId': communityId,
        'latitude': latitude,
        'longitude': longitude,
        'severity': severity,
        if (accuracyMeters != null) 'accuracyMeters': accuracyMeters,
        if (altitudeMeters != null) 'altitudeMeters': altitudeMeters,
        if (message != null && message.trim().isNotEmpty) 'message': message,
        if (durationMinutes != null) 'durationMinutes': durationMinutes,
      },
    );
    final map = _extractMap(response);
    if (map == null || map['id'] == null) return null;
    return SosAlertModel.fromApiJson(map);
  }

  /// Cancels an active SOS alert.
  Future<void> cancelAlert(String id) async {
    final token = await readToken();
    await _client.putJson(ApiEndpoints.sosCancel(id), token: token, body: {});
  }

  /// Resolves an active SOS alert.
  Future<void> resolveAlert(String id) async {
    final token = await readToken();
    await _client.putJson(ApiEndpoints.sosResolve(id), token: token, body: {});
  }

  /// Posts a single real-time location update (every 5s while active).
  Future<SosLocationDto?> updateLocation({
    required String id,
    required double latitude,
    required double longitude,
    double? accuracyMeters,
    double? altitudeMeters,
  }) async {
    final token = await readToken();
    final response = await _client.postJson(
      ApiEndpoints.sosLocationUpdate(id),
      token: token,
      body: {
        'latitude': latitude,
        'longitude': longitude,
        if (accuracyMeters != null) 'accuracyMeters': accuracyMeters,
        if (altitudeMeters != null) 'altitudeMeters': altitudeMeters,
      },
    );
    final map = _extractMap(response);
    if (map == null) return null;
    return SosLocationDto.fromJson(map);
  }

  /// Uploads all offline-queued pings in one batch request.
  Future<void> batchUploadLocations({
    required String id,
    required List<SosLocationItem> locations,
  }) async {
    if (locations.isEmpty) return;
    final token = await readToken();
    await _client.postJson(
      ApiEndpoints.sosBatchLocation(id),
      token: token,
      body: {'locations': locations.map((l) => l.toJson()).toList()},
    );
  }

  /// Fetches full live state snapshot — call on screen load or SignalR reconnect.
  Future<SosLiveStateDto?> getLiveState(String id) async {
    final token = await readToken();
    final response =
        await _client.getJson(ApiEndpoints.sosLiveState(id), token: token);
    final map = _extractMap(response);
    if (map == null) return null;
    return SosLiveStateDto.fromJson(map);
  }

  Future<SosAlertModel?> fetchById(String id) async {
    final token = await readToken();
    final response =
        await _client.getJson(ApiEndpoints.sosById(id), token: token);
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
      query: {'latitude': latitude, 'longitude': longitude, 'radiusKm': radiusKm},
    );
    final list = _extractList(response);
    if (list == null) return const [];
    return list
        .whereType<Map>()
        .map((item) =>
            SosAlertModel.fromApiJson(Map<String, dynamic>.from(item)))
        .where((item) => item.id.isNotEmpty)
        .toList();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

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
      if (payload.containsKey('id') || payload.containsKey('sosAlertId')) {
        return Map<String, dynamic>.from(payload);
      }
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
