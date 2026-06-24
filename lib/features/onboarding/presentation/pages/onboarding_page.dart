import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/routes/app_routes.dart';
import '../../../../core/state/app_flow_provider.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/app_brand_logo.dart';
import '../../../../core/widgets/app_layout_primitives.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final GlobalKey<IntroductionScreenState> _introKey =
      GlobalKey<IntroductionScreenState>();

  int _currentPage = 0;

  late final List<PageViewModel> _pages = [
    // Onboarding 1
    PageViewModel(
      titleWidget: Text(
        'بلغ عن المشكلات',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onBackground,
          height: 1.4,
        ),
      ),
      bodyWidget: Padding(
        padding: const EdgeInsets.only(left: 8, right: 8),
        child: Text(
          'ساهم في جعل منطقتك أكثر أماناً من خلال الإبلاغ عن\n المشكلات العامة',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w400,
            height: 1.9,
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ),
      image: _OnboardingHeroImage(assetPath: 'assets/images/onboarding1.png'),
      decoration: const PageDecoration(
        imagePadding: EdgeInsets.only(top: 144, bottom: 24),
        titlePadding: EdgeInsets.only(top: 16, bottom: 12),
        contentMargin: EdgeInsets.symmetric(horizontal: 20),
        imageFlex: 4,
        bodyFlex: 2,
      ),
    ),
    // Onboarding 2
    PageViewModel(
      titleWidget: Text(
        'هوية مواطن موثقة',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onBackground,
          height: 1.4,
        ),
      ),
      bodyWidget: Padding(
        padding: const EdgeInsets.only(left: 8, right: 8),
        child: Text(
          'نظام نقاط الثقة يضمن مصداقية البلاغات وحماية المجتمع',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w400,
            height: 1.7,
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ),
      image: _OnboardingHeroImage(assetPath: 'assets/images/onboarding2.png'),
      decoration: const PageDecoration(
        imagePadding: EdgeInsets.only(top: 144, bottom: 24),
        titlePadding: EdgeInsets.only(top: 16, bottom: 12),
        contentMargin: EdgeInsets.symmetric(horizontal: 20),
        imageFlex: 4,
        bodyFlex: 2,
      ),
    ),
    // Onboarding 3
    PageViewModel(
      titleWidget: Text(
        'استغاثة فورية SOS',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onBackground,
          height: 1.4,
        ),
      ),
      bodyWidget: Padding(
        padding: const EdgeInsets.only(left: 8, right: 8),
        child: Text(
          'اطلب المساعدة في حالات الطوارئ وشارك موقعك مع\n مجتمعك الموثوق',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w400,
            height: 1.7,
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ),
      image: _OnboardingHeroImage(assetPath: 'assets/images/onboarding3.png'),
      decoration: const PageDecoration(
        imagePadding: EdgeInsets.only(top: 144, bottom: 24),
        titlePadding: EdgeInsets.only(top: 16, bottom: 12),
        contentMargin: EdgeInsets.symmetric(horizontal: 20),
        imageFlex: 4,
        bodyFlex: 2,
      ),
    ),
    // Onboarding 4
    PageViewModel(
      titleWidget: Text(
        'ابقَ على اتصال، كن مطمئناً',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onBackground,
          height: 1.4,
        ),
      ),
      bodyWidget: Padding(
        padding: const EdgeInsets.only(left: 8, right: 8),
        child: Text(
          'تابع آخر موقع لأفراد عائلتك وأصدقائك لتكن مطمئناً تماماً على مكانهم وسلامتهم في كل الأوقات',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w400,
            height: 1.7,
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ),
      image: _OnboardingHeroImage(assetPath: 'assets/images/onboarding4.png'),
      decoration: const PageDecoration(
        imagePadding: EdgeInsets.only(top: 144, bottom: 24),
        titlePadding: EdgeInsets.only(top: 16, bottom: 12),
        contentMargin: EdgeInsets.symmetric(horizontal: 20),
        imageFlex: 4,
        bodyFlex: 2,
      ),
    ),
    // Onboarding 5 - Welcome (مرحبًا بك في عَيْن)
    PageViewModel(
      titleWidget: Text(
        'مرحبًا بك في عَيْن',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onBackground,
          height: 1.35,
        ),
      ),
      bodyWidget: Padding(
        padding: const EdgeInsets.only(left: 8, right: 8),
        child: Text(
          'عَيْن  هو أداة التواصل الفعّالة بينك وبين الجهات المسؤولة ، ووجهتُك للإبلاغ عن المشكلات بدقة وبخطوات بسيطة.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            height: 1.6,
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ),
      image: const AppBrandLogo(compact: true),
      decoration: const PageDecoration(
        imagePadding: EdgeInsets.only(top: 32, bottom: 8),
        titlePadding: EdgeInsets.only(top: 4, bottom: 6),
        contentMargin: EdgeInsets.symmetric(horizontal: 20),
        imageFlex: 1,
        bodyFlex: 1,
      ),
    ),
  ];

  void _onNextPressed() {
    final lastPageIndex = _pages.length - 1;
    if (_currentPage >= lastPageIndex) {
      _onDone();
    } else {
      _introKey.currentState?.next();
    }
  }

  void _onDone() {
    ref.read(appFlowProvider.notifier).completeOnboarding();
    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
  }

  void _onSignUp() {
    ref.read(appFlowProvider.notifier).completeOnboarding();
    Navigator.of(context).pushReplacementNamed(AppRoutes.signUp);
  }

  void _onLogin() {
    ref.read(appFlowProvider.notifier).completeOnboarding();
    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Column(
          children: [
            if (_currentPage != _pages.length - 1)
              Container(
                width: double.infinity,
                height: 6,
                decoration: BoxDecoration(gradient: context.heroGradient),
              ),
            Expanded(
              child: SafeArea(
                top: _currentPage == _pages.length - 1,
                child: IntroductionScreen(
                  key: _introKey,
                  globalBackgroundColor: theme.scaffoldBackgroundColor,
                  pages: _pages,
                  onChange: (index) => setState(() => _currentPage = index),
                  freeze: true,
                  isProgressTap: false,
                  scrollPhysics: const ClampingScrollPhysics(),
                  showBackButton: false,
                  showNextButton: false,
                  showDoneButton: false,
                  showSkipButton: false,
                  globalHeader: _currentPage == _pages.length - 1
                      ? const SizedBox.shrink()
                      : Align(
                          alignment: Alignment.topRight,
                          child: Padding(
                            padding: const EdgeInsets.only(
                              top: AppSpacing.xl,
                              right: AppSpacing.xl,
                            ),
                            child: InkWell(
                              onTap: () {
                                _introKey.currentState?.skipToEnd();
                              },
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.arrow_back_ios_rounded,
                                    size: 20,
                                    color: context.semantic.textMuted,
                                  ),
                                  const SizedBox(width: AppSpacing.xxs),
                                  Text(
                                    'تخطي',
                                    style: context.text.titleSmall?.copyWith(
                                      color: context.semantic.textMuted,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                  customProgress: _currentPage == _pages.length - 1
                      ? const SizedBox.shrink()
                      : null,
                  dotsDecorator: DotsDecorator(
                    size: const Size(8, 8),
                    activeSize: const Size(16, 8),
                    color: context.semantic.borderSubtle,
                    activeColor: context.colors.primary,
                    activeShape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                    ),
                  ),
                  controlsMargin: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.md,
                  ),
                  controlsPadding: const EdgeInsets.all(0),
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.xxl,
                  AppSpacing.xs,
                  AppSpacing.xxl,
                  AppSpacing.sm + MediaQuery.of(context).padding.bottom,
                ),
                child: _currentPage == _pages.length - 1
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const AppTrustIndicators(),
                          const SizedBox(height: AppSpacing.xs),
                          _WelcomeButtons(
                            onSignUp: _onSignUp,
                            onLogin: _onLogin,
                          ),
                        ],
                      )
                    : _NextButton(onPressed: _onNextPressed),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingHeroImage extends StatelessWidget {
  const _OnboardingHeroImage({required this.assetPath});

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return Image.asset(assetPath, width: 700, height: 700, fit: BoxFit.contain);
  }
}

class _NextButton extends StatelessWidget {
  const _NextButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
          gradient: context.primaryGradient,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.md),
            onTap: onPressed,
            child: Center(
              child: Text(
                'التالي',
                style: context.text.titleMedium?.copyWith(
                  color: context.semantic.textOnPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomeButtons extends StatelessWidget {
  const _WelcomeButtons({required this.onSignUp, required this.onLogin});

  final VoidCallback onSignUp;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              gradient: context.primaryGradient,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.md),
                onTap: onSignUp,
                child: Center(
                  child: Text(
                    'إنشاء حساب جديد',
                    style: context.text.titleMedium?.copyWith(
                      color: context.semantic.textOnPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: onLogin,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: context.colors.onSurface, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              foregroundColor: context.colors.onSurface,
            ),
            child: Text(
              'تسجيل الدخول',
              style: context.text.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
