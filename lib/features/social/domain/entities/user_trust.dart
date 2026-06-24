class UserTrust {
  const UserTrust({
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
  /// "Newcomer" | "Contributor" | "Trusted" | "Guardian"
  final String badge;
  final int totalReports;
  final int resolvedReports;
  final String? phoneNumber;
  final String? email;

  UserTrust copyWith({
    String? userId,
    String? displayName,
    int? trustPoints,
    String? badge,
    int? totalReports,
    int? resolvedReports,
    String? phoneNumber,
    String? email,
  }) {
    return UserTrust(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      trustPoints: trustPoints ?? this.trustPoints,
      badge: badge ?? this.badge,
      totalReports: totalReports ?? this.totalReports,
      resolvedReports: resolvedReports ?? this.resolvedReports,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
    );
  }
}
