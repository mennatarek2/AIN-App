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

double progressWithinCurrentTier(String badge, int trustPoints) {
  return switch (badge.trim().toLowerCase()) {
    'contributor' =>
      ((trustPoints - 20).clamp(0, 29) / 29).toDouble(),
    'trusted' => ((trustPoints - 50).clamp(0, 49) / 49).toDouble(),
    'guardian' => 1.0,
    _ => (trustPoints.clamp(0, 19) / 19).toDouble(),
  };
}

int pointsToNextBadge(String badge, int trustPoints) {
  return switch (badge.trim().toLowerCase()) {
    'contributor' => (50 - trustPoints).clamp(0, 50),
    'trusted' => (100 - trustPoints).clamp(0, 100),
    'guardian' => 0,
    _ => (20 - trustPoints).clamp(0, 20),
  };
}

class TrustBadgeChip extends StatelessWidget {
  const TrustBadgeChip({
    super.key,
    required this.badge,
    this.size = TrustBadgeSize.md,
  });

  final String badge;
  final TrustBadgeSize size;

  @override
  Widget build(BuildContext context) {
    final style = trustBadgeStyleFor(badge);
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
        style.label,
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
