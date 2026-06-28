import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/notifications/notification_router.dart';
import '../../../../core/realtime/signalr_provider.dart';
import '../../../../core/realtime/signalr_state.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/app_layout_primitives.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../data/models/notification_model.dart';
import '../providers/notifications_provider.dart';
import '../utils/notification_type_ui.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(notificationsProvider);
      if (state.items.isEmpty && !state.isLoading && state.error == null) {
        ref.read(notificationsProvider.notifier).loadInitial();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      ref.read(notificationsProvider.notifier).loadMore();
    }
  }

  Future<void> _confirmClearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('مسح جميع الإشعارات'),
        content: const Text('هل أنت متأكد من حذف جميع الإشعارات؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('مسح الكل'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(notificationsProvider.notifier).clearAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationsProvider);
    final signalRStatus = ref.watch(signalRStatusProvider);

    final todayItems = state.itemsForSection(NotificationSection.today);
    final weekItems = state.itemsForSection(NotificationSection.thisWeek);
    final unread = state.unreadCount;

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
              if (state.items.isNotEmpty)
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: context.semantic.textOnPrimary,
                  ),
                  onSelected: (value) async {
                    final notifier = ref.read(notificationsProvider.notifier);
                    if (value == 'read_all') {
                      await notifier.markAllRead();
                    } else if (value == 'clear_all') {
                      await _confirmClearAll();
                    }
                  },
                  itemBuilder: (_) => [
                    if (unread > 0)
                      const PopupMenuItem(
                        value: 'read_all',
                        child: Text('قراءة الكل'),
                      ),
                    const PopupMenuItem(
                      value: 'clear_all',
                      child: Text('مسح الكل'),
                    ),
                  ],
                ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: context.semantic.textOnPrimary,
                  size: 20,
                ),
                tooltip: 'رجوع',
              ),
            ],
          ),

          Expanded(child: _buildBody(context, state, todayItems, weekItems)),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    NotificationsState state,
    List<NotificationModel> todayItems,
    List<NotificationModel> weekItems,
  ) {
    if (state.isLoading && state.items.isEmpty) {
      return const AppLoadingView(message: 'جاري تحميل الإشعارات...');
    }

    if (state.error != null && state.items.isEmpty) {
      return AppErrorView(
        message: state.error!,
        onRetry: () => ref.read(notificationsProvider.notifier).loadInitial(),
      );
    }

    if (state.items.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => ref.read(notificationsProvider.notifier).refresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            AppEmptyView(
              icon: Icons.notifications_none_rounded,
              title: 'لا توجد إشعارات',
              subtitle: 'ستظهر هنا الإشعارات الواردة من التطبيق',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(notificationsProvider.notifier).refresh(),
      child: ListView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
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
            ...todayItems.map((item) => _buildTile(item)),
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
            ...weekItems.map((item) => _buildTile(item)),
          ],
          if (state.isLoadingMore)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildTile(NotificationModel item) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        0,
        AppSpacing.screenHorizontal,
        AppSpacing.xs,
      ),
      child: Dismissible(
        key: ValueKey(item.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: AppSpacing.md),
          decoration: BoxDecoration(
            color: context.semantic.sos,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Icon(Icons.delete_outline, color: context.semantic.textOnPrimary),
        ),
        confirmDismiss: (_) async {
          await ref.read(notificationsProvider.notifier).deleteNotification(item.id);
          return true;
        },
        child: _NotificationTile(
          item: item,
          onTap: () => _onTap(item),
        ),
      ),
    );
  }

  void _onTap(NotificationModel item) {
    ref.read(notificationsProvider.notifier).markRead(item.id);
    NotificationRouter.goForModel(item);
  }
}

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
        : 'اتصال منقطع — التحديثات المتوقفة';

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

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.item,
    required this.onTap,
  });

  final NotificationModel item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isUnread = !item.isRead;
    final typeUi = NotificationTypeUi.forType(item.type);
    final typeColor = typeUi.resolveColor(
      critical: context.semantic.sos,
      primary: context.colors.primary,
      community: context.colors.secondary,
      account: context.semantic.warning,
      success: Colors.green.shade600,
      warning: context.semantic.warning,
      muted: context.semantic.textMuted,
    );

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
                      color: item.isCritical
                          ? context.semantic.sos
                          : context.colors.primary,
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
                          child: Icon(typeUi.icon, size: 20, color: typeColor),
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
                                  if (item.isCritical)
                                    Container(
                                      margin: const EdgeInsets.only(
                                        left: AppSpacing.xxs,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: context.semantic.sos,
                                        borderRadius: BorderRadius.circular(
                                          AppRadius.pill,
                                        ),
                                      ),
                                      child: Text(
                                        'حرج',
                                        style: context.text.labelSmall?.copyWith(
                                          color: context.semantic.textOnPrimary,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 9,
                                        ),
                                      ),
                                    ),
                                  Expanded(
                                    child: Text(
                                      item.title.isNotEmpty
                                          ? item.title
                                          : item.body,
                                      textDirection: TextDirection.rtl,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: context.text.bodyMedium?.copyWith(
                                        fontWeight: isUnread
                                            ? FontWeight.w700
                                            : FontWeight.w600,
                                        color: context.colors.onSurface,
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (item.title.isNotEmpty &&
                                  item.body.isNotEmpty) ...[
                                const SizedBox(height: AppSpacing.xxs),
                                Text(
                                  item.body,
                                  textDirection: TextDirection.rtl,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: context.text.bodySmall?.copyWith(
                                    color: context.semantic.textMuted,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                              const SizedBox(height: AppSpacing.xxs),
                              Text(
                                _formatDateTime(item.createdAt),
                                textDirection: TextDirection.rtl,
                                style: context.text.labelSmall?.copyWith(
                                  color: context.semantic.textMuted,
                                ),
                              ),
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

  String _formatDateTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} يوم';

    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day/$month ${dt.year} — $hour:$minute';
  }
}

class SignalRConnectionBanner extends ConsumerWidget {
  const SignalRConnectionBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(signalRStatusProvider);
    return _ConnectionBanner(status: status);
  }
}
