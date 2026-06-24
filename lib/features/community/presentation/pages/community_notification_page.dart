import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../notifications/presentation/providers/notifications_provider.dart';

/// Community-scoped view of SOS notifications (from the app notifications store).
class CommunityNotificationPage extends ConsumerWidget {
  const CommunityNotificationPage({
    super.key,
    required this.communityId,
    required this.communityName,
  });

  final String communityId;
  final String communityName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref
        .watch(notificationsProvider)
        .items
        .where((item) => item.type == NotificationType.sos)
        .toList();

    return Scaffold(
      backgroundColor: context.colors.surface,
      body: Column(
        children: [
          AppPageHeader(
            title: 'تنبيهات $communityName',
            subtitle: '${items.length} تنبيه',
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xxl),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.notifications_none_rounded,
                            size: 48,
                            color: context.semantic.textMuted
                                .withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'لا توجد تنبيهات SOS بعد',
                            textDirection: TextDirection.rtl,
                            style: context.text.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            'ستظهر هنا تنبيهات الطوارئ الواردة عبر SignalR',
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.center,
                            style: context.text.bodySmall?.copyWith(
                              color: context.semantic.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenHorizontal,
                      AppSpacing.lg,
                      AppSpacing.screenHorizontal,
                      AppSpacing.xl,
                    ),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _NotificationCard(item: item);
                    },
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemCount: items.length,
                  ),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item});

  final NotificationItem item;

  @override
  Widget build(BuildContext context) {
    final color =
        item.highlighted ? context.semantic.sos : context.colors.onSurface;

    return AppSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        textDirection: TextDirection.rtl,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(Icons.crisis_alert_rounded, color: color, size: 22),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.text,
                  textDirection: TextDirection.rtl,
                  style: context.text.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                if (!item.isRead) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    'غير مقروء',
                    textDirection: TextDirection.rtl,
                    style: context.text.labelSmall?.copyWith(
                      color: context.semantic.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
