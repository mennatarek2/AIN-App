import 'package:flutter/material.dart';
import 'dart:async';

import '../../../../config/routes/app_routes.dart';
import '../../../../core/theme/app_colors.dart';

class VerificationProgressPage extends StatefulWidget {
  const VerificationProgressPage({super.key});

  @override
  State<VerificationProgressPage> createState() =>
      _VerificationProgressPageState();
}

class _VerificationProgressPageState extends State<VerificationProgressPage> {
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtitleColor =
        (isDark ? AppColors.textPrimaryDark : AppColors.textSecondaryLight)
            .withValues(alpha: isDark ? 0.95 : 1);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    SizedBox(height: constraints.maxHeight * 0.26),
                    Text(
                      'جاري التحقق ...',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontSize: 29,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'نقوم الآن بمراجعة بياناتك. تستغرق العملية ثوانٍ قليلة.\nيرجى الانتظار حتى اكتمال التحقق',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                        color: subtitleColor,
                      ),
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 34),
                      child: _VerificationLoadingBar(isDark: isDark),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _VerificationLoadingBar extends StatelessWidget {
  const _VerificationLoadingBar({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 320,
        height: 25,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 320,
              height: 25,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFFE3E3E3)
                    : const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 25,
                height: 25,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.primary, AppColors.primarySoft],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
