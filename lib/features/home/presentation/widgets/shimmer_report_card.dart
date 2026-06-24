import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';

/// Skeleton shimmer card shown while the public feed is loading.
class ShimmerReportCard extends StatefulWidget {
  const ShimmerReportCard({super.key});

  @override
  State<ShimmerReportCard> createState() => _ShimmerReportCardState();
}

class _ShimmerReportCardState extends State<ShimmerReportCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final semantic = context.semantic;
    final base = semantic.shimmerBase;
    final highlight = semantic.shimmerHighlight;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final shimmerColor =
            Color.lerp(base, highlight, _animation.value) ?? base;

        return Container(
          margin: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
            vertical: AppSpacing.sm - 2,
          ),
          padding: const EdgeInsets.all(AppSpacing.sm + 2),
          decoration: BoxDecoration(
            color: semantic.surfaceContainer,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: context.cardShadows,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _Bone(width: 30, height: 30, color: shimmerColor, circle: true),
                  const SizedBox(width: AppSpacing.sm - 2),
                  _Bone(width: 100, height: 12, color: shimmerColor),
                  const Spacer(),
                  _Bone(width: 60, height: 10, color: shimmerColor),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              _Bone(width: double.infinity, height: 14, color: shimmerColor),
              const SizedBox(height: 6),
              _Bone(width: 200, height: 12, color: shimmerColor),
              const SizedBox(height: AppSpacing.sm + 2),
              _Bone(
                width: double.infinity,
                height: 160,
                color: shimmerColor,
                radius: AppRadius.md,
              ),
              const SizedBox(height: AppSpacing.sm + 2),
              Row(
                children: [
                  _Bone(
                    width: 70,
                    height: 24,
                    color: shimmerColor,
                    radius: AppRadius.md,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  _Bone(
                    width: 80,
                    height: 24,
                    color: shimmerColor,
                    radius: AppRadius.md,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  _Bone(
                    width: 60,
                    height: 24,
                    color: shimmerColor,
                    radius: AppRadius.md,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Divider(height: 1, color: semantic.divider),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _Bone(width: 60, height: 12, color: shimmerColor),
                  _Bone(width: 60, height: 12, color: shimmerColor),
                  _Bone(width: 60, height: 12, color: shimmerColor),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Bone extends StatelessWidget {
  const _Bone({
    required this.width,
    required this.height,
    required this.color,
    this.radius = 6,
    this.circle = false,
  });

  final double width;
  final double height;
  final Color color;
  final double radius;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(radius),
      ),
    );
  }
}
