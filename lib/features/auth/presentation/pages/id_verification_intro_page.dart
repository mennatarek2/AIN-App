import 'package:flutter/material.dart';

import '../../../../config/routes/app_routes.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/app_layout_primitives.dart';

class IdVerificationIntroPage extends StatelessWidget {
  const IdVerificationIntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildHero(context),
                Transform.translate(
                  offset: const Offset(0, -AppSpacing.xxxl),
                  child: AppFormCard(
                    title: 'التحقق من الهوية',
                    subtitle: 'لإكمال عملية التسجيل الخاصة بك، ستحتاج إلى:',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _StepRow(
                          number: '1',
                          icon: Icons.credit_card_outlined,
                          title: 'صور بطاقة الرقم القومي',
                          description:
                              'التقط صورة أو اختر من المعرض للوجهين الأمامي والخلفي.',
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _StepRow(
                          number: '2',
                          icon: Icons.face_retouching_natural_outlined,
                          title: 'إضافة صورة شخصية',
                          description:
                              'التقط صورة أو اختر من المعرض مع إضاءة جيدة',
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _StepRow(
                          number: '3',
                          icon: Icons.fact_check_outlined,
                          title: 'تأكيد المعلومات الأساسية',
                          description:
                              'سيتم المراجعة والتأكد من صحة المعلومات التي أدخلتها',
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        SizedBox(
                          height: 52,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.xl),
                              gradient: context.primaryGradient,
                              boxShadow: [
                                BoxShadow(
                                  color: context.colors.primary
                                      .withValues(alpha: 0.35),
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
                                  Navigator.of(context).pushReplacementNamed(
                                    AppRoutes.idVerification,
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
                const SizedBox(height: AppSpacing.xxl),
                const AppTrustIndicators(),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
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
        AppSpacing.xxl,
        AppSpacing.xl,
        AppSpacing.huge + AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        gradient: context.headerGradient,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.xxl),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: context.semantic.textOnPrimary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: context.semantic.textOnPrimary.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.verified_user_outlined,
              size: 36,
              color: context.semantic.textOnPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'خطوة أخيرة',
            style: context.text.headlineMedium?.copyWith(
              color: context.semantic.textOnPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'تحقق من هويتك لضمان أمان المجتمع',
            textAlign: TextAlign.center,
            style: context.text.bodyMedium?.copyWith(
              color: context.semantic.textOnPrimary.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.number,
    required this.icon,
    required this.title,
    required this.description,
  });

  final String number;
  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.semantic.surfaceInput,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.semantic.borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: context.primaryGradient,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              number,
              style: context.text.titleSmall?.copyWith(
                color: context.semantic.textOnPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 18, color: context.colors.primary),
                    const SizedBox(width: AppSpacing.xxs),
                    Expanded(
                      child: Text(
                        title,
                        textAlign: TextAlign.right,
                        style: context.text.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  description,
                  textAlign: TextAlign.right,
                  style: context.text.bodySmall?.copyWith(
                    color: context.semantic.textMuted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
