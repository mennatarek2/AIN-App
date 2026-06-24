import 'package:flutter/material.dart';

/// Brand palette — trust, safety, and civic professionalism.
/// Prefer [ColorScheme] and [AppSemanticColors] in widget code.
abstract final class AppColors {
  // ── Light foundations ─────────────────────────────────────────────────────
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceMutedLight = Color(0xFFF1F5F9);

  // ── Dark foundations ──────────────────────────────────────────────────────
  static const Color backgroundDark = Color(0xFF0B1220);
  static const Color surfaceDark = Color(0xFF111827);
  static const Color surfaceDarkElevated = Color(0xFF1F2937);
  static const Color surfaceDarkContainer = Color(0xFF162032);

  // ── Brand (trust blue-teal) ───────────────────────────────────────────────
  static const Color primary = Color(0xFF0B6E99);
  static const Color primarySoft = Color(0xFF38BDF8);
  static const Color primaryDark = Color(0xFF075985);
  static const Color primaryDeep = Color(0xFF164E63);

  // ── Text ──────────────────────────────────────────────────────────────────
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textPrimaryDark = Color(0xFFF1F5F9);
  static const Color textSecondaryLight = Color(0xFF475569);
  static const Color textSecondaryDark = Color(0xFF94A3B8);

  // ── Status ────────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF059669);
  static const Color warning = Color(0xFFD97706);
  static const Color error = Color(0xFFDC2626);
  static const Color sosRed = Color(0xFFEF4444);
}
