import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/routes/app_routes.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/app_layout_primitives.dart';
import '../../../../core/widgets/app_otp_input.dart';
import '../notifiers/email_verification_notifier.dart';
import '../notifiers/password_reset_notifier.dart';
import 'email_verification_success_page.dart';
import '../state/form_state_simple.dart' as auth_form;
import 'reset_password_page.dart';

class EmailVerificationArgs {
  final String nextRoute;
  final String? email;

  const EmailVerificationArgs({required this.nextRoute, this.email});
}

class EmailVerificationPage extends ConsumerStatefulWidget {
  const EmailVerificationPage({super.key});

  @override
  ConsumerState<EmailVerificationPage> createState() =>
      _EmailVerificationPageState();
}

class _EmailVerificationPageState extends ConsumerState<EmailVerificationPage> {
  static const int _otpLength = 6;
  String _code = '';

  String _normalizeDigits(String input) {
    const arabicIndic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    const easternArabicIndic = [
      '۰',
      '۱',
      '۲',
      '۳',
      '۴',
      '۵',
      '۶',
      '۷',
      '۸',
      '۹',
    ];

    var normalized = input;
    for (var i = 0; i < 10; i++) {
      normalized = normalized.replaceAll(arabicIndic[i], i.toString());
      normalized = normalized.replaceAll(easternArabicIndic[i], i.toString());
    }
    return normalized.trim();
  }

  void _handleCodeChanged(String value) {
    setState(() {
      _code = _normalizeDigits(value);
    });
  }

  Future<void> _handleVerify({
    required bool isSignUpFlow,
    required String nextRoute,
    String? email,
  }) async {
    if (_code.length < _otpLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('يرجى إدخال رمز التحقق المكون من $_otpLength أرقام'),
          backgroundColor: context.semantic.error,
        ),
      );
      return;
    }

    if (isSignUpFlow) {
      if (email == null || email.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('البريد الإلكتروني غير متاح للتحقق'),
            backgroundColor: context.semantic.error,
          ),
        );
        return;
      }

      final notifier = ref.read(emailVerificationNotifierProvider.notifier);
      final success = await notifier.verifyEmail(email: email, code: _code);

      if (success && mounted) {
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.emailVerificationSuccess,
          arguments: EmailVerificationSuccessArgs(nextRoute: nextRoute),
        );
      }
      return;
    }

    if (email == null || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('البريد الإلكتروني غير متاح للتحقق'),
          backgroundColor: context.semantic.error,
        ),
      );
      return;
    }

    final resetNotifier = ref.read(passwordResetNotifierProvider.notifier);
    final verified = await resetNotifier.verifyResetCode(
      email: email,
      code: _normalizeDigits(_code),
    );

    if (!verified) {
      if (!mounted) {
        return;
      }

      final state = ref.read(passwordResetNotifierProvider);
      final message = state is auth_form.FormError
          ? state.failure.message
          : 'رمز التحقق غير صالح أو منتهي الصلاحية';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: context.semantic.error,
        ),
      );
      Future.microtask(
        () => ref.read(passwordResetNotifierProvider.notifier).reset(),
      );
      return;
    }

    if (mounted) {
      Navigator.of(context).pushReplacementNamed(
        nextRoute,
        arguments: ResetPasswordArgs(email: email),
      );
    }
  }

  Future<void> _handleResend(bool isSignUpFlow, String? email) async {
    if (isSignUpFlow) {
      final notifier = ref.read(emailVerificationNotifierProvider.notifier);
      final success = await notifier.resendOtp();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'تم إعادة إرسال الرمز' : 'تعذر إعادة الإرسال'),
        ),
      );
      return;
    }

    final resetNotifier = ref.read(passwordResetNotifierProvider.notifier);
    final success = await resetNotifier.resendForgotPasswordOtp();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'تم إعادة إرسال الرمز' : 'تعذر إعادة الإرسال'),
      ),
    );
    if (!success) {
      Future.microtask(
        () => ref.read(passwordResetNotifierProvider.notifier).reset(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as EmailVerificationArgs?;
    final nextRoute = args?.nextRoute ?? AppRoutes.resetPassword;
    final isSignUpFlow = nextRoute == AppRoutes.idVerificationIntro;
    final email = args?.email;

    final formState = ref.watch(emailVerificationNotifierProvider);
    final isLoading = formState is auth_form.FormLoading;

    ref.listen<auth_form.FormState>(emailVerificationNotifierProvider, (
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
          () => ref.read(emailVerificationNotifierProvider.notifier).reset(),
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
                _buildHero(
                  context,
                  isSignUpFlow: isSignUpFlow,
                  email: email,
                ),
                Transform.translate(
                  offset: const Offset(0, -AppSpacing.xxxl),
                  child: AppFormCard(
                    title: 'التحقق من البريد الإلكتروني',
                    subtitle:
                        'أدخل رمز التحقق المكون من 6 أرقام المرسل إلى بريدك',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (email != null && email.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: context.colors.primary
                                  .withValues(alpha: 0.08),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.lg),
                              border: Border.all(
                                color: context.colors.primary
                                    .withValues(alpha: 0.18),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.mark_email_read_outlined,
                                  size: 18,
                                  color: context.colors.primary,
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Flexible(
                                  child: Text(
                                    email,
                                    textAlign: TextAlign.center,
                                    style: context.text.bodySmall?.copyWith(
                                      color: context.colors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                        ],
                        AppOtpInput(
                          length: _otpLength,
                          enabled: !isLoading,
                          onChanged: _handleCodeChanged,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _PrimaryButton(
                          label: isSignUpFlow ? 'التحقق' : 'استمرار',
                          isLoading: isLoading,
                          onPressed: isLoading
                              ? null
                              : () => _handleVerify(
                                    isSignUpFlow: isSignUpFlow,
                                    nextRoute: nextRoute,
                                    email: email,
                                  ),
                        ),
                        if (isSignUpFlow) ...[
                          const SizedBox(height: AppSpacing.md),
                          OutlinedButton(
                            onPressed: isLoading
                                ? null
                                : () => _handleResend(isSignUpFlow, email),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 52),
                              side: BorderSide(
                                color: context.semantic.borderSubtle,
                              ),
                            ),
                            child: const Text('إعادة إرسال الرمز'),
                          ),
                        ],
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

  Widget _buildHero(
    BuildContext context, {
    required bool isSignUpFlow,
    String? email,
  }) {
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
          if (!isSignUpFlow) ...[
            _buildProgressIndicator(context: context, activeSteps: 2),
            const SizedBox(height: AppSpacing.lg),
          ],
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
              Icons.mark_email_unread_outlined,
              size: 36,
              color: context.semantic.textOnPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            isSignUpFlow ? 'تحقق من بريدك' : 'الخطوة 2 من 3',
            style: context.text.headlineMedium?.copyWith(
              color: context.semantic.textOnPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            isSignUpFlow
                ? 'أدخل الرمز المرسل إلى بريدك الإلكتروني'
                : 'تحقق من بريدك لإعادة تعيين كلمة المرور',
            textAlign: TextAlign.center,
            style: context.text.bodyMedium?.copyWith(
              color: context.semantic.textOnPrimary.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator({
    required BuildContext context,
    required int activeSteps,
  }) {
    Widget bar(bool active) {
      return Expanded(
        child: Container(
          height: 4,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            color: active
                ? context.semantic.textOnPrimary
                : context.semantic.textOnPrimary.withValues(alpha: 0.25),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Row(
        children: [
          bar(activeSteps >= 1),
          bar(activeSteps >= 2),
          bar(activeSteps >= 3),
        ],
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
