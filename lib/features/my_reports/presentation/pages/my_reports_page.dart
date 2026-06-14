import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // ── Header ──
          _Header(isDark: isDark),
          // ── Status filter chips ──
          _FilterChips(
            selected: s.filter,
            onSelected: (f) =>
                ref.read(myReportsProvider.notifier).setFilter(f),
            isDark: isDark,
          ),
          // ── Content ──
          Expanded(
            child: s.isLoading
                ? const Center(child: CircularProgressIndicator())
                : s.error != null
                    ? _ErrorState(
                        message: s.error!,
                        onRetry: () =>
                            ref.read(myReportsProvider.notifier).refresh(),
                      )
                    : s.reports.isEmpty
                        ? const _EmptyState()
                        : RefreshIndicator(
                            onRefresh: () =>
                                ref.read(myReportsProvider.notifier).refresh(),
                            child: ListView.separated(
                              controller: _scrollController,
                              padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                              itemCount:
                                  s.reports.length + (s.isLoadingMore ? 1 : 0),
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 10),
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
                                  isDark: isDark,
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ReportDetailPage(
                                        reportId: report.id,
                                      ),
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
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
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
          backgroundColor: success ? Colors.green : Colors.redAccent,
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
                  leading: Icon(opt.$3, color: AppColors.primary),
                  title: Text(opt.$2, textDirection: TextDirection.rtl),
                  trailing: report.visibility?.toLowerCase() ==
                          opt.$1.toLowerCase()
                      ? const Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    await ref
                        .read(myReportsProvider.notifier)
                        .updateVisibility(report.id, opt.$1);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('تم تحديث ظهور البلاغ'),
                        ),
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
// Header
// =============================================================================

class _Header extends StatelessWidget {
  const _Header({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 100,
      color: isDark ? const Color(0xFF121A5C) : AppColors.primarySoft,
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Back button
            Positioned(
              left: 12,
              bottom: 8,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    size: 22,
                  ),
                ),
              ),
            ),
            // Title
            Align(
              alignment: const Alignment(0, 0.32),
              child: Text(
                'البلاغات الخاصة بي',
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Filter chips
// =============================================================================

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.selected,
    required this.onSelected,
    required this.isDark,
  });

  final MyReportsFilter selected;
  final void Function(MyReportsFilter) onSelected;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        reverse: true, // RTL ordering
        children: MyReportsFilter.values.map((f) {
          final isSelected = f == selected;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(
                f.label,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected
                      ? Colors.white
                      : (isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight),
                ),
              ),
              selected: isSelected,
              onSelected: (_) => onSelected(f),
              selectedColor: AppColors.primary,
              backgroundColor: isDark
                  ? const Color(0xFF1A2070)
                  : const Color(0xFFF0F4FF),
              side: BorderSide(
                color: isSelected
                    ? AppColors.primary
                    : (isDark
                        ? const Color(0xFF2A3580)
                        : const Color(0xFFD1D9F0)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// =============================================================================
// Dismissible report card
// =============================================================================

class _DismissibleReportCard extends StatelessWidget {
  const _DismissibleReportCard({
    required this.report,
    required this.isDark,
    required this.onTap,
    required this.onDelete,
    required this.onVisibilityChange,
  });

  final ReportModel report;
  final bool isDark;
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
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28),
      ),
      child: GestureDetector(
        onLongPress: onVisibilityChange,
        child: _MyReportCard(
          report: report,
          isDark: isDark,
          onTap: onTap,
        ),
      ),
    );
  }
}

// =============================================================================
// Report card
// =============================================================================

class _MyReportCard extends StatelessWidget {
  const _MyReportCard({
    required this.report,
    required this.isDark,
    required this.onTap,
  });

