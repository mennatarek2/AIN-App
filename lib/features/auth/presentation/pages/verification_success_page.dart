import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/routes/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/checkmark_success_animation.dart';
import '../providers/auth_provider.dart';
import 'email_verification_success_page.dart';

class VerificationSuccessPage extends ConsumerStatefulWidget {
  const VerificationSuccessPage({super.key});

  @override
  ConsumerState<VerificationSuccessPage> createState() =>
      _VerificationSuccessPageState();
}

class _VerificationSuccessPageState
    extends ConsumerState<VerificationSuccessPage> {
  bool _isCompleting = false;
  bool _isComplete = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _completeSignup();
      }
    });
  }

  Future<void> _completeSignup() async {
    setState(() {
      _isCompleting = true;
      _errorMessage = null;
    });

    final success = await ref
        .read(authNotifierProvider.notifier)
        .completeSignUp();

    if (!mounted) {
      return;
    }

    setState(() {
      _isCompleting = false;
      _isComplete = success;
      _errorMessage = success
          ? null
          : 'تعذر إكمال إنشاء الحساب، يرجى المحاولة مرة أخرى';
    });
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments
            as EmailVerificationSuccessArgs?;
    final nextRoute = args?.nextRoute;
    final colorScheme = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const SizedBox(height: 140),
                const CheckmarkSuccessAnimation(),
                const SizedBox(height: 52),
                Text(
                  'تم التحقق من البريد الإلكتروني بنجاح',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onBackground,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'يمكنك الآن استكمال إنشاء الحساب',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 17,
                    color: colorScheme.onBackground,
                  ),
                ),
                const SizedBox(height: 18),
                if (_isCompleting)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'جاري استكمال إنشاء الحساب...',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colorScheme.outline,
                        fontSize: 15,
                      ),
                    ),
                  ),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colorScheme.error,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const Spacer(),
                SizedBox(
                  width: 300,
                  height: 52,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [colorScheme.primary, colorScheme.secondary],
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: _isCompleting
                            ? null
                            : () {
                                if (_isComplete) {
                                  final route =
                                      (nextRoute != null &&
                                          nextRoute.isNotEmpty)
                                      ? nextRoute
                                      : AppRoutes.home;
                                  Navigator.of(
                                    context,
                                  ).pushReplacementNamed(route);
                                  return;
                                }
                                _completeSignup();
                              },
                        child: Center(
                          child: _isCompleting
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text(
                                  _isComplete ? 'استمرار' : 'إعادة المحاولة',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        color: colorScheme.onPrimary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 21,
                                      ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 88),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
