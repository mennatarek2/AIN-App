import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/routes/app_routes.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/app_layout_primitives.dart';
import '../providers/auth_provider.dart';
import '../state/auth_state_simple.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(authNotifierProvider.notifier);
    final success = await notifier.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (success && mounted) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.failure.message),
            backgroundColor: context.semantic.error,
          ),
        );
        Future.microtask(
          () => ref.read(authNotifierProvider.notifier).clearError(),
        );
      }
    });

    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState is AuthLoading;

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
                    title: 'تسجيل الدخول',
                    subtitle: 'أدخل بياناتك للوصول إلى حسابك',
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildInput(
                            hint: 'البريد الإلكتروني',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            controller: _emailController,
                            enabled: !isLoading,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _buildInput(
                            hint: 'كلمة المرور',
                            icon: Icons.lock_outline_rounded,
                            obscureText: _obscurePassword,
                            controller: _passwordController,
                            enabled: !isLoading,
                            suffix: IconButton(
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: context.semantic.textMuted,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _buildRememberAndForgot(context),
                          const SizedBox(height: AppSpacing.lg),
                          _buildLoginButton(isLoading),
                          const SizedBox(height: AppSpacing.lg),
                          _buildDividerWithOr(context),
                          const SizedBox(height: AppSpacing.lg),
                          _buildGoogleButton(context),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const AppTrustIndicators(),
                const SizedBox(height: AppSpacing.lg),
                _buildSignUpLink(context),
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
              Icons.remove_red_eye_rounded,
              size: 36,
              color: context.semantic.textOnPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'عين',
            style: context.text.headlineMedium?.copyWith(
              color: context.semantic.textOnPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'منصة البلاغات والمساعدة الطارئة',
            textAlign: TextAlign.center,
            style: context.text.bodyMedium?.copyWith(
              color: context.semantic.textOnPrimary.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput({
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    TextEditingController? controller,
    bool enabled = true,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      textAlign: TextAlign.right,
      textDirection: TextDirection.rtl,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: context.text.bodyLarge,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'هذا الحقل مطلوب';
        }
        if (keyboardType == TextInputType.emailAddress &&
            !value.contains('@')) {
          return 'البريد الإلكتروني غير صحيح';
        }
        return null;
      },
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: context.colors.primary, size: 22),
        suffixIcon: suffix,
        filled: true,
        fillColor: context.semantic.surfaceInput,
      ),
    );
  }

  Widget _buildRememberAndForgot(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton(
          onPressed: () => Navigator.of(context).pushReplacementNamed(
            AppRoutes.forgotPassword,
          ),
          style: TextButton.styleFrom(
            foregroundColor: context.colors.primary,
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text('نسيت كلمة المرور؟'),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: false,
              onChanged: (_) {},
              visualDensity: VisualDensity.compact,
            ),
            Text('تذكرني', style: context.text.bodySmall),
          ],
        ),
      ],
    );
  }

  Widget _buildLoginButton(bool isLoading) {
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
            onTap: isLoading ? null : _handleLogin,
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
                      'تسجيل الدخول',
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

  Widget _buildDividerWithOr(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: context.semantic.divider)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Text('أو', style: context.text.bodySmall),
        ),
        Expanded(child: Divider(color: context.semantic.divider)),
      ],
    );
  }

  Widget _buildGoogleButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: Image.asset(
        'assets/images/googleIcon.png',
        width: 22,
        height: 22,
        errorBuilder: (_, __, ___) => Icon(
          Icons.g_mobiledata_rounded,
          size: 26,
          color: context.colors.onSurface,
        ),
      ),
      label: const Text('الاستمرار باستخدام جوجل'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 52),
        side: BorderSide(color: context.semantic.borderSubtle),
      ),
    );
  }

  Widget _buildSignUpLink(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          Navigator.of(context).pushReplacementNamed(AppRoutes.signUp),
      child: RichText(
        text: TextSpan(
          style: context.text.bodyMedium,
          children: [
            const TextSpan(text: 'ليس لديك حساب؟ '),
            TextSpan(
              text: 'إنشاء حساب جديد',
              style: TextStyle(
                color: context.colors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
