import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/realtime/signalr_provider.dart';
import '../../../../core/realtime/signalr_state.dart';
import '../../../../core/theme/app_colors.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
      backgroundColor: isDark
          ? const Color(0xFF060C3A)
          : AppColors.backgroundLight,
      body: Column(
        children: [
          // ── Connection banner ─────────────────────────────────────────────
          _ConnectionBanner(status: signalRStatus),

          // ── Header ────────────────────────────────────────────────────────
          _Header(
            unread: unread,
            onMarkAll: () =>
                ref.read(notificationsProvider.notifier).markAllRead(),
            onClear: () =>
                ref.read(notificationsProvider.notifier).clearAll(),
          ),

          // ── List ──────────────────────────────────────────────────────────
          Expanded(
            child: notificationsState.items.isEmpty
                ? _EmptyState(isDark: isDark)
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    children: [
                      if (todayItems.isNotEmpty) ...[
                        _SectionTitle('اليوم', isDark: isDark),
                        const SizedBox(height: 8),
                        ...todayItems.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _NotificationTile(
                              item: item,
                              isDark: isDark,
                              onTap: () => _onTap(item),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                      if (weekItems.isNotEmpty) ...[
                        _SectionTitle('هذا الأسبوع', isDark: isDark),
                        const SizedBox(height: 8),
                        ...weekItems.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _NotificationTile(
                              item: item,
                              isDark: isDark,
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
          navigateFromBottomNav(context, index);
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
      Navigator.of(context).pushNamed(
        '/report',
        arguments: item.relatedId,
      );
    }
  }
}

// ─── Connection banner ────────────────────────────────────────────────────────

class _ConnectionBanner extends StatelessWidget {
  const _ConnectionBanner({required this.status});

  final SignalRStatus status;

  @override
  Widget build(BuildContext context) {
    final isDisconnected = status == SignalRStatus.disconnected ||
        status == SignalRStatus.error ||
        status == SignalRStatus.reconnecting;

    if (!isDisconnected) return const SizedBox.shrink();

    final label = status == SignalRStatus.reconnecting
        ? 'جاري إعادة الاتصال...'
        : 'اتصال منقطع — التحديثات متوقفة';

    return Container(
      width: double.infinity,
      color: const Color(0xFFF59E0B),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.warning_amber_rounded, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            textDirection: TextDirection.rtl,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.unread,
    required this.onMarkAll,
    required this.onClear,
  });

  final int unread;
  final VoidCallback onMarkAll;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark
        ? const Color(0xFFF3F6F9)
        : AppColors.textPrimaryLight;

    return Container(
      width: double.infinity,
      color: isDark ? const Color(0xFF121A5C) : AppColors.primarySoft,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 12,
        left: 12,
        right: 12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left actions
          Row(
            children: [
              TextButton(
                onPressed: onClear,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'مسح',
                  style: TextStyle(fontSize: 13, color: Color(0xFFEF4444)),
                ),
              ),
              if (unread > 0)
                TextButton(
                  onPressed: onMarkAll,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'قراءة الكل ($unread)',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
          // Title
          Text(
            'الإشعارات',
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w600,
              color: titleColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section title ────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, {required this.isDark});

  final String title;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        title,
        textDirection: TextDirection.rtl,
        style: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w400,
          color: isDark ? const Color(0xFFF3F6F9) : AppColors.textPrimaryLight,
        ),
      ),
    );
  }
}

// ─── Notification tile ────────────────────────────────────────────────────────

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.item,
    required this.isDark,
    required this.onTap,
  });

  final NotificationItem item;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isUnread = !item.isRead;
    final (typeIcon, typeColor) = _typeInfo(item.type);

    final bgColor = isUnread
        ? (isDark
              ? const Color(0x3366C8FF)
              : AppColors.primarySoft.withValues(alpha: 0.2))
        : (isDark ? const Color(0xFF060C3A) : Colors.white);

    final borderColor = isUnread
        ? Colors.transparent
        : (isDark ? const Color(0xFFF3F6F9) : const Color(0x66060C3A));

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Row(
          textDirection: TextDirection.rtl,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type icon
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(left: 10, top: 2),
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(typeIcon, size: 16, color: typeColor),
            ),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    item.text,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isUnread ? FontWeight.w600 : FontWeight.w400,
                      color: isDark
                          ? const Color(0xFFF3F6F9)
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  if (item.createdAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _timeAgo(item.createdAt!),
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Unread dot
            if (isUnread)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 6, top: 6),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  (IconData, Color) _typeInfo(NotificationType type) {
    return switch (type) {
      NotificationType.sos => (Icons.crisis_alert_rounded, const Color(0xFFEF4444)),
      NotificationType.reportUpdate => (Icons.description_rounded, AppColors.primary),
      NotificationType.system => (Icons.info_rounded, const Color(0xFFF59E0B)),
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

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 64,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
          const SizedBox(height: 12),
          Text(
            'لا توجد إشعارات',
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontSize: 16,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
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
