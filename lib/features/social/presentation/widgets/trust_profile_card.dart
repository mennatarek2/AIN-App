import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../providers/social_providers.dart';
import 'trust_badge_chip.dart';

class TrustProfileCard extends ConsumerWidget {
  const TrustProfileCard({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trustAsync = userId == 'me'
        ? ref.watch(myTrustProvider)
        : ref.watch(userTrustProvider(userId));

    return AppSurfaceCard(
      child: trustAsync.when(
        loading: () => const SizedBox(
          height: 120,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (_, __) => Text(
          'تعذر تحميل بيانات الثقة',
          textDirection: TextDirection.rtl,
          style: TextStyle(color: context.semantic.textMuted),
        ),
        data: (trust) {
          final style = trustBadgeStyleFor(trust.badge);
          final progress = progressWithinCurrentTier(
            trust.badge,
            trust.trustPoints,
          );
          final toNext = pointsToNextBadge(trust.badge, trust.trustPoints);
          final isMax = trust.badge.toLowerCase() == 'guardian';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                textDirection: TextDirection.rtl,
                children: [
                  TrustBadgeChip(
                    badge: trust.badge,
                    size: TrustBadgeSize.lg,
                  ),
                  const Spacer(),
                  Text(
                    '${trust.trustPoints} نقطة',
                    style: context.text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  color: style.color,
                  backgroundColor: context.semantic.borderSubtle,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                isMax
                    ? '🏆 أعلى مستوى — حارس'
                    : '$toNext نقطة للمستوى التالي',
                textDirection: TextDirection.rtl,
                style: context.text.bodySmall?.copyWith(
                  color: context.semantic.textMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                textDirection: TextDirection.rtl,
                children: [
                  Expanded(
                    child: _StatMini(
                      label: 'البلاغات',
                      value: trust.totalReports,
                    ),
                  ),
                  Expanded(
                    child: _StatMini(
                      label: 'تم الحل',
                      value: trust.resolvedReports,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatMini extends StatelessWidget {
  const _StatMini({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$value',
          style: context.text.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          textDirection: TextDirection.rtl,
          style: context.text.bodySmall?.copyWith(
            color: context.semantic.textMuted,
          ),
        ),
      ],
    );
  }
}
