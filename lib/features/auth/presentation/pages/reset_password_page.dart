import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/routes/app_routes.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/app_layout_primitives.dart';
import '../providers/auth_provider.dart';
import '../notifiers/password_reset_notifier.dart';
import '../state/form_state_simple.dart' as auth_form;

class ResetPasswordArgs {
  final String email;
  const ResetPasswordArgs({required this.email});
}

class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _email = '';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as ResetPasswordArgs?;
    _email = args?.email ?? '';
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('البريد الإلكتروني غير متاح'),
          backgroundColor: context.semantic.error,
        ),
      );
      return;
    }

    final notifier = ref.read(passwordResetNotifierProvider.notifier);
    final success = await notifier.resetPassword(
      newPassword: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
    );

    if (success && mounted) {
      await ref.read(authNotifierProvider.notifier).refreshSession();
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(AppRoutes.passwordChanged);
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
                    title: 'إعادة تعيين كلمة المرور',
                    subtitle: 'أدخل كلمة المرور الجديدة الخاصة بك',
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildProgressIndicator(context, activeSteps: 3),
                          const SizedBox(height: AppSpacing.lg),
                          _PasswordField(
                            hint: 'كلمة المرور',
                            controller: _passwordController,
                            enabled: !isLoading,
                            isConfirm: false,
                            obscureText: _obscurePassword,
                            onToggleVisibility: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _PasswordField(
                            hint: 'تأكيد كلمة المرور',
                            controller: _confirmPasswordController,
                            enabled: !isLoading,
                            isConfirm: true,
                            compareWith: _passwordController,
                            obscureText: _obscureConfirmPassword,
                            onToggleVisibility: () => setState(
                              () => _obscureConfirmPassword =
                                  !_obscureConfirmPassword,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _PrimaryButton(
                            label: 'استمرار',
                            isLoading: isLoading,
                            onPressed: isLoading ? null : _handleReset,
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
              Icons.password_rounded,
              size: 36,
              color: context.semantic.textOnPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'كلمة مرور جديدة',
            style: context.text.headlineMedium?.copyWith(
              color: context.semantic.textOnPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'الخطوة 3 من 3 — اختر كلمة مرور قوية',
            textAlign: TextAlign.center,
            style: context.text.bodyMedium?.copyWith(
              color: context.semantic.textOnPrimary.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(BuildContext context, {required int activeSteps}) {
    Widget bar(bool active) {
      return Expanded(
        child: Container(
          height: 4,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            color: active
                ? context.colors.primary
                : context.colors.primary.withValues(alpha: 0.2),
          ),
        ),
      );
    }

    return Row(
      children: [
        bar(activeSteps >= 1),
        bar(activeSteps >= 2),
        bar(activeSteps >= 3),
      ],
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.hint,
    required this.controller,
    required this.enabled,
    required this.isConfirm,
    required this.obscureText,
    required this.onToggleVisibility,
    this.compareWith,
  });

  final String hint;
  final TextEditingController controller;
  final bool enabled;
  final bool isConfirm;
  final bool obscureText;
  final VoidCallback onToggleVisibility;
  final TextEditingController? compareWith;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      textAlign: TextAlign.right,
      textDirection: TextDirection.rtl,
      obscureText: obscureText,
      style: context.text.bodyLarge,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'هذا الحقل مطلوب';
        }
        if (!isConfirm && value.length < 6) {
          return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
        }
        if (isConfirm && compareWith != null) {
          if (value != compareWith!.text) {
            return 'كلمة المرور غير متطابقة';
          }
        }
        return null;
      },
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(
          Icons.lock_outline_rounded,
          color: context.colors.primary,
          size: 22,
        ),
        suffixIcon: IconButton(
          onPressed: onToggleVisibility,
          icon: Icon(
            obscureText
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: context.semantic.textMuted,
          ),
        ),
        filled: true,
        fillColor: context.semantic.surfaceInput,
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    required this.isLoading,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
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
