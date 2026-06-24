import 'enums/community_enums.dart';

class CommunityDetail {
  const CommunityDetail({
    required this.id,
    required this.name,
    this.description,
    required this.communityType,
    this.coverageRadiusMeters,
    this.inviteCode,
    this.inviteCodeExpiresAt,
    required this.createdAt,
    required this.createdById,
    required this.createdByName,
    required this.isArchived,
    required this.activeMemberCount,
    required this.locationPendingCount,
    required this.inactiveMemberCount,
    required this.totalMemberCount,
    required this.sosReadinessPercent,
  });

  final String id;
  final String name;
  final String? description;
  final CommunityType communityType;
  final int? coverageRadiusMeters;
  final String? inviteCode;
  final DateTime? inviteCodeExpiresAt;
  final DateTime createdAt;
  final String createdById;
  final String createdByName;
  final bool isArchived;
  final int activeMemberCount;
  final int locationPendingCount;
  final int inactiveMemberCount;
  final int totalMemberCount;
  final int sosReadinessPercent;

  factory CommunityDetail.fromJson(Map<String, dynamic> json) {
    return CommunityDetail(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      communityType: CommunityType.fromInt(_toInt(json['communityType'])),
      coverageRadiusMeters: json['coverageRadiusMeters'] != null
          ? _toInt(json['coverageRadiusMeters'])
          : null,
      inviteCode: json['inviteCode']?.toString(),
      inviteCodeExpiresAt: json['inviteCodeExpiresAt'] != null
          ? DateTime.tryParse(json['inviteCodeExpiresAt'].toString())
          : null,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      createdById: json['createdById']?.toString() ?? '',
      createdByName: json['createdByName']?.toString() ?? '',
      isArchived: json['isArchived'] == true,
      activeMemberCount: _toInt(json['activeMemberCount']),
      locationPendingCount: _toInt(json['locationPendingCount']),
      inactiveMemberCount: _toInt(json['inactiveMemberCount']),
      totalMemberCount: _toInt(json['totalMemberCount']),
      sosReadinessPercent: _toInt(json['sosReadinessPercent']),
    );
  }

  static int _toInt(dynamic v) {
    if (v is int) return v;
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }
}
