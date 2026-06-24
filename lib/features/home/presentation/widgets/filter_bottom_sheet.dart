import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../providers/categories_provider.dart';
import '../providers/home_feed_provider.dart';

/// Status options available in the public feed
const _statusOptions = [
  ('UnderReview', 'قيد المراجعة'),
  ('Dispatched', 'قيد المعالجة'),
  ('ReSolved', 'تم الحل'),
  ('Rejected', 'مرفوض'),
];

/// Shows a bottom sheet for filtering the public feed.
void showFilterBottomSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _FilterSheet(),
  );
}

class _FilterSheet extends ConsumerStatefulWidget {
  const _FilterSheet();

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  final Set<String> _selectedCategoryIds = {};
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    final current = ref.read(publicFeedProvider).valueOrNull?.filter;
    if (current?.categoryId != null) {
      _selectedCategoryIds.add(current!.categoryId!);
    }
    _selectedStatus = current?.status;
  }

  @override
  Widget build(BuildContext context) {
    final semantic = context.semantic;
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: semantic.surfaceContainer,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.xxl),
            ),
          ),
          child: Column(
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(
                    top: AppSpacing.sm,
                    bottom: AppSpacing.md,
                  ),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: semantic.borderStrong,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                ),
                child: Row(
                  textDirection: TextDirection.rtl,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'تصفية البلاغات',
                      style: context.text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: context.colors.onSurface,
                      ),
                    ),
                    TextButton(
                      onPressed: _clearAll,
                      child: Text(
                        'مسح الكل',
                        style: TextStyle(color: context.colors.primary),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  children: [
                    _SectionLabel(label: 'الفئات'),
                    const SizedBox(height: AppSpacing.sm - 2),
                    if (categories.isEmpty)
                      Center(
                        child: Text(
                          'جاري تحميل الفئات...',
                          style: TextStyle(color: semantic.textMuted),
                        ),
                      )
                    else
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        textDirection: TextDirection.rtl,
                        children: categories
                            .map(
                              (cat) => _FilterChip(
                                label: cat.name,
                                isSelected:
                                    _selectedCategoryIds.contains(cat.id),
                                onTap: () => setState(() {
                                  if (_selectedCategoryIds
                                      .contains(cat.id)) {
                                    _selectedCategoryIds.remove(cat.id);
                                  } else {
                                    _selectedCategoryIds.add(cat.id);
                                  }
                                }),
                              ),
                            )
                            .toList(),
                      ),
                    const SizedBox(height: AppSpacing.xl),
                    _SectionLabel(label: 'الحالة'),
                    const SizedBox(height: AppSpacing.sm - 2),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      textDirection: TextDirection.rtl,
                      children: _statusOptions
                          .map(
                            (s) => _FilterChip(
                              label: s.$2,
                              isSelected: _selectedStatus == s.$1,
                              onTap: () => setState(() {
                                _selectedStatus =
                                    _selectedStatus == s.$1 ? null : s.$1;
                              }),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.xl,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _applyFilter,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.colors.primary,
                      foregroundColor: context.semantic.textOnPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    child: const Text(
                      'تطبيق',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _clearAll() {
    setState(() {
      _selectedCategoryIds.clear();
      _selectedStatus = null;
    });
  }

  void _applyFilter() {
    final categoryId = _selectedCategoryIds.isEmpty
        ? null
        : _selectedCategoryIds.first;

    ref.read(publicFeedProvider.notifier).applyFilter(
          FeedFilter(
            categoryId: categoryId,
            status: _selectedStatus,
            search: ref.read(publicFeedProvider).valueOrNull?.filter.search,
          ),
        );

    Navigator.of(context).pop();
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: context.text.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: context.colors.onSurface,
      ),
      textDirection: TextDirection.rtl,
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semantic;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm + 2,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? context.colors.primary
              : semantic.chipBackground,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: isSelected
                ? context.colors.primary
                : semantic.borderSubtle,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected
                ? context.semantic.textOnPrimary
                : semantic.textMuted,
          ),
        ),
      ),
    );
  }
}
