import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
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
      height: 48,
      child: categoriesAsync.when(
        loading: () => const _ShimmerChipRow(),
        error: (e, s) => const SizedBox.shrink(),
        data: (categories) => ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
          ),
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
    final semantic = context.semantic;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(left: AppSpacing.xs),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs + 2,
        ),
        decoration: BoxDecoration(
          gradient: isSelected ? context.primaryGradient : null,
          color: isSelected ? null : semantic.surfaceContainer,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : semantic.borderSubtle,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: context.colors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : context.cardShadows,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              Icon(
                Icons.check_rounded,
                size: 14,
                color: context.semantic.textOnPrimary,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? context.semantic.textOnPrimary
                    : semantic.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShimmerChipRow extends StatelessWidget {
  const _ShimmerChipRow();

  @override
  Widget build(BuildContext context) {
    final semantic = context.semantic;

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
      ),
      itemCount: 5,
      itemBuilder: (_, i) => Container(
        margin: const EdgeInsets.only(left: AppSpacing.xs),
        width: 70 + (i.isEven ? 20 : 0).toDouble(),
        height: 36,
        decoration: BoxDecoration(
          color: semantic.shimmerBase,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ),
    );
  }
}
