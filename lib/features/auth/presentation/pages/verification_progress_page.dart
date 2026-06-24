import 'package:flutter/material.dart';
import 'dart:async';

import '../../../../config/routes/app_routes.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';

class VerificationProgressPage extends StatefulWidget {
  const VerificationProgressPage({super.key});

  @override
  State<VerificationProgressPage> createState() =>
      _VerificationProgressPageState();
}

class _VerificationProgressPageState extends State<VerificationProgressPage>
    with SingleTickerProviderStateMixin {
  Timer? _navigationTimer;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _navigationTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted) {
        return;
      }

      Navigator.of(context).pushReplacementNamed(AppRoutes.verificationSuccess);
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              _buildHero(context),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'جاري التحقق ...',
                        textAlign: TextAlign.center,
                        style: context.text.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'نقوم الآن بمراجعة بياناتك. تستغرق العملية ثوانٍ قليلة.\nيرجى الانتظار حتى اكتمال التحقق',
                        textAlign: TextAlign.center,
                        style: context.text.bodyMedium?.copyWith(
                          height: 1.5,
                          color: context.semantic.textMuted,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxxl),
                      const _VerificationLoadingBar(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xxxl,
        AppSpacing.xl,
        AppSpacing.huge,
      ),
      decoration: BoxDecoration(
        gradient: context.headerGradient,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.xxl),
        ),
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final scale = 1.0 + (_pulseController.value * 0.08);
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: context.semantic.textOnPrimary
                        .withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: context.semantic.textOnPrimary
                          .withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.hourglass_top_rounded,
                    size: 44,
                    color: context.semantic.textOnPrimary,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'التحقق جارٍ',
            style: context.text.headlineMedium?.copyWith(
              color: context.semantic.textOnPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _VerificationLoadingBar extends StatefulWidget {
  const _VerificationLoadingBar();

  @override
  State<_VerificationLoadingBar> createState() =>
      _VerificationLoadingBarState();
}

class _VerificationLoadingBarState extends State<_VerificationLoadingBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          height: 8,
          decoration: BoxDecoration(
            color: context.semantic.borderStrong,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Align(
            alignment: Alignment(_controller.value * 2 - 1, 0),
            child: Container(
              width: 80,
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                gradient: context.primaryGradient,
              ),
            ),
          ),
        );
      },
    );
  }
}
