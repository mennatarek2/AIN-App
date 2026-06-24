import '../../../core/enums/community_enums.dart';

class JoinRequestDto {
  final String memberId;
  final String userId;
  final String userName;
  final String? profilePhotoUrl;
  final DateTime requestedAt;
  final JoinStatus status;

  const JoinRequestDto({
    required this.memberId,
    required this.userId,
    required this.userName,
    this.profilePhotoUrl,
    required this.requestedAt,
    required this.status,
  });

  factory JoinRequestDto.fromJson(Map<String, dynamic> json) => JoinRequestDto(
        memberId: json['memberId']?.toString() ?? '',
        userId: json['userId']?.toString() ?? '',
        userName: json['userName']?.toString() ?? '',
        profilePhotoUrl: json['profilePhotoUrl']?.toString(),
        requestedAt: DateTime.tryParse(json['requestedAt']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        status: joinStatusFromJson(json['status']),
      );
}
