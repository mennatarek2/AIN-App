import '../../../core/enums/community_enums.dart';

class CommunitySearchResult {
  final String id;
  final String name;
  final String? description;
  final int communityType;
  final int memberCount;
  final int? coverageRadiusMeters;
  final bool acceptsJoinRequests;
  final bool hasActiveInviteCode;
  final bool isAlreadyMember;
  final JoinStatus? myJoinStatus;

  const CommunitySearchResult({
    required this.id,
    required this.name,
    this.description,
    required this.communityType,
    required this.memberCount,
    this.coverageRadiusMeters,
    required this.acceptsJoinRequests,
    required this.hasActiveInviteCode,
    required this.isAlreadyMember,
    this.myJoinStatus,
  });

  factory CommunitySearchResult.fromJson(Map<String, dynamic> json) =>
      CommunitySearchResult(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        description: json['description']?.toString(),
        communityType: _toInt(json['communityType']),
        memberCount: _toInt(json['memberCount']),
        coverageRadiusMeters: json['coverageRadiusMeters'] != null
            ? _toInt(json['coverageRadiusMeters'])
            : null,
        acceptsJoinRequests: json['acceptsJoinRequests'] == true,
        hasActiveInviteCode: json['hasActiveInviteCode'] == true,
        isAlreadyMember: json['isAlreadyMember'] == true,
        myJoinStatus: json['myJoinStatus'] != null
            ? joinStatusFromString(json['myJoinStatus'].toString())
            : null,
      );

  CommunitySearchResult copyWith({
    String? id,
    String? name,
    String? description,
    int? communityType,
    int? memberCount,
    int? coverageRadiusMeters,
    bool? acceptsJoinRequests,
    bool? hasActiveInviteCode,
    bool? isAlreadyMember,
    JoinStatus? myJoinStatus,
  }) =>
      CommunitySearchResult(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        communityType: communityType ?? this.communityType,
        memberCount: memberCount ?? this.memberCount,
        coverageRadiusMeters: coverageRadiusMeters ?? this.coverageRadiusMeters,
        acceptsJoinRequests: acceptsJoinRequests ?? this.acceptsJoinRequests,
        hasActiveInviteCode: hasActiveInviteCode ?? this.hasActiveInviteCode,
        isAlreadyMember: isAlreadyMember ?? this.isAlreadyMember,
        myJoinStatus: myJoinStatus ?? this.myJoinStatus,
      );

  static int _toInt(dynamic v) {
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }
}
