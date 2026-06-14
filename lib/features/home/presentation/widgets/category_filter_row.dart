import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/categories_provider.dart';
import '../providers/home_feed_provider.dart';

/// Horizontally scrollable category filter chips.
class CategoryFilterRow extends ConsumerWidget {
  const CategoryFilterRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final feedAsync = ref.watch(publicFeedProvider);
    final selectedCategoryId = feedAsync.valueOrNull?.filter.categoryId;

    return SizedBox(
      height: 44,
      child: categoriesAsync.when(
        loading: () => const _ShimmerChipRow(),
        error: (e, s) => const SizedBox.shrink(),
        data: (categories) => ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            _CategoryChip(
              label: 'الكل',
              isSelected: selectedCategoryId == null,
              onTap: () {
                ref
                    .read(publicFeedProvider.notifier)
                    .applyFilter(
                      (feedAsync.valueOrNull?.filter ?? const FeedFilter())
                          .copyWith(categoryId: null),
                    );
              },
            ),
            ...categories.map(
              (cat) => _CategoryChip(
                label: cat.name,
                isSelected: selectedCategoryId == cat.id,
                onTap: () {
                  ref
                      .read(publicFeedProvider.notifier)
                      .applyFilter(
                        (feedAsync.valueOrNull?.filter ?? const FeedFilter())
                            .copyWith(categoryId: cat.id),
                      );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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

class _ShimmerChipRow extends StatelessWidget {
  const _ShimmerChipRow();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? const Color(0xFF1A255C) : const Color(0xFFE8EDF2);

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 5,
      itemBuilder: (_, i) => Container(
        margin: const EdgeInsets.only(left: 8),
        width: 70 + (i.isEven ? 20 : 0).toDouble(),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
