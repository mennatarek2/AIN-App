import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';

class CommunityApiModel {
  const CommunityApiModel({
    required this.id,
    required this.name,
    this.description,
    this.members = const [],
  });

  final String id;
  final String name;
  final String? description;
  final List<CommunityMemberApiModel> members;

  factory CommunityApiModel.fromApiJson(
    Map<String, dynamic> json, {
    List<CommunityMemberApiModel> members = const [],
  }) {
    return CommunityApiModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      members: members,
    );
  }
}

class CommunityMemberApiModel {
  const CommunityMemberApiModel({
    required this.id,
    required this.email,
    this.displayName,
  });

  final String id;
  final String email;
  final String? displayName;

  factory CommunityMemberApiModel.fromApiJson(Map<String, dynamic> json) {
    return CommunityMemberApiModel(
      id: json['id']?.toString() ?? json['userId']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? json['name']?.toString(),
    );
  }
}

class CommunityRemoteDataSource {
  CommunityRemoteDataSource(this._client, {required this.readToken});

  final ApiClient _client;
  final Future<String?> Function() readToken;

  Future<String> _requiredToken() async {
    final token = await readToken();
    if (token == null || token.trim().isEmpty) {
      throw Exception('Missing auth token');
    }
    return token;
  }

  Future<void> createCommunity({
    required String name,
    required String description,
  }) async {
    final token = await _requiredToken();
    await _client.postJson(
      ApiEndpoints.communities,
      token: token,
      body: {'name': name, 'description': description},
    );
  }

  Future<List<CommunityApiModel>> fetchAllCommunities() async {
    final token = await _requiredToken();
    final response = await _client.getJson(ApiEndpoints.communities, token: token);
    final list = _extractList(response);
    if (list == null) return const [];
    return list
        .whereType<Map>()
        .map((item) => CommunityApiModel.fromApiJson(Map<String, dynamic>.from(item)))
        .where((item) => item.id.isNotEmpty && item.name.isNotEmpty)
        .toList();
  }

  Future<CommunityApiModel?> fetchCommunityById(String communityId) async {
    final token = await _requiredToken();
    final response = await _client.getJson(
      ApiEndpoints.communityById(communityId),
      token: token,
    );
    final map = _extractMap(response);
    if (map == null) return null;
    return CommunityApiModel.fromApiJson(map);
  }

  Future<void> addMemberByEmail({
    required String communityId,
    required String email,
  }) async {
    final token = await _requiredToken();
    await _client.postJson(
      ApiEndpoints.communityMembers(communityId),
      token: token,
      body: {'email': email},
    );
  }

  Future<List<CommunityMemberApiModel>> fetchCommunityMembers(
    String communityId,
  ) async {
    final token = await _requiredToken();
    final response = await _client.getJson(
      ApiEndpoints.communityMembers(communityId),
      token: token,
    );
    final list = _extractList(response);
    if (list == null) return const [];
    return list
        .whereType<Map>()
        .map(
          (item) =>
              CommunityMemberApiModel.fromApiJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  Future<void> leaveCommunity(String communityId) async {
    final token = await _requiredToken();
    await _client.deleteJson(ApiEndpoints.communityLeave(communityId), token: token);
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
