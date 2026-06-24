import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/app_layout_primitives.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../reports/domain/report_model.dart';
import '../../../reports/presentation/pages/report_detail_page.dart';
import '../providers/my_reports_provider.dart';

class MyReportsPage extends ConsumerStatefulWidget {
  const MyReportsPage({super.key});

  @override
  ConsumerState<MyReportsPage> createState() => _MyReportsPageState();
}

class _MyReportsPageState extends ConsumerState<MyReportsPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(myReportsProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(myReportsProvider);

    return Scaffold(
      backgroundColor: context.colors.surface,
      body: Column(
        children: [
          AppDashboardHeader(
            title: 'البلاغات الخاصة بي',
            subtitle: s.reports.isEmpty && !s.isLoading
                ? 'تابع حالة بلاغاتك من هنا'
                : '${s.reports.length} بلاغ',
            compact: true,
            trailing: [
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
            bottom: _SegmentedFilterTabs(
              selected: s.filter,
              onSelected: (f) =>
                  ref.read(myReportsProvider.notifier).setFilter(f),
            ),
          ),
          Expanded(
            child: s.isLoading
                ? const AppLoadingView()
                : s.error != null
                ? AppErrorView(
                    message: 'فشل تحميل البلاغات',
                    onRetry: () =>
                        ref.read(myReportsProvider.notifier).refresh(),
                  )
                : s.reports.isEmpty
                ? const AppEmptyView(
                    icon: Icons.assignment_outlined,
                    title: 'لم تقدم أي بلاغات بعد',
                    subtitle:
                        'اضغط على زر "بلاغ" في الأسفل لتقديم بلاغك الأول.',
                  )
                : RefreshIndicator(
                    onRefresh: () =>
                        ref.read(myReportsProvider.notifier).refresh(),
                    child: ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screenHorizontal,
                        AppSpacing.md,
                        AppSpacing.screenHorizontal,
                        AppSpacing.lg,
                      ),
                      itemCount: s.reports.length + (s.isLoadingMore ? 1 : 0),
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        if (index >= s.reports.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        final report = s.reports[index];
                        return _DismissibleReportCard(
                          report: report,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  ReportDetailPage(reportId: report.id),
                            ),
                          ),
                          onDelete: () => _confirmDelete(report),
                          onVisibilityChange: () =>
                              _showVisibilitySheet(report),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // Delete flow
  // ─────────────────────────────────────────────────────────────────

  Future<bool> _confirmDelete(ReportModel report) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'حذف البلاغ',
          textDirection: TextDirection.rtl,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'هل أنت متأكد من حذف هذا البلاغ؟ لا يمكن التراجع عن هذا الإجراء '
          'وسيؤدي إلى فقدان نقاط الثقة المكتسبة.',
          textDirection: TextDirection.rtl,
        ),
        actionsAlignment: MainAxisAlignment.end,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: context.semantic.error,
              foregroundColor: context.semantic.textOnPrimary,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed != true) return false;

    final success = await ref
        .read(myReportsProvider.notifier)
        .deleteReport(report.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'تم حذف البلاغ. سيتم خصم نقاط الثقة المكتسبة.'
                : 'فشل حذف البلاغ، يرجى المحاولة مرة أخرى.',
            textDirection: TextDirection.rtl,
          ),
          backgroundColor: success ? context.semantic.success : context.semantic.error,
        ),
      );
    }
    return success;
  }

  // ─────────────────────────────────────────────────────────────────
  // Visibility sheet
  // ─────────────────────────────────────────────────────────────────

  void _showVisibilitySheet(ReportModel report) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'تعديل ظهور البلاغ',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              for (final opt in [
                ('Public', 'عام', Icons.public),
                ('Confidential', 'سري', Icons.lock_outline),
                ('Anonymous', 'مجهول', Icons.person_off_outlined),
              ])
                ListTile(
                  leading: Icon(opt.$3, color: context.colors.primary),
                  title: Text(opt.$2, textDirection: TextDirection.rtl),
                  trailing:
                      report.visibility?.toLowerCase() == opt.$1.toLowerCase()
                      ? Icon(Icons.check, color: context.colors.primary)
                      : null,
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    await ref
                        .read(myReportsProvider.notifier)
                        .updateVisibility(report.id, opt.$1);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم تحديث ظهور البلاغ')),
                      );
                    }
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

// =============================================================================
// Segmented filter tabs
// =============================================================================

class _SegmentedFilterTabs extends StatelessWidget {
  const _SegmentedFilterTabs({
    required this.selected,
    required this.onSelected,
  });