  final ReportModel report;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor =
        isDark ? AppColors.textPrimaryDark : const Color(0x66415789);
    final titleColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final subColor =
        isDark ? AppColors.textSecondaryDark : const Color(0x80909090);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1),
          color: isDark ? const Color(0xFF0D1347) : Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Top row: title + status chip ──
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
              child: Row(
                textDirection: TextDirection.rtl,
                children: [
                  Expanded(
                    child: Text(
                      report.title,
                      textDirection: TextDirection.rtl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: titleColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusChip(
                    label: report.statusLabel,
                    color: report.statusColor,
                  ),
                ],
              ),
            ),
            // ── Category / subcategory ──
            if (report.categoryName != null || report.subCategoryName != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Icon(Icons.category_outlined, size: 13, color: subColor),
                    const SizedBox(width: 4),
                    Text(
                      [
                        if (report.categoryName != null) report.categoryName!,
                        if (report.subCategoryName != null)
                          report.subCategoryName!,
                      ].join(' / '),
                      textDirection: TextDirection.rtl,
                      style: TextStyle(fontSize: 12, color: subColor),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 6),
            // ── Location ──
            if (report.locationAddress != null &&
                report.locationAddress!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Icon(Icons.location_on_outlined, size: 13, color: subColor),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        report.locationAddress!,
                        textDirection: TextDirection.rtl,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: subColor),
                      ),
                    ),
                  ],
                ),
              ),
            // ── Progress stepper ──
            _StatusProgress(report: report),
            // ── Bottom row: timestamp + visibility + attachments ──
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: Row(
                textDirection: TextDirection.rtl,
                children: [
                  Icon(Icons.access_time_rounded, size: 13, color: subColor),
                  const SizedBox(width: 4),
                  Text(
                    report.submittedAgo,
                    style: TextStyle(fontSize: 11, color: subColor),
                  ),
                  const Spacer(),
                  if (report.visibility != null) ...[
                    Icon(_visibilityIcon(report.visibility!),
                        size: 13, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      _visibilityLabel(report.visibility!),
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.primary),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (report.attachments.isNotEmpty) ...[
                    Icon(Icons.attach_file_rounded,
                        size: 13, color: subColor),
                    const SizedBox(width: 2),
                    Text(
                      '${report.attachments.length}',
                      style: TextStyle(fontSize: 11, color: subColor),
                    ),
                  ],
                ],
              ),
            ),
          ],
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

// =============================================================================
// Status progress stepper
// =============================================================================

class _StatusProgress extends StatelessWidget {
  const _StatusProgress({required this.report});
  final ReportModel report;

  @override
  Widget build(BuildContext context) {
    final steps = ['قيد المراجعة', 'موزع', 'منتهي'];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Map progressIndex (0-3) to display index
    final progress = report.progressIndex.clamp(0, 3);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        textDirection: TextDirection.rtl,
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            // Connector line
            final stepIndex = (i + 1) ~/ 2;
            final isComplete = progress > stepIndex;
            return Expanded(
              child: Container(
                height: 2,
                color: isComplete
                    ? AppColors.primary
                    : (isDark
                        ? const Color(0xFF2A3580)
                        : const Color(0xFFD1D9F0)),
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
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isComplete || isCurrent
                      ? AppColors.primary
                      : (isDark
                          ? const Color(0xFF2A3580)
                          : const Color(0xFFD1D9F0)),
                  border: isCurrent
                      ? Border.all(color: AppColors.primary, width: 2)
                      : null,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                steps[stepIndex],
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontSize: 9,
                  color: isComplete || isCurrent
                      ? AppColors.primary
                      : (isDark
                          ? AppColors.textSecondaryDark
                          : const Color(0xFF9CA3AF)),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// =============================================================================
// Status chip
// =============================================================================

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 7, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Empty / Error states
// =============================================================================

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 80,
            color: isDark ? AppColors.textSecondaryDark : const Color(0xFFB8C4D9),
          ),
          const SizedBox(height: 16),
          const Text(
            'لم تقدم أي بلاغات بعد',
            textDirection: TextDirection.rtl,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'اضغط على زر "بلاغ" في الأسفل لتقديم بلاغك الأول.',
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.textSecondaryDark : const Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'فشل تحميل البلاغات',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('إعادة المحاولة', textDirection: TextDirection.rtl),
          ),
        ],
      ),
    );
  }
}
