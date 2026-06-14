import 'package:flutter/material.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? const Color(0xFF1A2455) : const Color(0xFFE8EDF2);
    final highlight =
        isDark ? const Color(0xFF232D60) : const Color(0xFFF2F5F8);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final shimmerColor =
            Color.lerp(base, highlight, _animation.value) ?? base;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0D1530) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar + name row
              Row(
                children: [
                  _Bone(width: 30, height: 30, color: shimmerColor, circle: true),
                  const SizedBox(width: 10),
                  _Bone(width: 100, height: 12, color: shimmerColor),
                  const Spacer(),
                  _Bone(width: 60, height: 10, color: shimmerColor),
                ],
              ),
              const SizedBox(height: 12),
              // Title
              _Bone(width: double.infinity, height: 14, color: shimmerColor),
              const SizedBox(height: 6),
              _Bone(width: 200, height: 12, color: shimmerColor),
              const SizedBox(height: 14),
              // Image placeholder
              _Bone(
                width: double.infinity,
                height: 160,
                color: shimmerColor,
                radius: 12,
              ),
              const SizedBox(height: 14),
              // Tag row
              Row(
                children: [
                  _Bone(width: 70, height: 24, color: shimmerColor, radius: 12),
                  const SizedBox(width: 8),
                  _Bone(width: 80, height: 24, color: shimmerColor, radius: 12),
                  const SizedBox(width: 8),
                  _Bone(width: 60, height: 24, color: shimmerColor, radius: 12),
                ],
              ),
              const SizedBox(height: 12),
              Divider(
                height: 1,
                color: isDark
                    ? const Color(0xFF1E2D6B)
                    : const Color(0xFFE5E7EB),
              ),
              const SizedBox(height: 12),
              // Action row
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
