import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/routes/app_routes.dart';
import '../../../../core/state/app_flow_provider.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/state/auth_state_simple.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoScaleAnim;
  late final Animation<double> _logoOpacityAnim;
  late final Animation<double> _taglineOpacityAnim;
  late final Animation<double> _glowAnim;
  bool _animationCompleted = false;
  bool _didNavigate = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _logoScaleAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack),
      ),
    );

    _logoOpacityAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    _taglineOpacityAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.45, 0.75, curve: Curves.easeIn),
      ),
    );

    _glowAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.55, 1.0, curve: Curves.easeInOut),
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationCompleted = true;
        Future.delayed(const Duration(milliseconds: 600), () {
          _tryNavigateNext();
        });
      }
    });

    _controller.forward();
  }

  void _tryNavigateNext() {
    if (!mounted || _didNavigate || !_animationCompleted) {
      return;
    }

    final nextRoute = ref.read(appLaunchRouteProvider);
    if (nextRoute == AppRoutes.splash) {
      return;
    }

    _didNavigate = true;
    Navigator.of(context).pushReplacementNamed(nextRoute);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next is AuthAuthenticated || next is AuthUnauthenticated) {
        _tryNavigateNext();
      }
    });

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: context.heroGradient,
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                top: -80,
                right: -60,
                child: AnimatedBuilder(
                  animation: _glowAnim,
                  builder: (context, child) {
                    return Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: context.semantic.textOnPrimary.withValues(
                          alpha: 0.06 * _glowAnim.value,
                        ),
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                bottom: -100,
                left: -80,
                child: AnimatedBuilder(
                  animation: _glowAnim,
                  builder: (context, child) {
                    return Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: context.semantic.textOnPrimary.withValues(
                          alpha: 0.04 * _glowAnim.value,
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Brand hero
              Center(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _logoOpacityAnim.value,
                      child: Transform.scale(
                        scale: _logoScaleAnim.value,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: context.semantic.textOnPrimary
                                    .withValues(alpha: 0.15),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.xxl),
                                border: Border.all(
                                  color: context.semantic.textOnPrimary
                                      .withValues(alpha: 0.3),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: context.semantic.shadow.withValues(
                                      alpha: 0.3 * _glowAnim.value,
                                    ),
                                    blurRadius: 32,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'عَيْن',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: context.semantic.textOnPrimary,
                                      fontSize: 32,
                                      fontWeight: FontWeight.w800,
                                      height: 1.2,
                                    ),
                                  ),
                                  Text(
                                    'Ai-N',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: context.semantic.textOnPrimary
                                          .withValues(alpha: 0.85),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: AppSpacing.xl * _taglineOpacityAnim.value),
                            Opacity(
                              opacity: _taglineOpacityAnim.value,
                              child: Text(
                                'من عَيْنك يبدأ الحل',
                                textDirection: TextDirection.rtl,
                                style: context.text.titleMedium?.copyWith(
                                  color: context.semantic.textOnPrimary
                                      .withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Loading indicator at bottom
              Positioned(
                left: 0,
                right: 0,
                bottom: AppSpacing.xxl,
                child: AnimatedBuilder(
                  animation: _taglineOpacityAnim,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _taglineOpacityAnim.value,
                      child: Center(
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: context.semantic.textOnPrimary.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
