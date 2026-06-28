import '../../domain/entities/user_trust.dart';

class UserTrustModel {
  const UserTrustModel({
    required this.userId,
    this.score,
    required this.tierName,
    required this.tierNameAr,
    this.totalReports,
    this.resolvedReports,
    this.rejectedReports,
    this.totalLikesReceived,
  });

  final String userId;
  final int? score;
  final String tierName;
  final String tierNameAr;
  final int? totalReports;
  final int? resolvedReports;
  final int? rejectedReports;
  final int? totalLikesReceived;

  factory UserTrustModel.fromJson(Map<String, dynamic> json) {
    final rawScore = json['score'] ?? json['trustPoints'] ?? json['points'];
    final score = rawScore == null ? null : _parseInt(rawScore);

    final tierName = json['tierName']?.toString().trim();
    final tierNameAr = json['tierNameAr']?.toString().trim();

    return UserTrustModel(
      userId: json['userId']?.toString() ?? json['id']?.toString() ?? '',
      score: score,
      tierName: tierName?.isNotEmpty == true
          ? tierName!
          : _tierNameFromScore(score ?? 0),
      tierNameAr: tierNameAr?.isNotEmpty == true
          ? tierNameAr!
          : _tierNameArFromScore(score ?? 0),
      totalReports: _parseNullableInt(json['totalReports']),
      resolvedReports: _parseNullableInt(json['resolvedReports']),
      rejectedReports: _parseNullableInt(json['rejectedReports']),
      totalLikesReceived: _parseNullableInt(json['totalLikesReceived']),
    );
  }

  UserTrust toEntity() => UserTrust(
    userId: userId,
    score: score,
    tierName: tierName,
    tierNameAr: tierNameAr,
    totalReports: totalReports,
    resolvedReports: resolvedReports,
    rejectedReports: rejectedReports,
    totalLikesReceived: totalLikesReceived,
  );

  static String _tierNameFromScore(int score) {
    if (score >= 100) return 'Guardian';
    if (score >= 50) return 'Trusted';
    if (score >= 20) return 'Contributor';
    return 'Newcomer';
  }

  static String _tierNameArFromScore(int score) {
    if (score >= 100) return 'حارس';
    if (score >= 50) return 'موثوق';
    if (score >= 20) return 'مساهم';
    return 'مبتدئ';
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int? _parseNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString());
  }
}
