class UserTrust {
  const UserTrust({
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

  /// Backward-compatible alias for [score].
  int get trustPoints => score ?? 0;

  /// Backward-compatible alias for [tierName].
  String get badge => tierName;

  bool get isMaxTier => (score ?? 0) >= 100;

  UserTrust copyWith({
    String? userId,
    int? score,
    String? tierName,
    String? tierNameAr,
    int? totalReports,
    int? resolvedReports,
    int? rejectedReports,
    int? totalLikesReceived,
  }) {
    return UserTrust(
      userId: userId ?? this.userId,
      score: score ?? this.score,
      tierName: tierName ?? this.tierName,
      tierNameAr: tierNameAr ?? this.tierNameAr,
      totalReports: totalReports ?? this.totalReports,
      resolvedReports: resolvedReports ?? this.resolvedReports,
      rejectedReports: rejectedReports ?? this.rejectedReports,
      totalLikesReceived: totalLikesReceived ?? this.totalLikesReceived,
    );
  }
}
