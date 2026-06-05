import 'package:flutter/material.dart';

class ProfileModel {
  const ProfileModel({
    required this.id,
    required this.displayName,
    required this.email,
    required this.phoneNumber,
    required this.userName,
    this.isVerified = false,
    this.points = 0,
    this.profilePhotoUrl,
  });

  final String id;
  final String displayName;
  final String email;
  final String phoneNumber;
  final String userName;
  final bool isVerified;
  final int points;
  final String? profilePhotoUrl;

  // Calculate level dynamically based on points
  String get level {
    if (points < 100) return 'مستخدم جديد';
    if (points < 200) return 'مساهم';
    if (points < 300) return 'موثق';
    return 'متميز';
  }

  Color get levelDotColor {
    if (points < 100) return const Color(0xFF697184);
    if (points < 200) return const Color(0xFF498EF4);
    if (points < 300) return const Color(0xFF14B57A);
    return const Color(0xFFF59E0B);
  }

  int get pointsToNextLevel {
    if (points < 100) return 100 - points;
    if (points < 200) return 200 - points;
    if (points < 300) return 300 - points;
    return 0;
  }

  ProfileModel copyWith({
    String? id,
    String? displayName,
    String? email,
    String? phoneNumber,
    String? userName,
    bool? isVerified,
    int? points,
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
      points: points ?? this.points,
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
          points == other.points &&
          profilePhotoUrl == other.profilePhotoUrl;

  @override
  int get hashCode =>
      id.hashCode ^
      displayName.hashCode ^
      email.hashCode ^
      phoneNumber.hashCode ^
      userName.hashCode ^
      isVerified.hashCode ^
      points.hashCode ^
      profilePhotoUrl.hashCode;
}
