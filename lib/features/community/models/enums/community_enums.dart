enum CommunityType {
  neighborhood(0, 'حي', 'قابل للاكتشاف من المستخدمين القريبين', 500),
  building(1, 'مبنى', 'بكود دعوة فقط', 100),
  privateGroup(2, 'مجموعة خاصة', 'بدون نطاق جغرافي', null);

  const CommunityType(
    this.value,
    this.labelAr,
    this.descriptionAr,
    this.defaultRadiusMeters,
  );

  final int value;
  final String labelAr;
  final String descriptionAr;
  final int? defaultRadiusMeters;

  bool get hasRadius => defaultRadiusMeters != null;

  static CommunityType fromInt(int v) => CommunityType.values.firstWhere(
        (t) => t.value == v,
        orElse: () => CommunityType.neighborhood,
      );

  static CommunityType fromValue(int value) => fromInt(value);
}

enum CommunityRole {
  member,
  moderator,
  admin,
  owner,
}

enum MemberStatus {
  active,
  locationPending,
  inactive,
}

enum JoinStatus {
  pending,
  approved,
  rejected,
  banned,
}

extension CommunityTypeX on CommunityType {
  String get displayName => switch (this) {
        CommunityType.neighborhood => 'Neighborhood',
        CommunityType.building => 'Building',
        CommunityType.privateGroup => 'Private Group',
      };
}

extension CommunityRoleX on CommunityRole {
  int get value => index;

  static CommunityRole fromInt(int v) {
    if (v < 0 || v >= CommunityRole.values.length) {
      return CommunityRole.member;
    }
    return CommunityRole.values[v];
  }

  static CommunityRole fromString(String v) => communityRoleFromString(v);

  bool get canManageMembers => index >= CommunityRole.admin.index;

  bool get isOwner => this == CommunityRole.owner;

  bool get canManageCodes => index >= CommunityRole.admin.index;
}

extension MemberStatusX on MemberStatus {
  static MemberStatus fromInt(int v) {
    if (v < 0 || v >= MemberStatus.values.length) {
      return MemberStatus.locationPending;
    }
    return MemberStatus.values[v];
  }

  static MemberStatus parse(String? raw) => switch ((raw ?? '').toLowerCase()) {
        'active' => MemberStatus.active,
        'locationpending' => MemberStatus.locationPending,
        'inactive' => MemberStatus.inactive,
        _ => MemberStatus.locationPending,
      };
}

extension JoinStatusX on JoinStatus {
  static JoinStatus fromInt(int v) {
    if (v < 0 || v >= JoinStatus.values.length) {
      return JoinStatus.pending;
    }
    return JoinStatus.values[v];
  }
}

JoinStatus joinStatusFromString(String v) => switch (v) {
      'Pending' => JoinStatus.pending,
      'Approved' => JoinStatus.approved,
      'Rejected' => JoinStatus.rejected,
      'Banned' => JoinStatus.banned,
      _ => JoinStatus.pending,
    };

JoinStatus joinStatusFromJson(dynamic v) {
  if (v is int) return JoinStatusX.fromInt(v);
  return joinStatusFromString(v.toString());
}

CommunityRole communityRoleFromString(String v) => switch (v) {
      'Owner' => CommunityRole.owner,
      'Admin' => CommunityRole.admin,
      'Moderator' => CommunityRole.moderator,
      _ => CommunityRole.member,
    };

CommunityRole communityRoleFromJson(dynamic v) {
  if (v is int) return CommunityRoleX.fromInt(v);
  return communityRoleFromString(v.toString());
}

MemberStatus memberStatusFromJson(dynamic v) {
  if (v is int) return MemberStatusX.fromInt(v);
  return MemberStatusX.parse(v?.toString());
}
