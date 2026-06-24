import '../../domain/entities/user_trust.dart';

class UserTrustModel {
  const UserTrustModel({
    required this.userId,
    required this.displayName,
    required this.trustPoints,
    required this.badge,
    required this.totalReports,
    required this.resolvedReports,
    this.phoneNumber,
    this.email,
  });

  final String userId;
  final String displayName;
  final int trustPoints;
  final String badge;
  final int totalReports;
  final int resolvedReports;
  final String? phoneNumber;
  final String? email;

  factory UserTrustModel.fromJson(Map<String, dynamic> json) {
    final points = _parseInt(
      json['trustPoints'] ?? json['points'] ?? json['trust'] ?? 0,
    );
    final rawBadge = json['badge']?.toString();
    return UserTrustModel(
      userId:
          json['userId']?.toString() ??
          json['id']?.toString() ??
          '',
      displayName:
          json['displayName']?.toString() ??
          json['name']?.toString() ??
          json['userName']?.toString() ??
          '',
      trustPoints: points,
      badge: _normalizeBadge(rawBadge, points),
      totalReports: _parseInt(json['totalReports'] ?? json['total'] ?? 0),
      resolvedReports: _parseInt(
        json['resolvedReports'] ?? json['resolved'] ?? 0,
      ),
      phoneNumber: json['phoneNumber']?.toString(),
      email: json['email']?.toString(),
    );
  }

  UserTrust toEntity() => UserTrust(
    userId: userId,
    displayName: displayName,
    trustPoints: trustPoints,
    badge: badge,
    totalReports: totalReports,
    resolvedReports: resolvedReports,
    phoneNumber: phoneNumber,
    email: email,
  );

  static String _normalizeBadge(String? raw, int points) {
    if (raw != null && raw.trim().isNotEmpty) {
      return switch (raw.trim().toLowerCase()) {
        'guardian' => 'Guardian',
        'trusted' => 'Trusted',
        'contributor' => 'Contributor',
        'newcomer' => 'Newcomer',
        _ => raw.trim(),
      };
    }
    if (points >= 100) return 'Guardian';
    if (points >= 50) return 'Trusted';
    if (points >= 20) return 'Contributor';
    return 'Newcomer';
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
