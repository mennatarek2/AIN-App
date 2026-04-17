import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/routes/app_routes.dart';
import '../notifiers/password_reset_notifier.dart';
import '../state/form_state_simple.dart' as auth_form;

class ResetPasswordArgs {
  final String token;
  const ResetPasswordArgs({required this.token});
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
  String _token = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as ResetPasswordArgs?;
    _token = args?.token ?? '';
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

    if (_token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('رمز التحقق غير متاح'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final notifier = ref.read(passwordResetNotifierProvider.notifier);
    final success = await notifier.resetPassword(
      token: _token,
      newPassword: _passwordController.text,
    );

    if (success && mounted) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.passwordChanged);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
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
            backgroundColor: Colors.red,
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
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 72),
                Center(
                  child: Image.asset(
                    'assets/images/resetPassword.png',
                    height: 220,
                    width: 220,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 36),
                Text(
                  'إعادة تعيين كلمة المرور',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onBackground,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'أدخل كلمة المرور الجديدة الخاصة بك',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 18,
                    height: 1.6,
                    color: colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 32),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _PasswordField(
                        hint: 'كلمة المرور',
                        controller: _passwordController,
                        enabled: !isLoading,
                        isConfirm: false,
                        iconColor: colorScheme.outline,
                        hintColor: colorScheme.outline,
                        fillColor: colorScheme.surface,
                        borderColor: colorScheme.outlineVariant,
                        focusedBorderColor: colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      _PasswordField(
                        hint: 'تأكيد كلمة المرور',
                        controller: _confirmPasswordController,
                        enabled: !isLoading,
                        isConfirm: true,
                        compareWith: _passwordController,
                        iconColor: colorScheme.outline,
                        hintColor: colorScheme.outline,
                        fillColor: colorScheme.surface,
                        borderColor: colorScheme.outlineVariant,
                        focusedBorderColor: colorScheme.primary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                _PrimaryButton(
                  label: 'استمرار',
                  isLoading: isLoading,
                  startColor: colorScheme.secondary,
                  endColor: colorScheme.primary,
                  onPressed: isLoading ? null : _handleReset,
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.hint,
    required this.controller,
    required this.enabled,
    required this.isConfirm,
    required this.iconColor,
    required this.hintColor,
    required this.fillColor,
    required this.borderColor,
    required this.focusedBorderColor,
    this.compareWith,
  });

  final String hint;
  final TextEditingController controller;
  final bool enabled;
  final bool isConfirm;
  final Color iconColor;
  final Color hintColor;
  final Color fillColor;
  final Color borderColor;
  final Color focusedBorderColor;
  final TextEditingController? compareWith;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      textAlign: TextAlign.right,
      obscureText: true,
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
        hintStyle: TextStyle(color: hintColor, fontSize: 16),
        filled: true,
        fillColor: fillColor,
        prefixIcon: Icon(Icons.lock_outline, color: iconColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: focusedBorderColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    required this.isLoading,
    required this.startColor,
    required this.endColor,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color startColor;
  final Color endColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 49, vertical: 90),
      child: SizedBox(
        height: 56,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [startColor, endColor],
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
                          fontSize: 18,
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
