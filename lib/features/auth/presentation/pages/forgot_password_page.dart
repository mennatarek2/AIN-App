import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/routes/app_routes.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/app_layout_primitives.dart';
import '../notifiers/password_reset_notifier.dart';
import '../state/form_state_simple.dart' as auth_form;
import 'email_verification_page.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final notifier = ref.read(passwordResetNotifierProvider.notifier);
    final success = await notifier.sendPasswordResetEmail(
      email: _emailController.text.trim(),
    );

    if (success && mounted) {
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.emailVerification,
        arguments: EmailVerificationArgs(
          nextRoute: AppRoutes.resetPassword,
          email: _emailController.text.trim(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(passwordResetNotifierProvider);
    final isLoading = formState is auth_form.FormLoading;

    ref.listen<auth_form.FormState>(passwordResetNotifierProvider, (
      previous,
      next,
    ) {
      if (next is auth_form.FormError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.failure.message),
            backgroundColor: context.semantic.error,
          ),
        );
        Future.microtask(
          () => ref.read(passwordResetNotifierProvider.notifier).reset(),
        );
      }
    });

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
                    title: 'نسيت كلمة المرور',
                    subtitle:
                        'أدخل بريدك الإلكتروني وسنرسل لك رمز التحقق لإعادة التعيين',
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _emailController,
                            enabled: !isLoading,
                            keyboardType: TextInputType.emailAddress,
                            textAlign: TextAlign.right,
                            textDirection: TextDirection.rtl,
                            style: context.text.bodyLarge,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'هذا الحقل مطلوب';
                              }
                              if (!value.contains('@')) {
                                return 'البريد الإلكتروني غير صحيح';
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              hintText: 'البريد الإلكتروني',
                              prefixIcon: Icon(
                                Icons.email_outlined,
                                color: context.colors.primary,
                                size: 22,
                              ),
                              filled: true,
                              fillColor: context.semantic.surfaceInput,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _buildPrimaryButton(
                            label: 'استمرار',
                            isLoading: isLoading,
                            onPressed: isLoading ? null : _handleSubmit,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextButton(
                            onPressed: () => Navigator.of(context)
                                .pushReplacementNamed(AppRoutes.login),
                            child: Text(
                              'العودة لتسجيل الدخول',
                              style: TextStyle(
                                color: context.colors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
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
              Icons.lock_reset_rounded,
              size: 36,
              color: context.semantic.textOnPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'استعادة الحساب',
            style: context.text.headlineMedium?.copyWith(
              color: context.semantic.textOnPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'لا تقلق، سنساعدك على استعادة الوصول',
            textAlign: TextAlign.center,
            style: context.text.bodyMedium?.copyWith(
              color: context.semantic.textOnPrimary.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback? onPressed,
    required bool isLoading,
  }) {
    return SizedBox(
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          gradient: context.primaryGradient,
          boxShadow: [
            BoxShadow(
              color: context.colors.primary.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            onTap: onPressed,
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: context.semantic.textOnPrimary,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      label,
                      style: context.text.titleMedium?.copyWith(
                        color: context.semantic.textOnPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
