import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/routes/app_routes.dart';
import '../../../../core/state/app_flow_provider.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 2), _goNext);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _goNext() {
    if (!mounted) return;
    final nextRoute = ref.read(appLaunchRouteProvider);

    if (nextRoute == AppRoutes.splash) {
      _timer = Timer(const Duration(milliseconds: 350), _goNext);
      return;
    }

    Navigator.of(context).pushReplacementNamed(nextRoute);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: isDarkMode ? _buildDarkSplash() : _buildLightSplash(),
        ),
      ),
    );
  }

  Widget _buildLightSplash() {
    return Image.asset('assets/images/splashScreen.png', fit: BoxFit.contain);
  }

  Widget _buildDarkSplash() {
    return Container(
      width: 192,
      height: 320,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Arabic Logo (using existing splash image centered)
          Expanded(
            child: Image.asset(
              'assets/images/splashScreen.png',
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}
