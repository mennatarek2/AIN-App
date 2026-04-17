import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../../../config/routes/app_routes.dart';
import '../../../../core/theme/app_colors.dart';

class VerificationSuccessPage extends StatelessWidget {
  const VerificationSuccessPage({super.key});

  static const String _successAnimationAsset =
      'assets/animations/report_success.lottie';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final titleColor = colorScheme.onBackground;
    final bodyColor = colorScheme.onBackground.withValues(alpha: 0.95);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final scale = constraints.maxHeight / 932;
              final buttonWidth = constraints.maxWidth < 300
                  ? constraints.maxWidth
                  : 300.0;

              return Stack(
                children: [
                  Positioned(
                    top: 268 * scale,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: SizedBox(
                        width: 104,
                        height: 104,
                        child: ClipOval(
                          child: Lottie.asset(
                            _successAnimationAsset,
                            fit: BoxFit.cover,
                            repeat: false,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.check_rounded,
                                color: AppColors.primary,
                                size: 62,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 380 * scale,
                    left: 0,
                    right: 0,
                    child: Text(
                      'تم التحقق بنجاح!',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontSize: 29,
                            fontWeight: FontWeight.w700,
                            color: titleColor,
                          ),
                    ),
                  ),
                  Positioned(
                    top: 448 * scale,
                    left: 27,
                    right: 27,
                    child: Text(
                      'لقد اكتملت عملية التحقق من بياناتك ، يمكنك الآن البدء\nفي استخدام التطبيق.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                        color: bodyColor,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 656 * scale,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: SizedBox(
                        width: buttonWidth,
                        height: 52,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            gradient: const LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                AppColors.primary,
                                AppColors.primarySoft,
                              ],
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () {
                                Navigator.of(
                                  context,
                                ).pushReplacementNamed(AppRoutes.home);
                              },
                              child: Center(
                                child: Text(
                                  'المتابعة',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        color: AppColors.textPrimaryDark,
                                        fontSize: 21,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
