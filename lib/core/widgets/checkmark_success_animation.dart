import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/theme_extensions.dart';

class CheckmarkSuccessAnimation extends StatefulWidget {
  const CheckmarkSuccessAnimation({
    super.key,
    this.size = 140,
    this.circleColor,
    this.checkColor,
  });

  final double size;
  final Color? circleColor;
  final Color? checkColor;

  @override
  State<CheckmarkSuccessAnimation> createState() =>
      _CheckmarkSuccessAnimationState();
}

class _CheckmarkSuccessAnimationState extends State<CheckmarkSuccessAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _circleProgress;
  late final Animation<double> _checkProgress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _circleProgress = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );

    _checkProgress = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 0.8, curve: Curves.easeInOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.colors.primary;
    final circleColor = widget.circleColor ?? accent;
    final checkColor = widget.checkColor ?? context.semantic.success;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _CheckmarkPainter(
              circleProgress: _circleProgress.value,
              checkProgress: _checkProgress.value,
              circleColor: circleColor,
              checkColor: checkColor,
            ),
          );
        },
      ),
    );
  }
}

class _CheckmarkPainter extends CustomPainter {
  _CheckmarkPainter({
    required this.circleProgress,
    required this.checkProgress,
    required this.circleColor,
    required this.checkColor,
  });

  final double circleProgress;
  final double checkProgress;
  final Color circleColor;
  final Color checkColor;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.shortestSide * 0.07;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) - (strokeWidth / 2);

    final circlePaint = Paint()
      ..color = circleColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * circleProgress,
      false,
      circlePaint,
    );

    final checkPaint = Paint()
      ..color = checkColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final p1 = Offset(size.width * 0.25, size.height * 0.50);
    final p2 = Offset(size.width * 0.44, size.height * 0.67);
    final p3 = Offset(size.width * 0.74, size.height * 0.35);

    final len1 = (p2 - p1).distance;
    final len2 = (p3 - p2).distance;
    final total = len1 + len2;
    final drawLen = total * checkProgress;

    final path = Path();
    if (drawLen <= len1) {
      final t = len1 == 0 ? 0.0 : drawLen / len1;
      final p = Offset.lerp(p1, p2, t) ?? p1;
      path.moveTo(p1.dx, p1.dy);
      path.lineTo(p.dx, p.dy);
    } else {
      final remaining = drawLen - len1;
      final t = len2 == 0 ? 0.0 : remaining / len2;
      final p = Offset.lerp(p2, p3, t) ?? p2;
      path.moveTo(p1.dx, p1.dy);
      path.lineTo(p2.dx, p2.dy);
      path.lineTo(p.dx, p.dy);
    }

    canvas.drawPath(path, checkPaint);
  }

  @override
  bool shouldRepaint(covariant _CheckmarkPainter oldDelegate) {
    return oldDelegate.circleProgress != circleProgress ||
        oldDelegate.checkProgress != checkProgress;
  }
}
