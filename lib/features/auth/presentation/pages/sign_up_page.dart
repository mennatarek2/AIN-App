import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/routes/app_routes.dart';
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
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final notifier = ref.read(authNotifierProvider.notifier);
    final success = await notifier.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      name: _nameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
    );

    if (success && mounted) {
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.emailVerification,
        arguments: EmailVerificationArgs(
          nextRoute: AppRoutes.idVerificationIntro,
          email: _emailController.text.trim(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to auth state changes
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.failure.message),
            backgroundColor: Colors.red,
          ),
        );
        // Clear error after showing
        Future.microtask(
          () => ref.read(authNotifierProvider.notifier).clearError(),
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
                _buildBlueHeader(context),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildForm(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBlueHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 168,
      child: Stack(
        children: [
          ClipPath(
            clipper: _CurvedBottomHeaderClipper(),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [colorScheme.primary, colorScheme.secondary],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                'إنشاء حساب جديد',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState is AuthLoading;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 28),
          _buildInput(
            hint: 'اسم المستخدم',
            textInputAction: TextInputAction.next,
            controller: _nameController,
            enabled: !isLoading,
          ),
          const SizedBox(height: 16),
          _buildInput(
            hint: 'البريد الإلكتروني',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            controller: _emailController,
            enabled: !isLoading,
          ),
          const SizedBox(height: 16),
          _buildInput(
            hint: 'رقم الهاتف المحمول',
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            controller: _phoneController,
            enabled: !isLoading,
          ),
          const SizedBox(height: 16),
          _buildInput(
            hint: 'رقم الهوية الشخصية',
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            enabled: !isLoading,
          ),
          const SizedBox(height: 16),
          _buildInput(
            hint: 'كلمة المرور',
            obscureText: true,
            textInputAction: TextInputAction.next,
            controller: _passwordController,
            enabled: !isLoading,
          ),
          const SizedBox(height: 16),
          _buildInput(
            hint: 'تأكيد كلمة المرور',
            obscureText: true,
            textInputAction: TextInputAction.done,
            controller: _confirmPasswordController,
            enabled: !isLoading,
          ),
          const SizedBox(height: 32),
          _buildContinueButton(context, isLoading),
          const SizedBox(height: 28),
          _buildDividerWithOr(context),
          const SizedBox(height: 28),
          _buildGoogleButton(context),
          const SizedBox(height: 40),
          _buildLoginLink(context),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildInput({
    required String hint,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    bool obscureText = false,
    TextEditingController? controller,
    bool enabled = true,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextFormField(
      controller: controller,
      enabled: enabled,
      textAlign: TextAlign.right,
      textDirection: TextDirection.rtl,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      style: TextStyle(color: colorScheme.onBackground),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'هذا الحقل مطلوب';
        }
        if (keyboardType == TextInputType.emailAddress) {
          if (!value.contains('@')) {
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
        hintStyle: TextStyle(
          color: colorScheme.outline,
          fontSize: 18,
          fontWeight: FontWeight.w400,
        ),
        filled: true,
        fillColor: colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
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

  Widget _buildContinueButton(BuildContext context, bool isLoading) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [colorScheme.primary, colorScheme.secondary],
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: isLoading ? null : _handleSignUp,
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
                      'المتابعة',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 21,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDividerWithOr(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(child: Container(height: 1, color: colorScheme.outline)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'أو',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.outline,
              fontSize: 18,
            ),
          ),
        ),
        Expanded(child: Container(height: 1, color: colorScheme.outline)),
      ],
    );
  }

  Widget _buildGoogleButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 56,
      child: OutlinedButton(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          backgroundColor: colorScheme.surface,
          side: BorderSide(color: colorScheme.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          foregroundColor: colorScheme.onSurface,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/googleIcon.png',
              width: 24,
              height: 24,
              errorBuilder: (_, __, ___) => Icon(
                Icons.g_mobiledata_rounded,
                size: 28,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'الاستمرار باستخدام جوجل',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginLink(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).pushReplacementNamed(AppRoutes.login);
        },
        child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.outline,
              fontSize: 18,
            ),
            children: [
              const TextSpan(text: 'لديك حساب بالفعل؟ '),
              TextSpan(
                text: 'تسجيل الدخول',
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// الهيدر بحافة سفلية منحنية بسلاسة عند الزاوية اليسرى السفلية فقط.
class _CurvedBottomHeaderClipper extends CustomClipper<Path> {
  static const double _radius = 36;

  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(_radius, size.height);
    path.quadraticBezierTo(0, size.height, 0, size.height - _radius);
    path.lineTo(0, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
