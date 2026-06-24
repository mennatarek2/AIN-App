import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/routes/app_routes.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/app_layout_primitives.dart';
import '../../domain/utils/username_utils.dart';
import 'email_verification_page.dart';
import '../providers/auth_provider.dart';
import '../state/auth_state_simple.dart';

class SignUpPage extends ConsumerStatefulWidget {
  const SignUpPage({super.key});

  @override
  ConsumerState<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends ConsumerState<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ssnController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _ssnController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email = _emailController.text.trim();
    if (UsernameUtils.fromEmail(email) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('البريد الإلكتروني غير صحيح'),
          backgroundColor: context.semantic.error,
        ),
      );
      return;
    }

    final notifier = ref.read(authNotifierProvider.notifier);
    final success = await notifier.signUp(
      email: email,
      password: _passwordController.text,
      name: _nameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      ssn: _ssnController.text.trim(),
    );

    if (success && mounted) {
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.emailVerification,
        arguments: EmailVerificationArgs(
          nextRoute: AppRoutes.idVerificationIntro,
          email: email,
        ),
      );
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
                    title: 'إنشاء حساب جديد',
                    subtitle: 'أدخل بياناتك لإنشاء حسابك',
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildInput(
                            hint: 'الاسم الكامل',
                            icon: Icons.person_outline_rounded,
                            textInputAction: TextInputAction.next,
                            controller: _nameController,
                            enabled: !isLoading,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _buildInput(
                            hint: 'البريد الإلكتروني',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            controller: _emailController,
                            enabled: !isLoading,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _buildInput(
                            hint: 'رقم الهاتف المحمول',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            controller: _phoneController,
                            enabled: !isLoading,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _buildInput(
                            hint: 'رقم الهوية الشخصية',
                            icon: Icons.badge_outlined,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            controller: _ssnController,
                            enabled: !isLoading,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _buildInput(
                            hint: 'كلمة المرور',
                            icon: Icons.lock_outline_rounded,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.next,
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
                          const SizedBox(height: AppSpacing.md),
                          _buildInput(
                            hint: 'تأكيد كلمة المرور',
                            icon: Icons.lock_outline_rounded,
                            obscureText: _obscureConfirmPassword,
                            textInputAction: TextInputAction.done,
                            controller: _confirmPasswordController,
                            enabled: !isLoading,
                            suffix: IconButton(
                              onPressed: () => setState(
                                () => _obscureConfirmPassword =
                                    !_obscureConfirmPassword,
                              ),
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: context.semantic.textMuted,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _buildContinueButton(isLoading),
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
                _buildLoginLink(context),
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
              Icons.person_add_outlined,
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
            'انضم إلى مجتمع البلاغات والمساعدة',
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
    TextInputAction? textInputAction,
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
      textInputAction: textInputAction,
      obscureText: obscureText,
      style: context.text.bodyLarge,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'هذا الحقل مطلوب';
        }
        if (keyboardType == TextInputType.emailAddress) {
          if (UsernameUtils.fromEmail(value) == null) {
            return 'البريد الإلكتروني غير صحيح';
          }
        }
        if (hint == 'تأكيد كلمة المرور') {
          if (value != _passwordController.text) {
            return 'كلمة المرور غير متطابقة';
          }
        }
        if (obscureText && hint == 'كلمة المرور') {
          if (value.length < 6) {
            return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
          }
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

  Widget _buildContinueButton(bool isLoading) {
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
            onTap: isLoading ? null : _handleSignUp,
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

  Widget _buildLoginLink(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
      },
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: context.text.bodyMedium,
          children: [
            const TextSpan(text: 'لديك حساب بالفعل؟ '),
            TextSpan(
              text: 'تسجيل الدخول',
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
