import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/checkmark_success_animation.dart';
import 'community_page.dart';

class ConfirmCommunityAddedPage extends StatelessWidget {
  const ConfirmCommunityAddedPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? const Color(0xFF060C3A)
        : AppColors.backgroundLight;
    final titleColor = isDark
        ? const Color(0xFFF3F6F9)
        : AppColors.textPrimaryLight;
    final buttonTextColor = isDark
        ? const Color(0xFFF3F6F9)
        : AppColors.backgroundLight;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CheckmarkSuccessAnimation(),
                const SizedBox(height: 18),
                Text(
                  'تمت إنشاء المجموعة\nبنجاح',
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 96),
                SizedBox(
                  width: 300,
                  height: 52,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [AppColors.primary, AppColors.primarySoft],
                      ),
                    ),
                    child: TextButton(
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => const CommunityPage(),
                          ),
                          (route) => route.isFirst,
                        );
                      },
                      child: Text(
                        'المتابعة',
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w600,
                          color: buttonTextColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
