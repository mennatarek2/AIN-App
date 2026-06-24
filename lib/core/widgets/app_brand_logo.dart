import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/theme_extensions.dart';

/// Splash-style brand mark used on splash, onboarding welcome, etc.
class AppBrandLogo extends StatelessWidget {
  const AppBrandLogo({
    super.key,
    this.compact = false,
    this.showTagline = false,
  });

  final bool compact;
  final bool showTagline;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 96.0 : 120.0;
    final titleSize = compact ? 28.0 : 32.0;
    final subtitleSize = compact ? 14.0 : 16.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: context.heroGradient,
            borderRadius: BorderRadius.circular(AppRadius.xxl),
            border: Border.all(
              color: context.colors.primary.withValues(alpha: 0.25),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: context.colors.primary.withValues(alpha: 0.25),
                blurRadius: compact ? 16 : 32,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'عَيْن',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.semantic.textOnPrimary,
                  fontSize: titleSize,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              Text(
                'Ai-N',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.semantic.textOnPrimary.withValues(alpha: 0.85),
                  fontSize: subtitleSize,
                  fontWeight: FontWeight.w500,
                  letterSpacing: compact ? 2 : 3,
                ),
              ),
            ],
          ),
        ),
        if (showTagline) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            'منصة البلاغات والمساعدة المجتمعية',
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: context.text.bodySmall?.copyWith(
              color: context.semantic.textMuted,
            ),
          ),
        ],
      ],
    );
  }
}
