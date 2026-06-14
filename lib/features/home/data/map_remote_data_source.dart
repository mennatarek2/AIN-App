import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../domain/report_map_pin.dart';

/// Fetches report map pins from `GET /api/Reports/map-data`.
/// Requires a Bearer token (citizen endpoint).
class MapRemoteDataSource {
  const MapRemoteDataSource(this._client, {required this.readToken});

  final ApiClient _client;
  final Future<String?> Function() readToken;

  Future<List<ReportMapPin>> fetchMapPins({
    String? categoryId,
    String? status,
  }) async {
    final token = await readToken();

    final query = <String, dynamic>{};
    if (categoryId != null && categoryId.isNotEmpty) {
      query['categoryId'] = categoryId;
    }
    if (status != null && status.isNotEmpty) {
      query['status'] = status;
    }

    final response = await _client.getJson(
      ApiEndpoints.reportsMapData,
      token: token,
      query: query.isEmpty ? null : query,
    );

    return _parseList(response);
  }

  List<ReportMapPin> _parseList(dynamic response) {
    List<dynamic>? list;

    if (response is List) {
      list = response;
    } else if (response is Map) {
      final candidate =
          response['data'] ?? response['items'] ?? response['result'];
      if (candidate is List) list = candidate;
    }

    if (list == null) return const [];

    return list
        .whereType<Map>()
        .map((item) => ReportMapPin.fromJson(Map<String, dynamic>.from(item)))
        .where((pin) => pin.id.isNotEmpty)
        .toList();
  }
}
