import 'package:flutter/material.dart';

import 'app_semantic_colors.dart';

/// Convenient access to semantic design tokens from any [BuildContext].
extension AppThemeContext on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  AppSemanticColors get semantic {
    final extension = Theme.of(this).extension<AppSemanticColors>();
    return extension ??
        (isDarkMode ? AppSemanticColors.dark : AppSemanticColors.light);
  }

  LinearGradient get headerGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [semantic.headerGradientStart, semantic.headerGradientEnd],
  );

  LinearGradient get heroGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [semantic.heroGradientStart, semantic.heroGradientEnd],
  );

  LinearGradient get primaryGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [colors.primary, colors.secondary],
  );

  BoxShadow get cardShadow => BoxShadow(
    color: semantic.shadow,
    blurRadius: 8,
    offset: const Offset(0, 2),
  );

  List<BoxShadow> get cardShadows => [cardShadow];
}
