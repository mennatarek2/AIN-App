import 'package:flutter/material.dart';

import '../../../../config/routes/app_routes.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/app_layout_primitives.dart';
import '../../../../core/widgets/checkmark_success_animation.dart';

class AddReportSuccessPage extends StatelessWidget {
  const AddReportSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                context.colors.surface,
                context.colors.primary.withValues(alpha: 0.06),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Brand hero strip
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.only(
                    top: AppSpacing.lg,
                    bottom: AppSpacing.xl,
                  ),
                  decoration: BoxDecoration(
                    gradient: context.heroGradient,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(AppRadius.xxl),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: context.semantic.shadow,
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: context.semantic.textOnPrimary.withValues(
                            alpha: 0.15,
                          ),
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(
                            color: context.semantic.textOnPrimary.withValues(
                              alpha: 0.25,
                            ),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'عَيْن',
                            style: TextStyle(
                              color: context.semantic.textOnPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenHorizontal,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CheckmarkSuccessAnimation(size: 120),
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          'تم إرسال البلاغ بنجاح',
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.center,
                          style: context.text.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: context.colors.onSurface,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'يمكنك الآن متابعة حالته من صفحة البلاغات الخاصة بك',
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.center,
                          style: context.text.bodyLarge?.copyWith(
                            color: context.semantic.textMuted,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        AppFormCard(
                          child: Column(
                            children: [
                              Row(
                                textDirection: TextDirection.rtl,
                                children: [
                                  Icon(
                                    Icons.notifications_active_outlined,
                                    color: context.colors.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  Expanded(
                                    child: Text(
                                      'سنُعلمك عند أي تحديث على بلاغك',
                                      textDirection: TextDirection.rtl,
                                      style: context.text.bodySmall?.copyWith(
                                        color: context.semantic.textMuted,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.screenHorizontal,
                    AppSpacing.sm,
                    AppSpacing.screenHorizontal,
                    AppSpacing.lg + MediaQuery.of(context).padding.bottom,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: context.primaryGradient,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        boxShadow: [
                          BoxShadow(
                            color: context.colors.primary.withValues(
                              alpha: 0.35,
                            ),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          onTap: () {
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              AppRoutes.home,
                              (route) => false,
                            );
                          },
                          child: Center(
                            child: Text(
                              'العودة إلى الصفحة الرئيسية',
                              textDirection: TextDirection.rtl,
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
