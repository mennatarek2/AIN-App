import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.username,
    required this.isVerified,
    required this.points,
    required this.pointsToNextLevel,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final String username;
  final bool isVerified;
  final int points;
  final int pointsToNextLevel;

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

  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? username,
    bool? isVerified,
    int? points,
    int? pointsToNextLevel,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      username: username ?? this.username,
      isVerified: isVerified ?? this.isVerified,
      points: points ?? this.points,
      pointsToNextLevel: pointsToNextLevel ?? this.pointsToNextLevel,
    );
  }
}

class ProfileNotifier extends StateNotifier<UserProfile> {
  ProfileNotifier()
    : super(
        UserProfile(
          id: 'user_1',
          name: 'Mohamed Tarek',
          email: 'user123@gmail.com',
          phone: '+201020939734',
          username: 'mohamed_tarek',
          isVerified: true,
          points: 50,
          pointsToNextLevel: _calculatePointsToNextLevel(50),
        ),
      );

  static int _calculatePointsToNextLevel(int points) {
    if (points < 100) return 100 - points;
    if (points < 200) return 200 - points;
    if (points < 300) return 300 - points;
    return 0; // Max level reached
  }

  void _updatePoints(int delta) {
    final newTotal = (state.points + delta).clamp(0, 999999);
    state = state.copyWith(
      points: newTotal,
      pointsToNextLevel: _calculatePointsToNextLevel(newTotal),
    );
  }

  void updateName(String name) {
    state = state.copyWith(name: name);
  }

  void updateEmail(String email) {
    state = state.copyWith(email: email);
  }

  void updatePhone(String phone) {
    state = state.copyWith(phone: phone);
  }

  void updateUsername(String username) {
    state = state.copyWith(username: username);
  }

  void updatePassword(String oldPassword, String newPassword) {
    // Logic for password update (will be handled by auth service)
  }

  void addPoints(int points) {
    _updatePoints(points);
  }

  void losePoints(int points) {
    _updatePoints(-points);
  }

  void applyReportOutcome({required bool resolved}) {
    _updatePoints(resolved ? 10 : -10);
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, UserProfile>(
  (ref) => ProfileNotifier(),
);
