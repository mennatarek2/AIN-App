import 'package:flutter/material.dart';

class ProfileModel {
  const ProfileModel({
    required this.id,
    required this.displayName,
    required this.email,
    required this.phoneNumber,
    required this.userName,
    this.isVerified = false,
    this.trustPoints = 0,
    this.badge = 'Newcomer',
    this.profilePhotoUrl,
  });

  final String id;
  final String displayName;
  final String email;
  final String phoneNumber;
  final String userName;
  final bool isVerified;
  /// Raw trust points from API (trustPoints field)
  final int trustPoints;
  /// Badge string from API: 'Newcomer' | 'Contributor' | 'Trusted' | 'Guardian'
  final String badge;
  final String? profilePhotoUrl;

  // Keep legacy getters for backwards compatibility
  int get points => trustPoints;

  String get level {
    return switch (badge.toLowerCase()) {
      'guardian'    => 'حارس',
      'trusted'     => 'موثوق',
      'contributor' => 'مساهم',
      _             => 'مستخدم جديد',
    };
  }

  Color get levelDotColor {
    return switch (badge.toLowerCase()) {
      'guardian'    => const Color(0xFFF59E0B),
      'trusted'     => const Color(0xFF10B981),
      'contributor' => const Color(0xFF3B82F6),
      _             => const Color(0xFF697184),
    };
  }

  int get pointsToNextLevel {
    if (trustPoints < 20)  return 20 - trustPoints;
    if (trustPoints < 50)  return 50 - trustPoints;
    if (trustPoints < 100) return 100 - trustPoints;
    return 0;
  }

  ProfileModel copyWith({
    String? id,
    String? displayName,
    String? email,
    String? phoneNumber,
    String? userName,
    bool? isVerified,
    int? trustPoints,
    String? badge,
    String? profilePhotoUrl,
    bool clearPhoto = false,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      userName: userName ?? this.userName,
      isVerified: isVerified ?? this.isVerified,
      trustPoints: trustPoints ?? this.trustPoints,
      badge: badge ?? this.badge,
      profilePhotoUrl:
          clearPhoto ? null : (profilePhotoUrl ?? this.profilePhotoUrl),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProfileModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          displayName == other.displayName &&
          email == other.email &&
          phoneNumber == other.phoneNumber &&
          userName == other.userName &&
          isVerified == other.isVerified &&
          trustPoints == other.trustPoints &&
          badge == other.badge &&
          profilePhotoUrl == other.profilePhotoUrl;

  @override
  int get hashCode =>
      id.hashCode ^
      displayName.hashCode ^
      email.hashCode ^
      phoneNumber.hashCode ^
      userName.hashCode ^
      isVerified.hashCode ^
      trustPoints.hashCode ^
      badge.hashCode ^
      profilePhotoUrl.hashCode;
}
