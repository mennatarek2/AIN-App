import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
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
  // Local selections — will be applied on "تطبيق"
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF0D1530) : Colors.white;
    final titleColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 16),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2A3A7C)
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Title row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  textDirection: TextDirection.rtl,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'تصفية البلاغات',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                      ),
                    ),
                    TextButton(
                      onPressed: _clearAll,
                      child: const Text(
                        'مسح الكل',
                        style: TextStyle(color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    // ---- Categories ----
                    _SectionLabel(
                      label: 'الفئات',
                      isDark: isDark,
                      titleColor: titleColor,
                    ),
                    const SizedBox(height: 10),
                    if (categories.isEmpty)
                      Center(
                        child: Text(
                          'جاري تحميل الفئات...',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
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
                                isDark: isDark,
                              ),
                            )
                            .toList(),
                      ),
                    const SizedBox(height: 24),
                    // ---- Status ----
                    _SectionLabel(
                      label: 'الحالة',
                      isDark: isDark,
                      titleColor: titleColor,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
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
                              isDark: isDark,
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
              // Apply button
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _applyFilter,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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
    // Only pass first selected category (API takes single categoryId)
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
  const _SectionLabel({
    required this.label,
    required this.isDark,
    required this.titleColor,
  });

  final String label;
  final bool isDark;
  final Color titleColor;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: titleColor,
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
    required this.isDark,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark
                    ? const Color(0xFF1A255C)
                    : const Color(0xFFF0F4FF)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark
                      ? const Color(0xFF2A3A8C)
                      : const Color(0xFFD6E4FF)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight:
                isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected
                ? Colors.white
                : (isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight),
          ),
        ),
      ),
    );
  }
}
