import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

enum TrustBadgeSize { sm, md, lg }

class TrustBadgeStyle {
  const TrustBadgeStyle({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final String icon;
  final Color color;
}

TrustBadgeStyle trustBadgeStyleFor(String badge) {
  return switch (badge.trim().toLowerCase()) {
    'contributor' => const TrustBadgeStyle(
      label: 'مساهم',
      icon: '⭐',
      color: AppColors.primarySoft,
    ),
    'trusted' => const TrustBadgeStyle(
      label: 'موثوق',
      icon: '🛡',
      color: AppColors.success,
    ),
    'guardian' => const TrustBadgeStyle(
      label: 'حارس',
      icon: '👑',
      color: Color(0xFFFFD700),
    ),
    _ => const TrustBadgeStyle(
      label: 'مبتدئ',
      icon: '🌱',
      color: Color(0xFF697184),
    ),
  };
}

/// Progress toward the next trust tier [0.0 – 1.0] per backend contract.
double trustTierProgress(int? score) {
  final s = score ?? 0;
  if (s >= 100) return 1.0;

  final (currentMin, nextThreshold) = switch (s) {
    >= 50 => (50, 100),
    >= 20 => (20, 50),
    _ => (0, 20),
  };

  return (s - currentMin) / (nextThreshold - currentMin);
}

/// Points remaining until the next tier threshold.
int pointsToNextTier(int? score) {
  final s = score ?? 0;
  if (s >= 100) return 0;

  final nextThreshold = switch (s) {
    >= 50 => 100,
    >= 20 => 50,
    _ => 20,
  };

  return nextThreshold - s;
}

/// Arabic label for the next tier (used below the progress bar).
String nextTierLabelAr(int? score) {
  final s = score ?? 0;
  if (s >= 100) return '';

  final nextEn = switch (s) {
    >= 50 => 'Guardian',
    >= 20 => 'Trusted',
    _ => 'Contributor',
  };

  return trustBadgeStyleFor(nextEn).label;
}

@Deprecated('Use trustTierProgress(score) instead')
double progressWithinCurrentTier(String badge, int trustPoints) =>
    trustTierProgress(trustPoints);

@Deprecated('Use pointsToNextTier(score) instead')
int pointsToNextBadge(String badge, int trustPoints) =>
    pointsToNextTier(trustPoints);

class TrustBadgeChip extends StatelessWidget {
  const TrustBadgeChip({
    super.key,
    required this.badge,
    this.labelAr,
    this.size = TrustBadgeSize.md,
  });

  final String badge;
  final String? labelAr;
  final TrustBadgeSize size;

  @override
  Widget build(BuildContext context) {
    final style = trustBadgeStyleFor(badge);
    final displayLabel = labelAr ?? style.label;
    final fontSize = switch (size) {
      TrustBadgeSize.sm => 11.0,
      TrustBadgeSize.md => 13.0,
      TrustBadgeSize.lg => 15.0,
    };
    final avatarRadius = switch (size) {
      TrustBadgeSize.sm => 12.0,
      TrustBadgeSize.md => 14.0,
      TrustBadgeSize.lg => 16.0,
    };

    return Chip(
      avatar: CircleAvatar(
        radius: avatarRadius,
        backgroundColor: style.color.withValues(alpha: 0.15),
        child: Text(style.icon, style: TextStyle(fontSize: fontSize)),
      ),
      label: Text(
        displayLabel,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: style.color,
        ),
      ),
      backgroundColor: style.color.withValues(alpha: 0.15),
      side: BorderSide(color: style.color.withValues(alpha: 0.25)),
      padding: EdgeInsets.symmetric(
        horizontal: size == TrustBadgeSize.lg ? 8 : 4,
        vertical: size == TrustBadgeSize.lg ? 4 : 0,
      ),
    );
  }
}
