import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/routes/app_routes.dart';
import '../../../../core/state/app_flow_provider.dart';
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
  late final Animation<double> _heightAnim;
  late final Animation<double> _widthAnim;
  late final Animation<double> _logoOpacityAnim;
  late final Animation<double> _scaleAnim;
  bool _animationCompleted = false;
  bool _didNavigate = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _heightAnim = Tween<double>(begin: 10, end: 325).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.2, curve: Curves.easeOut),
      ),
    );

    _widthAnim = Tween<double>(begin: 10, end: 200).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.55, curve: Curves.easeInOut),
      ),
    );

    _logoOpacityAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.55, 0.85, curve: Curves.easeIn),
      ),
    );

    _scaleAnim =
        TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween<double>(begin: 1.0, end: 1.06),
            weight: 50,
          ),
          TweenSequenceItem(
            tween: Tween<double>(begin: 1.06, end: 1.0),
            weight: 50,
          ),
        ]).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.85, 1.0, curve: Curves.easeOut),
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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF0A1045) : Colors.white;
    final boxColor = isDark ? const Color(0xFFF0F4F8) : const Color(0xFF0A1045);
    final textColor = isDark ? const Color(0xFF0A1045) : Colors.white;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final showText = _logoOpacityAnim.value > 0;

              return Transform.scale(
                scale: _scaleAnim.value,
                child: Container(
                  width: _widthAnim.value,
                  height: _heightAnim.value,
                  decoration: BoxDecoration(
                    color: boxColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: showText
                      ? Opacity(
                          opacity: _logoOpacityAnim.value,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'عَيْن',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w500,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Ai-N',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: 2.5,
                                ),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
