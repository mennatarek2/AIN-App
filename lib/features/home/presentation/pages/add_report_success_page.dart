import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../../../config/routes/app_routes.dart';
import '../../../../core/theme/app_colors.dart';

class AddReportSuccessPage extends StatelessWidget {
  const AddReportSuccessPage({super.key});

  static const double _designW = 430;
  static const double _designH = 932;
  static const String _checkmarkAnimationAssetPath =
      'assets/animations/report_success.lottie';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final titleColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final subtitleColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textSecondaryLight;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final scale = constraints.maxWidth / _designW;
              final designHeight = _designH * scale;
              final canvasHeight = designHeight > constraints.maxHeight
                  ? designHeight
                  : constraints.maxHeight;

              double sx(double value) => value * scale;

              return SizedBox(
                width: constraints.maxWidth,
                height: canvasHeight,
                child: Stack(
                  children: [
                    Positioned(
                      left: sx(125),
                      top: sx(140),
                      width: sx(180),
                      height: sx(180),
                      child: Lottie.asset(
                        _checkmarkAnimationAssetPath,
                        repeat: false,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              size: 80,
                              color: Colors.white,
                            ),
                          );
                        },
                      ),
                    ),
                    Positioned(
                      left: sx(91),
                      top: sx(356),
                      width: sx(248),
                      child: Text(
                        'تم إرسال البلاغ بنجاح',
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: sx(25),
                          fontWeight: FontWeight.w700,
                          color: titleColor,
                          height: 1,
                        ),
                      ),
                    ),
                    Positioned(
                      left: sx(29),
                      top: sx(416),
                      width: sx(372),
                      child: Text(
                        'يمكنك الآن متابعة حالته من صفحة البلاغات الخاصة بك',
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: sx(17),
                          color: subtitleColor,
                          fontWeight: FontWeight.w400,
                          height: 1,
                        ),
                      ),
                    ),
                    Positioned(
                      left: sx(65),
                      top: sx(584),
                      width: sx(300),
                      height: sx(52),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFF0099FF), Color(0xFF66C8FF)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              AppRoutes.home,
                              (route) => false,
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFFF3F6F9),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'العودة إلى الصفحة الرئيسية',
                            textDirection: TextDirection.rtl,
                            style: TextStyle(
                              fontSize: sx(21),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
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
