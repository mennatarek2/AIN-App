import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/routes/app_routes.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/app_layout_primitives.dart';
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
                    child: Column(
                      children: [
                        const CheckmarkSuccessAnimation(size: 180),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'تم التحقق من هويتك بنجاح',
                          textAlign: TextAlign.center,
                          style: context.text.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'تم إنشاء حسابك بنجاح، مرحباً بك في عين',
                          textAlign: TextAlign.center,
                          style: context.text.bodyMedium?.copyWith(
                            color: context.semantic.textMuted,
                          ),
                        ),
                        if (_isCompleting) ...[
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: context.colors.primary,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                'جاري استكمال إنشاء الحساب...',
                                style: context.text.bodySmall?.copyWith(
                                  color: context.semantic.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (_errorMessage != null) ...[
                          const SizedBox(height: AppSpacing.md),
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: context.semantic.error
                                  .withValues(alpha: 0.1),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.lg),
                              border: Border.all(
                                color: context.semantic.error
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: context.text.bodySmall?.copyWith(
                                color: context.semantic.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.xl),
                        SizedBox(
                          width: double.infinity,
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
                                onTap: _isCompleting
                                    ? null
                                    : () {
                                        if (_isComplete) {
                                          final route =
                                              (nextRoute != null &&
                                                      nextRoute.isNotEmpty)
                                                  ? nextRoute
                                                  : AppRoutes.home;
                                          Navigator.of(context)
                                              .pushReplacementNamed(route);
                                          return;
                                        }
                                        _completeSignup();
                                      },
                                child: Center(
                                  child: _isCompleting
                                      ? SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            color: context
                                                .semantic.textOnPrimary,
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : Text(
                                          _isComplete
                                              ? 'استمرار'
                                              : 'إعادة المحاولة',
                                          style: context.text.titleMedium
                                              ?.copyWith(
                                            color: context
                                                .semantic.textOnPrimary,
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
        AppSpacing.xxxl,
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
              Icons.verified_user_rounded,
              size: 36,
              color: context.semantic.textOnPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'مرحباً بك!',
            style: context.text.headlineMedium?.copyWith(
              color: context.semantic.textOnPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