  final MyReportsFilter selected;
  final void Function(MyReportsFilter) onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: context.semantic.textOnPrimary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: context.semantic.textOnPrimary.withValues(alpha: 0.2),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        reverse: true,
        child: Row(
          children: MyReportsFilter.values.map((f) {
            final isSelected = f == selected;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: GestureDetector(
                onTap: () => onSelected(f),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? context.semantic.textOnPrimary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: context.semantic.shadow,
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    f.label,
                    textDirection: TextDirection.rtl,
                    style: context.text.labelSmall?.copyWith(
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? context.colors.primary
                          : context.semantic.textOnPrimary.withValues(
                              alpha: 0.85,
                            ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _DismissibleReportCard extends StatelessWidget {
  const _DismissibleReportCard({
    required this.report,
    required this.onTap,
    required this.onDelete,
    required this.onVisibilityChange,
  });

  final ReportModel report;
  final VoidCallback onTap;
  final Future<bool> Function() onDelete;
  final VoidCallback onVisibilityChange;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(report.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: AppSpacing.lg),
        decoration: BoxDecoration(
          color: context.semantic.error,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Icon(
          Icons.delete_outline_rounded,
          color: context.semantic.textOnPrimary,
          size: 28,
        ),
      ),
      child: GestureDetector(
        onLongPress: onVisibilityChange,
        child: _MyReportCard(report: report, onTap: onTap),
      ),
    );
  }
}

class _MyReportCard extends StatelessWidget {
  const _MyReportCard({
    required this.report,
    required this.onTap,
  });

  final ReportModel report;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = report.statusColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: context.semantic.borderSubtle),
            color: context.semantic.surfaceContainer,
            boxShadow: context.cardShadows,
          ),
          clipBehavior: Clip.antiAlias,
          child: IntrinsicHeight(
            child: Row(
              textDirection: TextDirection.rtl,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 4,
                  color: statusColor,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          textDirection: TextDirection.rtl,
                          children: [
                            Expanded(
                              child: Text(
                                report.title,
                                textDirection: TextDirection.rtl,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: context.text.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: context.colors.onSurface,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            _StatusChip(
                              label: report.statusLabel,
                              color: statusColor,
                            ),
                          ],
                        ),
                        if (report.categoryName != null ||
                            report.subCategoryName != null) ...[
                          const SizedBox(height: AppSpacing.xxs),
                          _MetaChip(
                            icon: Icons.category_outlined,
                            label: [
                              if (report.categoryName != null)
                                report.categoryName!,
                              if (report.subCategoryName != null)
                                report.subCategoryName!,
                            ].join(' · '),
                          ),
                        ],
                        if (report.locationAddress != null &&
                            report.locationAddress!.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xxs),
                          _MetaChip(
                            icon: Icons.location_on_outlined,
                            label: report.locationAddress!,
                          ),
                        ],
                        const SizedBox(height: AppSpacing.xs),
                        _StatusProgress(report: report),
                        const SizedBox(height: AppSpacing.xxs),
                        Row(
                          textDirection: TextDirection.rtl,
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 13,
                              color: context.semantic.textMuted,
                            ),
                            const SizedBox(width: AppSpacing.xxs),
                            Text(
                              report.submittedAgo,
                              style: context.text.labelSmall?.copyWith(
                                color: context.semantic.textMuted,
                              ),
                            ),
                            const Spacer(),
                            if (report.visibility != null) ...[
                              Icon(
                                _visibilityIcon(report.visibility!),
                                size: 13,
                                color: context.colors.primary,
                              ),
                              const SizedBox(width: AppSpacing.xxs),
                              Text(
                                _visibilityLabel(report.visibility!),
                                style: context.text.labelSmall?.copyWith(
                                  color: context.colors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                            ],
                            if (report.attachments.isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.xxs,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: context.semantic.chipBackground,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.xs),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.attach_file_rounded,
                                      size: 12,
                                      color: context.semantic.textMuted,
                                    ),
                                    Text(
                                      '${report.attachments.length}',
                                      style: context.text.labelSmall?.copyWith(
                                        color: context.semantic.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            Icon(
                              Icons.chevron_left_rounded,
                              size: 18,
                              color: context.semantic.textMuted
                                  .withValues(alpha: 0.5),
                            ),
                          ],
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

  String _visibilityLabel(String v) {
    switch (v.toLowerCase()) {
      case 'public':
        return 'عام';
      case 'anonymous':
        return 'مجهول';
      case 'confidential':
        return 'سري';
      default:
        return v;
    }
  }

  IconData _visibilityIcon(String v) {
    switch (v.toLowerCase()) {
      case 'anonymous':
        return Icons.person_off_outlined;
      case 'confidential':
        return Icons.lock_outline;
      default:
        return Icons.public;
    }
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Icon(icon, size: 13, color: context.semantic.textMuted),
        const SizedBox(width: AppSpacing.xxs),
        Expanded(
          child: Text(
            label,
            textDirection: TextDirection.rtl,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.bodySmall?.copyWith(
              color: context.semantic.textMuted,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusProgress extends StatelessWidget {
  const _StatusProgress({required this.report});
  final ReportModel report;

  @override
  Widget build(BuildContext context) {
    final steps = ['قيد المراجعة', 'موزع', 'منتهي'];
    final progress = report.progressIndex.clamp(0, 3);
    final inactiveColor = context.semantic.borderSubtle;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: context.semantic.chipBackground,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            final stepIndex = (i + 1) ~/ 2;
            final isComplete = progress > stepIndex;
            return Expanded(
              child: Container(
                height: 2,
                color: isComplete ? context.colors.primary : inactiveColor,
              ),
            );
          }
          final stepIndex = i ~/ 2;
          final isComplete = progress > stepIndex;
          final isCurrent = progress == stepIndex;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: isCurrent ? 12 : 8,
                height: isCurrent ? 12 : 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isComplete || isCurrent
                      ? context.colors.primary
                      : inactiveColor,
                  border: isCurrent
                      ? Border.all(
                          color: context.colors.primary.withValues(alpha: 0.3),
                          width: 2,
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                steps[stepIndex],
                textDirection: TextDirection.rtl,
                style: context.text.labelSmall?.copyWith(
                  fontSize: 8,
                  color: isComplete || isCurrent
                      ? context.colors.primary
                      : context.semantic.textMuted,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
