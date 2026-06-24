import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/realtime/signalr_provider.dart';
import '../../../../core/realtime/signalr_state.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/app_layout_primitives.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../home/presentation/providers/home_navigation_provider.dart';
import '../../../home/presentation/widgets/bottom_nav_bar.dart';
import '../providers/notifications_provider.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    ref.read(homeNavigationProvider.notifier).setSelectedIndex(3);
  }

  @override
  Widget build(BuildContext context) {
    final notificationsState = ref.watch(notificationsProvider);
    final signalRStatus = ref.watch(signalRStatusProvider);

    final todayItems = notificationsState.itemsForSection(
      NotificationSection.today,
    );
    final weekItems = notificationsState.itemsForSection(
      NotificationSection.thisWeek,
    );
    final unread = notificationsState.unreadCount;

    return Scaffold(
      backgroundColor: context.colors.surface,
      body: Column(
        children: [
          _ConnectionBanner(status: signalRStatus),

          AppDashboardHeader(
            title: 'الإشعارات',
            subtitle: unread > 0 ? '$unread غير مقروء' : 'لا توجد إشعارات جديدة',
            compact: true,
            trailing: [
              if (unread > 0)
                TextButton(
                  onPressed: () =>
                      ref.read(notificationsProvider.notifier).markAllRead(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'قراءة الكل',
                    style: TextStyle(
                      fontSize: 13,
                      color: context.semantic.textOnPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              TextButton(
                onPressed: () =>
                    ref.read(notificationsProvider.notifier).clearAll(),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'مسح',
                  style: TextStyle(
                    fontSize: 13,
                    color: context.semantic.textOnPrimary.withValues(
                      alpha: 0.75,
                    ),
                  ),
                ),
              ),
            ],
          ),

          Expanded(
            child: notificationsState.items.isEmpty
                ? const AppEmptyView(
                    icon: Icons.notifications_none_rounded,
                    title: 'لا توجد إشعارات',
                  )
                : ListView(
                    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                    children: [
                      if (todayItems.isNotEmpty) ...[
                        AppSectionHeader(
                          title: 'اليوم',
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.screenHorizontal,
                            AppSpacing.md,
                            AppSpacing.screenHorizontal,
                            AppSpacing.xs,
                          ),
                        ),
                        ...todayItems.map(
                          (item) => Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.screenHorizontal,
                              0,
                              AppSpacing.screenHorizontal,
                              AppSpacing.xs,
                            ),
                            child: _NotificationTile(
                              item: item,
                              onTap: () => _onTap(item),
                            ),
                          ),
                        ),
                      ],
                      if (weekItems.isNotEmpty) ...[
                        AppSectionHeader(
                          title: 'هذا الأسبوع',
                          padding: EdgeInsets.fromLTRB(
                            AppSpacing.screenHorizontal,
                            todayItems.isNotEmpty ? AppSpacing.md : AppSpacing.sm,
                            AppSpacing.screenHorizontal,
                            AppSpacing.xs,
                          ),
                        ),
                        ...weekItems.map(
                          (item) => Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.screenHorizontal,
                              0,
                              AppSpacing.screenHorizontal,
                              AppSpacing.xs,
                            ),
                            child: _NotificationTile(
                              item: item,
                              onTap: () => _onTap(item),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: ref.watch(homeNavigationProvider),
        onTap: (index) {
          if (index == 3) return;
          ref.read(homeNavigationProvider.notifier).setSelectedIndex(index);
          navigateFromBottomNav(context, ref, index);
        },
      ),
    );
  }

  void _onTap(NotificationItem item) {
    ref.read(notificationsProvider.notifier).markRead(item.id);
    if (item.type == NotificationType.sos && item.relatedId != null) {
      Navigator.of(context).pushNamed('/sos');
    } else if (item.type == NotificationType.reportUpdate &&
        item.relatedId != null) {
      Navigator.of(context).pushNamed('/report', arguments: item.relatedId);
    }
  }
}

// ─── Connection banner ────────────────────────────────────────────────────────

class _ConnectionBanner extends StatelessWidget {
  const _ConnectionBanner({required this.status});

  final SignalRStatus status;

  @override
  Widget build(BuildContext context) {
    final isDisconnected =
        status == SignalRStatus.disconnected ||
        status == SignalRStatus.error ||
        status == SignalRStatus.reconnecting;

    if (!isDisconnected) return const SizedBox.shrink();

    final label = status == SignalRStatus.reconnecting
        ? 'جاري إعادة الاتصال...'
        : 'اتصال منقطع — التحديثات متوقفة';

    return Container(
      width: double.infinity,
      color: context.semantic.warning,
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.xxs,
        horizontal: AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 14,
            color: context.semantic.textOnPrimary,
          ),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            label,
            textDirection: TextDirection.rtl,
            style: context.text.labelSmall?.copyWith(
              color: context.semantic.textOnPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Notification tile ────────────────────────────────────────────────────────

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.item,
    required this.onTap,
  });

  final NotificationItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isUnread = !item.isRead;
    final (typeIcon, typeColor) = _typeInfo(context, item.type);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          decoration: BoxDecoration(
            color: isUnread
                ? context.colors.primary.withValues(alpha: 0.06)
                : context.semantic.surfaceContainer,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: isUnread
                  ? context.colors.primary.withValues(alpha: 0.25)
                  : context.semantic.borderSubtle,
            ),
            boxShadow: isUnread ? null : context.cardShadows,
          ),
          child: IntrinsicHeight(
            child: Row(
              textDirection: TextDirection.rtl,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isUnread)
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: context.colors.primary,
                      borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(AppRadius.lg),
                      ),
                    ),
                  ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Row(
                      textDirection: TextDirection.rtl,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: typeColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Icon(typeIcon, size: 20, color: typeColor),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                textDirection: TextDirection.rtl,
                                children: [
                                  if (isUnread)
                                    Container(
                                      margin: const EdgeInsets.only(
                                        left: AppSpacing.xxs,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: context.colors.primary,
                                        borderRadius: BorderRadius.circular(
                                          AppRadius.pill,
                                        ),
                                      ),
                                      child: Text(
                                        'جديد',
                                        style: context.text.labelSmall?.copyWith(
                                          color: context.semantic.textOnPrimary,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 9,
                                        ),
                                      ),
                                    ),
                                  Expanded(
                                    child: Text(
                                      item.text,
                                      textDirection: TextDirection.rtl,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: context.text.bodyMedium?.copyWith(
                                        fontWeight: isUnread
                                            ? FontWeight.w700
                                            : FontWeight.w400,
                                        color: context.colors.onSurface,
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (item.createdAt != null) ...[
                                const SizedBox(height: AppSpacing.xxs),
                                Text(
                                  _timeAgo(item.createdAt!),
                                  textDirection: TextDirection.rtl,
                                  style: context.text.labelSmall?.copyWith(
                                    color: context.semantic.textMuted,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  (IconData, Color) _typeInfo(BuildContext context, NotificationType type) {
    return switch (type) {
      NotificationType.sos => (
        Icons.crisis_alert_rounded,
        context.semantic.sos,
      ),
      NotificationType.reportUpdate => (
        Icons.description_rounded,
        context.colors.primary,
      ),
      NotificationType.system => (
        Icons.info_rounded,
        context.semantic.warning,
      ),
    };
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    return 'منذ ${diff.inDays} يوم';
  }
}

// ─── Reusable connection status banner (for other screens) ────────────────────

/// Can be placed at the top of any screen that needs the disconnection banner.
class SignalRConnectionBanner extends ConsumerWidget {
  const SignalRConnectionBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(signalRStatusProvider);
    return _ConnectionBanner(status: status);
  }
}
