import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/app_layout_primitives.dart';
import '../../../../core/widgets/checkmark_success_animation.dart';
import 'community_page.dart';

class ConfirmCommunityAddedPage extends StatelessWidget {
  const ConfirmCommunityAddedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          AppDashboardHeader(
            title: 'تم الإنشاء',
            subtitle: 'مجتمعك جاهز للانطلاق',
            compact: true,
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                  vertical: AppSpacing.lg,
                ),
                child: AppFormCard(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CheckmarkSuccessAnimation(size: 120),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'تمت إنشاء المجموعة بنجاح',
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.center,
                        style: context.text.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'يمكنك الآن دعوة الأعضاء ومتابعة مجتمعك',
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.center,
                        style: context.text.bodyMedium?.copyWith(
                          color: context.semantic.textMuted,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppRadius.xl),
                            gradient: context.primaryGradient,
                            boxShadow: [
                              BoxShadow(
                                color: context.colors.primary.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.xl),
                              onTap: () {
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                    builder: (_) => const CommunityPage(),
                                  ),
                                  (route) => route.isFirst,
                                );
                              },
                              child: Center(
                                child: Text(
                                  'المتابعة',
                                  style: context.text.titleMedium?.copyWith(
                                    color: context.semantic.textOnPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
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
          ),
        ],
      ),
    );
  }
}
