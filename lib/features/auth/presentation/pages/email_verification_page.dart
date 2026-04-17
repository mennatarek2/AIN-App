import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/routes/app_routes.dart';
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
    if (_code.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال رمز التحقق كاملا'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (isSignUpFlow) {
      if (email == null || email.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('البريد الإلكتروني غير متاح للتحقق'),
            backgroundColor: Colors.red,
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
        const SnackBar(
          content: Text('البريد الإلكتروني غير متاح للتحقق'),
          backgroundColor: Colors.red,
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
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
      Future.microtask(
        () => ref.read(passwordResetNotifierProvider.notifier).reset(),
      );
      return;
    }

    if (mounted) {
      Navigator.of(context).pushReplacementNamed(
        nextRoute,
        arguments: ResetPasswordArgs(token: _normalizeDigits(_code)),
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
            backgroundColor: Colors.red,
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
        body: isSignUpFlow
            ? _buildSignUpVerification(context, nextRoute, isLoading, email)
            : _buildForgotPasswordVerification(
                context,
                nextRoute,
                isLoading,
                email,
              ),
      ),
    );
  }

  Widget _buildProgressIndicator({
    required BuildContext context,
    required int activeSteps,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    Widget bar(bool active) {
      return Container(
        width: 60,
        height: 4,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          color: active
              ? colorScheme.primary
              : colorScheme.primary.withOpacity(0.2),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        bar(activeSteps >= 1),
        const SizedBox(width: 8),
        bar(activeSteps >= 2),
        const SizedBox(width: 8),
        bar(activeSteps >= 3),
      ],
    );
  }

  Widget _buildForgotPasswordVerification(
    BuildContext context,
    String nextRoute,
    bool isLoading,
    String? email,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 72),
            Center(
              child: Image.asset(
                'assets/images/enterOTP.png',
                height: 270,
                width: 270,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 36),
            _buildProgressIndicator(context: context, activeSteps: 2),
            const SizedBox(height: 20),
            Text(
              'التحقق من البريد الإلكتروني',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: colorScheme.onBackground,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'أدخل رمز التحقق المكون من 4 أرقام الذي تم إرساله إلى بريدك الإلكتروني',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 18,
                height: 1.6,
                color: colorScheme.outline,
              ),
            ),
            const SizedBox(height: 32),
            _OtpFields(onChanged: _handleCodeChanged, enabled: !isLoading),
            const SizedBox(height: 40),
            _PrimaryButton(
              label: 'استمرار',
              isLoading: isLoading,
              onPressed: isLoading
                  ? null
                  : () => _handleVerify(
                      isSignUpFlow: false,
                      nextRoute: nextRoute,
                      email: email,
                    ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSignUpVerification(
    BuildContext context,
    String nextRoute,
    bool isLoading,
    String? email,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Stack(
        children: [
          Container(
            height: 350,
            width: double.infinity,
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.35),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(100),
                bottomRight: Radius.circular(100),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(30, 197, 30, 75),
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'التحقق من البريد الإلكتروني',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'أدخل رمز التحقق المكون من 4 أرقام الذي تم إرساله إلى بريدك الإلكتروني',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 18,
                        height: 1.6,
                        color: colorScheme.outline,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _OtpFields(
                      onChanged: _handleCodeChanged,
                      enabled: !isLoading,
                    ),
                    const SizedBox(height: 172),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 13),
                      child: SizedBox(
                        height: 52,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                colorScheme.secondary,
                                colorScheme.primary,
                              ],
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: isLoading
                                  ? null
                                  : () => _handleVerify(
                                      isSignUpFlow: true,
                                      nextRoute: nextRoute,
                                      email: email,
                                    ),
                              child: Center(
                                child: isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : const Text(
                                        'التحقق',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 20,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 13),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 13),
                      child: SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(
                              color: colorScheme.onSurface,
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            'إعادة إرسال الرمز',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
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
        ],
      ),
    );
  }
}

class _OtpFields extends StatefulWidget {
  const _OtpFields({required this.onChanged, required this.enabled});

  final ValueChanged<String> onChanged;
  final bool enabled;

  @override
  State<_OtpFields> createState() => _OtpFieldsState();
}

class _OtpFieldsState extends State<_OtpFields> {
  final _controllers = List.generate(
    4,
    (_) => TextEditingController(),
    growable: false,
  );

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(4, (index) {
        return SizedBox(
          width: 56,
          height: 56,
          child: TextField(
            controller: _controllers[index],
            enabled: widget.enabled,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            style: const TextStyle(
              color: Color(0xFF060C3A),
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: colorScheme.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: colorScheme.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
              ),
            ),
            onChanged: (value) {
              if (value.isNotEmpty && index < _controllers.length - 1) {
                FocusScope.of(context).nextFocus();
              }
              final code = _controllers.map((c) => c.text).join();
              widget.onChanged(code);
            },
          ),
        );
      }),
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
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 49),
      child: SizedBox(
        height: 52,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [colorScheme.secondary, colorScheme.primary],
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onPressed,
              child: Center(
                child: isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
