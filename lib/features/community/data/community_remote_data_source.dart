import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../models/community_detail.dart';
import '../models/community_search_result.dart';
import '../models/enums/community_enums.dart';
import '../models/join_request.dart';
import '../models/member_detail.dart';

// ─── SOS History ─────────────────────────────────────────────────────────────

class SosHistoryItem {
  const SosHistoryItem({
    required this.id,
    required this.severity,
    required this.status,
    this.message,
    this.resolvedBy,
    this.triggeredAt,
  });

  final String id;
  final String severity;
  final String status;
  final String? message;
  final String? resolvedBy;
  final DateTime? triggeredAt;

  factory SosHistoryItem.fromApiJson(Map<String, dynamic> json) {
    return SosHistoryItem(
      id: json['id']?.toString() ?? '',
      severity: json['severity']?.toString() ?? 'Standard',
      status: json['status']?.toString() ?? 'Resolved',
      message: json['message']?.toString(),
      resolvedBy: json['resolvedBy']?.toString(),
      triggeredAt: json['triggeredAt'] != null
          ? DateTime.tryParse(json['triggeredAt'].toString())
          : null,
    );
  }
}

// ─── Location ─────────────────────────────────────────────────────────────────

class LocationDto {
  const LocationDto({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  factory LocationDto.fromJson(Map<String, dynamic> json) => LocationDto(
        latitude: _toDouble(json['latitude']),
        longitude: _toDouble(json['longitude']),
      );

  static double _toDouble(dynamic v) {
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}

// ─── UserDetailsDto ───────────────────────────────────────────────────────────

class UserDetailsDto {
  const UserDetailsDto({
    required this.usrId,
    required this.userName,
    required this.role,
    this.userLocation,
    required this.lastLocationUpdatedAt,
    this.memberStatus = MemberStatus.locationPending,
  });

  final String usrId;
  final String userName;
  final String role;
  final LocationDto? userLocation;
  final DateTime lastLocationUpdatedAt;
  final MemberStatus memberStatus;

  bool get hasLocation => userLocation != null;

  factory UserDetailsDto.fromJson(Map<String, dynamic> json) => UserDetailsDto(
        usrId: json['usrId']?.toString() ?? '',
        userName: json['userName']?.toString() ?? '',
        role: json['role']?.toString() ?? 'Member',
        userLocation: json['userLocation'] != null
            ? LocationDto.fromJson(
                Map<String, dynamic>.from(json['userLocation'] as Map))
            : null,
        lastLocationUpdatedAt:
            DateTime.tryParse(json['lastLocationUpdatedAt']?.toString() ?? '') ??
                DateTime(1),
        memberStatus: memberStatusFromJson(json['memberStatus']),
      );
}

// ─── Create Community Response ────────────────────────────────────────────────

class CreateCommunityResponseDto {
  const CreateCommunityResponseDto({
    required this.id,
    required this.name,
    this.description,
    required this.communityType,
    this.coverageRadiusMeters,
    required this.createdById,
    required this.userName,
    required this.createdAt,
    this.inviteCode,
    this.inviteCodeExpiresAt,
    required this.userDetails,
  });

  final String id;
  final String name;
  final String? description;
  final int communityType;
  final int? coverageRadiusMeters;
  final String createdById;
  final String userName;
  final DateTime createdAt;
  final String? inviteCode;
  final DateTime? inviteCodeExpiresAt;
  final UserDetailsDto userDetails;

  bool get isLocationPending =>
      userDetails.userLocation == null ||
      userDetails.memberStatus == MemberStatus.locationPending;

  factory CreateCommunityResponseDto.fromJson(Map<String, dynamic> json) =>
      CreateCommunityResponseDto(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        description: json['description']?.toString(),
        communityType: _toInt(json['communityType']),
        coverageRadiusMeters: json['coverageRadiusMeters'] != null
            ? _toInt(json['coverageRadiusMeters'])
            : null,
        createdById: json['createdById']?.toString() ?? '',
        userName: json['userName']?.toString() ?? '',
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
            DateTime.now(),
        inviteCode: json['inviteCode']?.toString(),
        inviteCodeExpiresAt: json['inviteCodeExpiresAt'] != null
            ? DateTime.tryParse(json['inviteCodeExpiresAt'].toString())
            : null,
        userDetails: json['userDetails'] != null
            ? UserDetailsDto.fromJson(
                Map<String, dynamic>.from(json['userDetails'] as Map))
            : UserDetailsDto(
                usrId: '',
                userName: '',
                role: 'Member',
                lastLocationUpdatedAt: DateTime(1),
              ),
      );

  static int _toInt(dynamic v) {
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }
}

// ─── Join Result ──────────────────────────────────────────────────────────────

class CommunityJoinResultDto {
  const CommunityJoinResultDto({
    required this.communityId,
    required this.communityName,
    required this.memberStatus,
    required this.message,
    required this.requiresLocation,
  });

  final String communityId;
  final String communityName;
  final String memberStatus;
  final String message;
  final bool requiresLocation;

  bool get isLocationPending => memberStatus == 'LocationPending';

  factory CommunityJoinResultDto.fromJson(Map<String, dynamic> json) =>
      CommunityJoinResultDto(
        communityId: json['communityId']?.toString() ?? '',
        communityName: json['communityName']?.toString() ?? '',
        memberStatus: json['memberStatus']?.toString() ?? 'LocationPending',
        message: json['message']?.toString() ?? '',
        requiresLocation: json['requiresLocation'] == true,
      );
}

// ─── Regenerate Code Result ───────────────────────────────────────────────────

class RegenerateCodeResultDto {
  const RegenerateCodeResultDto({
    required this.communityId,
    required this.inviteCode,
    this.inviteCodeExpiresAt,
  });

  final String communityId;
  final String inviteCode;
  final DateTime? inviteCodeExpiresAt;

  factory RegenerateCodeResultDto.fromJson(Map<String, dynamic> json) =>
      RegenerateCodeResultDto(
        communityId: json['communityId']?.toString() ?? '',
        inviteCode: json['newInviteCode']?.toString() ??
            json['inviteCode']?.toString() ??
            '',
        inviteCodeExpiresAt: json['inviteCodeExpiresAt'] != null
            ? DateTime.tryParse(json['inviteCodeExpiresAt'].toString())
            : null,
      );
}

// ─── Nearby Community ─────────────────────────────────────────────────────────

class NearbyCommunityDto {
  const NearbyCommunityDto({
    required this.id,
    required this.name,
    required this.communityType,
    this.coverageRadiusMeters,
    required this.distanceMeters,
    required this.memberCount,
  });

  final String id;
  final String name;
  final int communityType;
  final int? coverageRadiusMeters;
  final double distanceMeters;
  final int memberCount;

  bool get isNearby => distanceMeters < 1000;

  factory NearbyCommunityDto.fromJson(Map<String, dynamic> json) =>
      NearbyCommunityDto(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        communityType: _toInt(json['communityType']),
        coverageRadiusMeters: json['coverageRadiusMeters'] != null
            ? _toInt(json['coverageRadiusMeters'])
            : null,
        distanceMeters: _toDouble(json['distanceMeters']),
        memberCount: _toInt(json['memberCount']),
      );

  static int _toInt(dynamic v) {
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }

  static double _toDouble(dynamic v) {
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}

// ─── Legacy Community & Member models (used by existing UI) ──────────────────

class CommunityApiModel {
  const CommunityApiModel({
    required this.id,
    required this.name,
    this.description,
    this.inviteCode,
    this.members = const [],
  });

  final String id;
  final String name;
  final String? description;
  final String? inviteCode;
  final List<CommunityMemberApiModel> members;

  factory CommunityApiModel.fromApiJson(Map<String, dynamic> json) {
    return CommunityApiModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      inviteCode: json['inviteCode']?.toString(),
      members: _parseMembersFromJson(json),
    );
  }

  static List<CommunityMemberApiModel> _parseMembersFromJson(
    Map<String, dynamic> json,
  ) {
    final raw = json['members'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((m) =>
            CommunityMemberApiModel.fromApiJson(Map<String, dynamic>.from(m)))
        .toList();
  }
}

class CommunityMemberApiModel {
  const CommunityMemberApiModel({
    required this.id,
    required this.email,
    this.displayName,
    this.memberStatus = MemberStatus.locationPending,
    this.userLocation,
  });

  final String id;
  final String email;
  final String? displayName;
  final MemberStatus memberStatus;
  final LocationDto? userLocation;

  factory CommunityMemberApiModel.fromApiJson(Map<String, dynamic> json) {
    final id = json['usrId']?.toString() ??
        json['id']?.toString() ??
        json['userId']?.toString() ??
        '';
    final userName = json['userName']?.toString() ??
        json['displayName']?.toString() ??
        json['name']?.toString() ??
        '';
    final email = json['email']?.toString() ?? '';
    final location = json['userLocation'] != null
        ? LocationDto.fromJson(
            Map<String, dynamic>.from(json['userLocation'] as Map))
        : null;
    return CommunityMemberApiModel(
      id: id,
      email: email.isNotEmpty ? email : userName,
      displayName: userName.isNotEmpty ? userName : null,
      memberStatus: memberStatusFromJson(json['memberStatus']),
      userLocation: location,
    );
  }
}

// ─── Data Source ──────────────────────────────────────────────────────────────

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

  // ── Create community — returns full response with inviteCode ────────────────

  Future<CreateCommunityResponseDto> createCommunity({
    required String name,
    String? description,
    int communityType = 0,
    int? coverageRadiusMeters,
  }) async {
    final token = await _requiredToken();
    final body = <String, dynamic>{
      'name': name,
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
      'communityType': communityType,
      if (coverageRadiusMeters != null)
        'coverageRadiusMeters': coverageRadiusMeters,
    };
    final response = await _client.postJson(
      ApiEndpoints.community,
      token: token,
      body: body,
    );
    final map = _extractMap(response);
    if (map == null) throw Exception('Empty response from create community');
    return CreateCommunityResponseDto.fromJson(map);
  }

  // ── Get my communities ─────────────────────────────────────────────────────

  Future<List<CommunityApiModel>> fetchAllCommunities() async {
    final token = await _requiredToken();
    final response = await _client.getJson(ApiEndpoints.community, token: token);
    debugPrint('[Community] fetchAllCommunities response type: ${response.runtimeType}');

    final List<dynamic> rawList = _normalizeToList(response);
    if (rawList.isEmpty) return const [];

    return rawList
        .whereType<Map>()
        .map((item) =>
            CommunityApiModel.fromApiJson(Map<String, dynamic>.from(item)))
        .where((item) => item.id.isNotEmpty && item.name.isNotEmpty)
        .toList();
  }

  // ── Get community by ID ────────────────────────────────────────────────────

  Future<CommunityDetail?> fetchCommunityById(String communityId) async {
    final token = await _requiredToken();
    final response = await _client.getJson(
      ApiEndpoints.communityById(communityId),
      token: token,
    );
    final map = _extractMap(response);
    if (map == null) return null;
    return CommunityDetail.fromJson(map);
  }

  Future<void> updateCommunity({
    required String communityId,
    required String name,
    String? description,
    required CommunityType type,
    int? coverageRadiusMeters,
  }) async {
    final token = await _requiredToken();
    await _client.putJson(
      ApiEndpoints.communityById(communityId),
      token: token,
      body: {
        'name': name,
        'description': description,
        'communityType': type.value,
        if (coverageRadiusMeters != null)
          'coverageRadiusMeters': coverageRadiusMeters,
      },
    );
  }

  Future<void> archiveCommunity(String communityId) async {
    final token = await _requiredToken();
    await _client.deleteJson(
      ApiEndpoints.communityById(communityId),
      token: token,
    );
  }

  // ── Join by invite code ────────────────────────────────────────────────────

  Future<CommunityJoinResultDto> joinByInviteCode(String code) async {
    final token = await _requiredToken();
    final response = await _client.postJson(
      ApiEndpoints.communityJoinByCode,
      token: token,
      body: {'inviteCode': code.trim().toUpperCase()},
    );
    final map = _extractMap(response) ??
        (response is Map ? Map<String, dynamic>.from(response) : null);
    if (map == null) throw Exception('Invalid join response');
    return CommunityJoinResultDto.fromJson(map);
  }

  // ── Submit join request (Neighborhood only) ────────────────────────────────

  Future<CommunityJoinResultDto> requestToJoin(String communityId) async {
    final token = await _requiredToken();
    final response = await _client.postJson(
      ApiEndpoints.communityJoinRequest(communityId),
      token: token,
      body: {},
    );
    final map = _extractMap(response) ??
        (response is Map ? Map<String, dynamic>.from(response) : null);
    if (map == null) throw Exception('Invalid join-request response');
    return CommunityJoinResultDto.fromJson(map);
  }

  // ── Get community members (role-aware, server-filtered fields) ─────────────

  Future<List<MemberDetailDto>> getMembers(String communityId) async {
    final token = await _requiredToken();
    final response = await _client.getJson(
      ApiEndpoints.communityMembersList(communityId),
      token: token,
    );
    final list = _extractList(response);
    if (list == null) return const [];
    return list
        .whereType<Map>()
        .map((item) =>
            MemberDetailDto.fromJson(Map<String, dynamic>.from(item)))
        .where((item) => item.userId.isNotEmpty)
        .toList();
  }

  // ── Admin: pending join requests ───────────────────────────────────────────

  Future<List<JoinRequestDto>> getPendingRequests(String communityId) async {
    final token = await _requiredToken();
    final response = await _client.getJson(
      ApiEndpoints.communityJoinRequests(communityId),
      token: token,
    );
    final list = _extractList(response);
    if (list == null) return const [];
    return list
        .whereType<Map>()
        .map((item) =>
            JoinRequestDto.fromJson(Map<String, dynamic>.from(item)))
        .where((item) => item.userId.isNotEmpty)
        .toList();
  }

  Future<void> approveRequest(String communityId, String userId) async {
    final token = await _requiredToken();
    await _client.putEmpty(
      ApiEndpoints.communityJoinRequestApprove(communityId, userId),
      token: token,
    );
  }

  Future<void> rejectRequest(String communityId, String userId) async {
    final token = await _requiredToken();
    await _client.putEmpty(
      ApiEndpoints.communityJoinRequestReject(communityId, userId),
      token: token,
    );
  }

  // ── Admin: member management ───────────────────────────────────────────────

  Future<void> kickMember(String communityId, String userId) async {
    final token = await _requiredToken();
    await _client.deleteJson(
      ApiEndpoints.communityMemberById(communityId, userId),
      token: token,
    );
  }

  Future<void> changeMemberRole(
    String communityId,
    String userId,
    CommunityRole newRole,
  ) async {
    if (newRole == CommunityRole.owner) {
      throw ArgumentError('Use transferOwnership instead');
    }
    final token = await _requiredToken();
    await _client.putRaw(
      ApiEndpoints.communityMemberRole(communityId, userId),
      token: token,
      body: newRole.value,
    );
  }

  Future<void> transferOwnership(
    String communityId,
    String newOwnerUserId,
  ) async {
    final token = await _requiredToken();
    await _client.postRaw(
      ApiEndpoints.communityTransferOwnership(communityId),
      token: token,
      body: newOwnerUserId,
    );
  }

  // ── Regenerate invite code ─────────────────────────────────────────────────

  Future<RegenerateCodeResultDto> regenerateCode(String communityId) async {
    final token = await _requiredToken();
    final response = await _client.postJson(
      ApiEndpoints.communityRegenerateCode(communityId),
      token: token,
      body: {},
    );
    final map = _extractMap(response) ??
        (response is Map ? Map<String, dynamic>.from(response) : null);
    if (map == null) throw Exception('Invalid regenerate-code response');
    return RegenerateCodeResultDto.fromJson(map);
  }

  // ── Revoke invite code ─────────────────────────────────────────────────────

  Future<void> revokeCode(String communityId) async {
    final token = await _requiredToken();
    await _client.deleteJson(
      ApiEndpoints.communityRevokeCode(communityId),
      token: token,
    );
  }

  // ── Search / discover communities ──────────────────────────────────────────

  Future<List<CommunitySearchResult>> searchCommunities({
    String? nameQuery,
    int? type,
    double? radiusKm,
  }) async {
    final token = await _requiredToken();
    final query = <String, dynamic>{};
    if (nameQuery != null && nameQuery.trim().isNotEmpty) {
      query['nameQuery'] = nameQuery.trim();
    }
    if (type != null) query['type'] = type;
    if (radiusKm != null) query['radiusKm'] = radiusKm;

    final response = await _client.getJson(
      ApiEndpoints.communitySearch,
      token: token,
      query: query.isEmpty ? null : query,
    );
    final list = _extractList(response);
    if (list == null) return const [];
    return list
        .whereType<Map>()
        .map((item) =>
            CommunitySearchResult.fromJson(Map<String, dynamic>.from(item)))
        .where((item) => item.id.isNotEmpty)
        .toList();
  }

  // ── Discover nearby communities ────────────────────────────────────────────

  Future<List<NearbyCommunityDto>> fetchNearbyCommunities({
    required double lat,
    required double lng,
    double radiusKm = 2.0,
  }) async {
    final token = await _requiredToken();
    final response = await _client.getJson(
      ApiEndpoints.communityNearby,
      token: token,
      query: {'lat': lat, 'lng': lng, 'radiusKm': radiusKm},
    );
    final list = _extractList(response);
    if (list == null) return const [];
    return list
        .whereType<Map>()
        .map((item) =>
            NearbyCommunityDto.fromJson(Map<String, dynamic>.from(item)))
        .where((item) => item.id.isNotEmpty)
        .toList();
  }

  // ── Send location reminder ─────────────────────────────────────────────────

  Future<void> sendLocationReminder({
    required String communityId,
    required String memberId,
  }) async {
    final token = await _requiredToken();
    await _client.postJson(
      ApiEndpoints.communityRemindLocation(communityId, memberId),
      token: token,
      body: {},
    );
  }

  // ── Legacy: add member by email ────────────────────────────────────────────

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
        .map((item) =>
            CommunityMemberApiModel.fromApiJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<void> leaveCommunity(String communityId) async {
    final token = await _requiredToken();
    await _client.deleteJson(
      ApiEndpoints.communityLeave(communityId),
      token: token,
    );
  }

  Future<List<SosHistoryItem>> fetchSosHistory(String communityId) async {
    final token = await _requiredToken();
    final response = await _client.getJson(
      ApiEndpoints.sosCommunityHistory(communityId),
      token: token,
    );
    final list = _extractList(response);
    if (list == null) return const [];
    return list
        .whereType<Map>()
        .map((item) =>
            SosHistoryItem.fromApiJson(Map<String, dynamic>.from(item)))
        .where((item) => item.id.isNotEmpty)
        .toList();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  List<dynamic> _normalizeToList(dynamic payload) {
    if (payload is List) return payload;
    if (payload is Map) {
      for (final key in ['data', 'items', 'result', 'communities']) {
        if (payload[key] is List) return payload[key] as List;
      }
      if (payload.containsKey('id') || payload.containsKey('name')) {
        return [payload];
      }
      for (final value in payload.values) {
        if (value is List && value.isNotEmpty) return value;
      }
    }
    return const [];
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
      if (payload.containsKey('id') ||
          payload.containsKey('communityId') ||
          payload.containsKey('inviteCode')) {
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
