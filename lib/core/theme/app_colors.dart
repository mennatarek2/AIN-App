import 'package:flutter/material.dart';

abstract final class AppColors {
  // Palette from design (light/dark shared)
  // #F3F6F9, #66C8FF, #0099FF, #060C3A, #004DFF
  static const Color backgroundLight = Color(0xFFF3F6F9);
  static const Color primary = Color(0xFF0099FF);
  static const Color primarySoft = Color(0xFF66C8FF);
  static const Color primaryDark = Color(0xFF004DFF);
  static const Color backgroundDark = Color(0xFF060C3A);

  static const Color textPrimaryLight = Color(0xFF060C3A);
  static const Color textPrimaryDark = Color(0xFFF3F6F9);

  static const Color textSecondaryLight = Color(0xFF4B5563);
  static const Color textSecondaryDark = Color(0xFFCBD5F5);
}

