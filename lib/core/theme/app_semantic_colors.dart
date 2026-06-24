import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Semantic color tokens beyond Material [ColorScheme].
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.surfaceElevated,
    required this.surfaceContainer,
    required this.surfaceHeader,
    required this.surfaceNavBar,
    required this.surfaceInput,
    required this.borderSubtle,
    required this.borderStrong,
    required this.textMuted,
    required this.textOnPrimary,
    required this.headerGradientStart,
    required this.headerGradientEnd,
    required this.heroGradientStart,
    required this.heroGradientEnd,
    required this.success,
    required this.successContainer,
    required this.warning,
    required this.warningContainer,
    required this.error,
    required this.errorContainer,
    required this.info,
    required this.infoContainer,
    required this.sos,
    required this.sosContainer,
    required this.shadow,
    required this.overlay,
    required this.chipBackground,
    required this.divider,
    required this.shimmerBase,
    required this.shimmerHighlight,
    required this.mapOverlay,
  });

  final Color surfaceElevated;
  final Color surfaceContainer;
  final Color surfaceHeader;
  final Color surfaceNavBar;
  final Color surfaceInput;
  final Color borderSubtle;
  final Color borderStrong;
  final Color textMuted;
  final Color textOnPrimary;
  final Color headerGradientStart;
  final Color headerGradientEnd;
  final Color heroGradientStart;
  final Color heroGradientEnd;
  final Color success;
  final Color successContainer;
  final Color warning;
  final Color warningContainer;
  final Color error;
  final Color errorContainer;
  final Color info;
  final Color infoContainer;
  final Color sos;
  final Color sosContainer;
  final Color shadow;
  final Color overlay;
  final Color chipBackground;
  final Color divider;
  final Color shimmerBase;
  final Color shimmerHighlight;
  final Color mapOverlay;

  static const AppSemanticColors light = AppSemanticColors(
    surfaceElevated: AppColors.surfaceLight,
    surfaceContainer: AppColors.surfaceLight,
    surfaceHeader: AppColors.primaryDeep,
    surfaceNavBar: AppColors.surfaceLight,
    surfaceInput: AppColors.surfaceMutedLight,
    borderSubtle: Color(0xFFE2E8F0),
    borderStrong: Color(0xFFCBD5E1),
    textMuted: Color(0xFF64748B),
    textOnPrimary: Colors.white,
    headerGradientStart: AppColors.primaryDeep,
    headerGradientEnd: AppColors.primary,
    heroGradientStart: AppColors.primaryDeep,
    heroGradientEnd: AppColors.primary,
    success: AppColors.success,
    successContainer: Color(0xFFD1FAE5),
    warning: AppColors.warning,
    warningContainer: Color(0xFFFEF3C7),
    error: AppColors.error,
    errorContainer: Color(0xFFFEE2E2),
    info: AppColors.primary,
    infoContainer: Color(0xFFE0F2FE),
    sos: AppColors.sosRed,
    sosContainer: Color(0xFFFEE2E2),
    shadow: Color(0x120F172A),
    overlay: Color(0x660F172A),
    chipBackground: Color(0xFFF1F5F9),
    divider: Color(0xFFE2E8F0),
    shimmerBase: Color(0xFFE2E8F0),
    shimmerHighlight: Color(0xFFF8FAFC),
    mapOverlay: Color(0xCCFFFFFF),
  );

  static const AppSemanticColors dark = AppSemanticColors(
    surfaceElevated: AppColors.surfaceDarkElevated,
    surfaceContainer: AppColors.surfaceDarkContainer,
    surfaceHeader: AppColors.backgroundDark,
    surfaceNavBar: AppColors.surfaceDark,
    surfaceInput: AppColors.surfaceDarkElevated,
    borderSubtle: Color(0xFF1E293B),
    borderStrong: Color(0xFF334155),
    textMuted: Color(0xFF94A3B8),
    textOnPrimary: AppColors.textPrimaryDark,
    headerGradientStart: Color(0xFF0B1220),
    headerGradientEnd: AppColors.primaryDeep,
    heroGradientStart: Color(0xFF0B1220),
    heroGradientEnd: AppColors.primaryDeep,
    success: Color(0xFF34D399),
    successContainer: Color(0xFF064E3B),
    warning: Color(0xFFFBBF24),
    warningContainer: Color(0xFF78350F),
    error: Color(0xFFF87171),
    errorContainer: Color(0xFF7F1D1D),
    info: AppColors.primarySoft,
    infoContainer: Color(0xFF164E63),
    sos: Color(0xFFFCA5A5),
    sosContainer: Color(0xFF7F1D1D),
    shadow: Color(0x66000000),
    overlay: Color(0x99000000),
    chipBackground: Color(0xFF1E293B),
    divider: Color(0xFF1E293B),
    shimmerBase: Color(0xFF1E293B),
    shimmerHighlight: Color(0xFF334155),
    mapOverlay: Color(0xCC0B1220),
  );

  @override
  AppSemanticColors copyWith({
    Color? surfaceElevated,
    Color? surfaceContainer,
    Color? surfaceHeader,
    Color? surfaceNavBar,
    Color? surfaceInput,
    Color? borderSubtle,
    Color? borderStrong,
    Color? textMuted,
    Color? textOnPrimary,
    Color? headerGradientStart,
    Color? headerGradientEnd,
    Color? heroGradientStart,
    Color? heroGradientEnd,
    Color? success,
    Color? successContainer,
    Color? warning,
    Color? warningContainer,
    Color? error,
    Color? errorContainer,
    Color? info,
    Color? infoContainer,
    Color? sos,
    Color? sosContainer,
    Color? shadow,
    Color? overlay,
    Color? chipBackground,
    Color? divider,
    Color? shimmerBase,
    Color? shimmerHighlight,
    Color? mapOverlay,
  }) {
    return AppSemanticColors(
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      surfaceContainer: surfaceContainer ?? this.surfaceContainer,
      surfaceHeader: surfaceHeader ?? this.surfaceHeader,
      surfaceNavBar: surfaceNavBar ?? this.surfaceNavBar,
      surfaceInput: surfaceInput ?? this.surfaceInput,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      borderStrong: borderStrong ?? this.borderStrong,
      textMuted: textMuted ?? this.textMuted,
      textOnPrimary: textOnPrimary ?? this.textOnPrimary,
      headerGradientStart: headerGradientStart ?? this.headerGradientStart,
      headerGradientEnd: headerGradientEnd ?? this.headerGradientEnd,
      heroGradientStart: heroGradientStart ?? this.heroGradientStart,
      heroGradientEnd: heroGradientEnd ?? this.heroGradientEnd,
      success: success ?? this.success,
      successContainer: successContainer ?? this.successContainer,
      warning: warning ?? this.warning,
      warningContainer: warningContainer ?? this.warningContainer,
      error: error ?? this.error,
      errorContainer: errorContainer ?? this.errorContainer,
      info: info ?? this.info,
      infoContainer: infoContainer ?? this.infoContainer,
      sos: sos ?? this.sos,
      sosContainer: sosContainer ?? this.sosContainer,
      shadow: shadow ?? this.shadow,
      overlay: overlay ?? this.overlay,
      chipBackground: chipBackground ?? this.chipBackground,
      divider: divider ?? this.divider,
      shimmerBase: shimmerBase ?? this.shimmerBase,
      shimmerHighlight: shimmerHighlight ?? this.shimmerHighlight,
      mapOverlay: mapOverlay ?? this.mapOverlay,
    );
  }

  @override
  AppSemanticColors lerp(AppSemanticColors? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      surfaceElevated:
          Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      surfaceContainer:
          Color.lerp(surfaceContainer, other.surfaceContainer, t)!,
      surfaceHeader: Color.lerp(surfaceHeader, other.surfaceHeader, t)!,
      surfaceNavBar: Color.lerp(surfaceNavBar, other.surfaceNavBar, t)!,
      surfaceInput: Color.lerp(surfaceInput, other.surfaceInput, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textOnPrimary: Color.lerp(textOnPrimary, other.textOnPrimary, t)!,
      headerGradientStart:
          Color.lerp(headerGradientStart, other.headerGradientStart, t)!,
      headerGradientEnd:
          Color.lerp(headerGradientEnd, other.headerGradientEnd, t)!,
      heroGradientStart:
          Color.lerp(heroGradientStart, other.heroGradientStart, t)!,
      heroGradientEnd: Color.lerp(heroGradientEnd, other.heroGradientEnd, t)!,
      success: Color.lerp(success, other.success, t)!,
      successContainer:
          Color.lerp(successContainer, other.successContainer, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningContainer:
          Color.lerp(warningContainer, other.warningContainer, t)!,
      error: Color.lerp(error, other.error, t)!,
      errorContainer: Color.lerp(errorContainer, other.errorContainer, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
      sos: Color.lerp(sos, other.sos, t)!,
      sosContainer: Color.lerp(sosContainer, other.sosContainer, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      overlay: Color.lerp(overlay, other.overlay, t)!,
      chipBackground: Color.lerp(chipBackground, other.chipBackground, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      shimmerBase: Color.lerp(shimmerBase, other.shimmerBase, t)!,
      shimmerHighlight:
          Color.lerp(shimmerHighlight, other.shimmerHighlight, t)!,
      mapOverlay: Color.lerp(mapOverlay, other.mapOverlay, t)!,
    );
  }
}
