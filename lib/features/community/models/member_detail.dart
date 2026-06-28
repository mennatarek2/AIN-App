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

  bool get hasLocation => locationLatitude != null && locationLongitude != null;

  factory MemberDetailDto.fromJson(Map<String, dynamic> json) {
    // The API returns location as a nested object:
    // { "userLocation": { "latitude": 30.29, "longitude": 31.72 } }
    // We extract lat/lng from that nested object.
    final locationMap = json['userLocation'] as Map?;
    final lat = locationMap != null
        ? _toDoubleOrNull(locationMap['latitude'])
        : _toDoubleOrNull(
            json['locationLatitude'],
          ); // fallback for legacy shape
    final lng = locationMap != null
        ? _toDoubleOrNull(locationMap['longitude'])
        : _toDoubleOrNull(
            json['locationLongitude'],
          ); // fallback for legacy shape

    // The API uses 'usrId' as the user ID field, but some endpoints use 'userId'.
    final userId = json['userId']?.toString().isNotEmpty == true
        ? json['userId'].toString()
        : json['usrId']?.toString() ?? '';

    // Role field: API may return 'role' or 'communityRole'.
    final roleRaw = json['communityRole'] ?? json['role'];

    // MemberStatus: API returns e.g. "LocationPending", "Active", or an int.
    // We default to locationPending when absent so the UI correctly reflects
    // that the member hasn't shared their location yet.
    final memberStatusRaw = json['memberStatus'];

    return MemberDetailDto(
      userId: userId,
      userName: json['userName']?.toString() ?? '',
      role: communityRoleFromJson(roleRaw),
      joinStatus: joinStatusFromJson(json['joinStatus']),
      joinedAt:
          DateTime.tryParse(json['joinedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      memberStatus: memberStatusRaw != null
          ? memberStatusFromJson(memberStatusRaw)
          : (lat != null && lng != null
                ? MemberStatus.active
                : MemberStatus.locationPending),
      email: json['email']?.toString(),
      phoneNumber: json['phoneNumber']?.toString(),
      locationLatitude: lat,
      locationLongitude: lng,
      lastLocationUpdatedAt: json['lastLocationUpdatedAt'] != null
          ? DateTime.tryParse(json['lastLocationUpdatedAt'].toString())
          : null,
    );
  }

  static double? _toDoubleOrNull(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString());
  }
}
