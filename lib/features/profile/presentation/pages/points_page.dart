import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../providers/profile_provider.dart';

class PointsPage extends ConsumerWidget {
  const PointsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);

    final pts = profile?.points ?? 0;
    final badge = TrustBadge.fromString(profile?.badge);
    final progress = badge.progressFor(pts);
    final toNext = badge.pointsToNext(pts);
    final isMax = badge == TrustBadge.guardian;

    return Scaffold(
      backgroundColor: context.colors.surface,
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            children: [
              AppPageHeader(
                title: 'النقاط',
                onBack: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                ),
                decoration: BoxDecoration(
                  color: context.semantic.surfaceContainer,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: context.semantic.borderSubtle),
                  boxShadow: context.cardShadows,
                ),
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/points_level.png',
                      width: 186,
                      height: 186,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      textDirection: TextDirection.rtl,
                      children: [
                        Icon(
                          Icons.circle,
                          size: 12,
                          color: profile?.levelDotColor ?? badge.color,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          badge.label,
                          textDirection: TextDirection.rtl,
                          style: context.text.titleSmall?.copyWith(
                            color: context.colors.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      isMax
                          ? '🏆 أعلى مستوى — حارس\nاستمر في المشاركة'
                          : 'متبقي $toNext نقطة للمستوى التالي!\nاستمر في المشاركة',
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.center,
                      style: context.text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: context.colors.onSurface,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: LinearProgressIndicator(
                        minHeight: 16,
                        value: progress,
                        backgroundColor: context.semantic.chipBackground,
                        valueColor: AlwaysStoppedAnimation<Color>(badge.color),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'المستويات المحققة',
                    textDirection: TextDirection.rtl,
                    style: context.text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: context.colors.onSurface,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  children: [
                    _LevelItem(
                      label: TrustBadge.newcomer.label,
                      dotColor: TrustBadge.newcomer.color,
                      achieved: pts >= 0,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _LevelItem(
                      label: TrustBadge.contributor.label,
                      dotColor: TrustBadge.contributor.color,
                      achieved: pts >= 20,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _LevelItem(
                      label: TrustBadge.trusted.label,
                      dotColor: TrustBadge.trusted.color,
                      achieved: pts >= 50,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _LevelItem(
                      label: TrustBadge.guardian.label,
                      dotColor: TrustBadge.guardian.color,
                      achieved: pts >= 100,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelItem extends StatelessWidget {
  const _LevelItem({
    required this.label,
    required this.dotColor,
    required this.achieved,
  });

  final String label;
  final Color dotColor;
  final bool achieved;

  @override
  Widget build(BuildContext context) {
    final rowBackground = achieved
        ? context.semantic.infoContainer
        : context.semantic.chipBackground;

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: rowBackground,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        textDirection: TextDirection.ltr,
        children: [
          Icon(
            achieved
                ? Icons.check_circle_outline_rounded
                : Icons.lock_outline_rounded,
            size: 30,
            color: context.colors.primary,
          ),
          const Spacer(),
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Icon(Icons.circle, size: 16, color: dotColor),
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                textDirection: TextDirection.rtl,
                style: context.text.titleSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: context.colors.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
