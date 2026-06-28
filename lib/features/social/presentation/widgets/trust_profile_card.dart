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

  bool get _isOwnProfile => userId == 'me';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trustAsync = _isOwnProfile
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
          final style = trustBadgeStyleFor(trust.tierName);
          final showScore = trust.score != null;
          final score = trust.score ?? 0;
          final progress = trustTierProgress(trust.score);
          final toNext = pointsToNextTier(trust.score);
          final isMax = trust.isMaxTier;
          final nextTier = nextTierLabelAr(trust.score);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                textDirection: TextDirection.rtl,
                children: [
                  TrustBadgeChip(
                    badge: trust.tierName,
                    labelAr: trust.tierNameAr,
                    size: TrustBadgeSize.lg,
                  ),
                  if (showScore) ...[
                    const Spacer(),
                    Text(
                      '$score نقطة',
                      textDirection: TextDirection.rtl,
                      style: context.text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ],
              ),
              if (showScore) ...[
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
                      ? 'أعلى مستوى 🏆'
                      : '$toNext نقطة إلى $nextTier',
                  textDirection: TextDirection.rtl,
                  style: context.text.bodySmall?.copyWith(
                    color: context.semantic.textMuted,
                  ),
                ),
              ],
              if (_isOwnProfile &&
                  (trust.totalReports != null ||
                      trust.resolvedReports != null ||
                      trust.totalLikesReceived != null)) ...[
                const SizedBox(height: AppSpacing.md),
                Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    if (trust.totalReports != null)
                      Expanded(
                        child: _StatMini(
                          label: 'البلاغات',
                          value: trust.totalReports!,
                        ),
                      ),
                    if (trust.resolvedReports != null)
                      Expanded(
                        child: _StatMini(
                          label: 'تم الحل',
                          value: trust.resolvedReports!,
                        ),
                      ),
                    if (trust.totalLikesReceived != null)
                      Expanded(
                        child: _StatMini(
                          label: 'الإعجابات',
                          value: trust.totalLikesReceived!,
                        ),
                      ),
                  ],
                ),
              ],
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
