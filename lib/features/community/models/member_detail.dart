import '../../../core/enums/community_enums.dart';

class MemberDetailDto {
  final String userId;
  final String userName;
  final CommunityRole role;
  final JoinStatus joinStatus;
  final DateTime joinedAt;
  final MemberStatus? memberStatus;
  final String? email;
  final String? phoneNumber;
  final double? locationLatitude;
  final double? locationLongitude;
  final DateTime? lastLocationUpdatedAt;

  const MemberDetailDto({
    required this.userId,
    required this.userName,
    required this.role,
    required this.joinStatus,
    required this.joinedAt,
    this.memberStatus,
    this.email,
    this.phoneNumber,
    this.locationLatitude,
    this.locationLongitude,
    this.lastLocationUpdatedAt,
  });

  bool get isApproved => joinStatus == JoinStatus.approved;

  bool get hasLocation =>
      locationLatitude != null && locationLongitude != null;

  factory MemberDetailDto.fromJson(Map<String, dynamic> json) =>
      MemberDetailDto(
        userId: json['userId']?.toString() ?? '',
        userName: json['userName']?.toString() ?? '',
        role: communityRoleFromJson(json['communityRole'] ?? json['role']),
        joinStatus: joinStatusFromJson(json['joinStatus']),
        joinedAt: DateTime.tryParse(json['joinedAt']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        memberStatus: json['memberStatus'] != null
            ? memberStatusFromJson(json['memberStatus'])
            : null,
        email: json['email']?.toString(),
        phoneNumber: json['phoneNumber']?.toString(),
        locationLatitude: _toDoubleOrNull(json['locationLatitude']),
        locationLongitude: _toDoubleOrNull(json['locationLongitude']),
        lastLocationUpdatedAt: json['lastLocationUpdatedAt'] != null
            ? DateTime.tryParse(json['lastLocationUpdatedAt'].toString())
            : null,
      );

  static double? _toDoubleOrNull(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString());
  }
}
