import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/routes/app_routes.dart';
import '../../../../core/state/app_flow_provider.dart';

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
        'من عَيْنك يبدأ الحل',
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
          'منصة واحدة وشاملة تتيح لك الإبلاغ عن أي\n'
          'مشكلة أو ملاحظة تواجهها بسهولة، \n'
          'لضمان سلامة وأمان الجميع',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w400,
            height: 1.9,
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ),
      image: SizedBox(
        height: 360,
        child: Image.asset(
          'assets/images/onboarding1.png',
          width: double.infinity,
          fit: BoxFit.contain,
        ),
      ),
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
        'يصل بلاغك للجهات المختصّة',
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
          'بلاغك يصل مباشرةً إلى الجهات المختصة لضمان أعلى سرعة في الاستجابة وحل المشكلة، ويمكنك متابعة حالته خطوة بخطوة.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w400,
            height: 1.7,
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ),
      image: SizedBox(
        height: 360,
        child: Image.asset(
          'assets/images/onboarding2.png',
          width: double.infinity,
          fit: BoxFit.contain,
        ),
      ),
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
        'مساعد ذكي',
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
          'مساعد ذكي موجود دائما للرد على استفساراتك وتقديم الإرشادات اللي تحتاجها في أي وقت',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w400,
            height: 1.7,
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ),
      image: SizedBox(
        height: 360,
        child: Image.asset(
          'assets/images/onboarding3.png',
          width: double.infinity,
          fit: BoxFit.contain,
        ),
      ),
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
      image: SizedBox(
        height: 360,
        child: Image.asset(
          'assets/images/onboarding4.png',
          width: double.infinity,
          fit: BoxFit.contain,
        ),
      ),
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
          fontSize: 34,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onBackground,
          height: 1.4,
        ),
      ),
      bodyWidget: Padding(
        padding: const EdgeInsets.only(left: 8, right: 8),
        child: Text(
          'عَيْن  هو أداة التواصل الفعّالة بينك وبين الجهات المسؤولة ، ووجهتُك للإبلاغ عن المشكلات بدقة وبخطوات بسيطة.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w400,
            height: 1.7,
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ),
      image: const SizedBox(height: 24),
      decoration: const PageDecoration(
        imagePadding: EdgeInsets.only(top: 222, bottom: 24),
        titlePadding: EdgeInsets.only(top: 16, bottom: 12),
        contentMargin: EdgeInsets.symmetric(horizontal: 24),
        imageFlex: 0,
        bodyFlex: 2,
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
    final colorScheme = theme.colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: IntroductionScreen(
                  key: _introKey,
                  globalBackgroundColor: theme.scaffoldBackgroundColor,
                  pages: _pages,
                  onChange: (index) => setState(() => _currentPage = index),
                  freeze: true,
                  isProgressTap: false,
                  scrollPhysics: const NeverScrollableScrollPhysics(),
                  showBackButton: false,
                  showNextButton: false,
                  showDoneButton: false,
                  showSkipButton: false,
                  globalHeader: _currentPage == _pages.length - 1
                      ? const SizedBox.shrink()
                      : Align(
                          alignment: Alignment.topRight,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 24, right: 24),
                            child: InkWell(
                              onTap: () {
                                _introKey.currentState?.skipToEnd();
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.arrow_back_ios_rounded,
                                    size: 20,
                                    color: colorScheme.outline,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'تخطي',
                                    style: TextStyle(
                                      color: colorScheme.outline,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 20,
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
                    color: colorScheme.outlineVariant,
                    activeColor: colorScheme.primary,
                    activeShape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  controlsMargin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  controlsPadding: const EdgeInsets.all(0),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 62,
                  vertical: 10,
                ),
                child: _currentPage == _pages.length - 1
                    ? _WelcomeButtons(onSignUp: _onSignUp, onLogin: _onLogin)
                    : _NextButton(onPressed: _onNextPressed),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NextButton extends StatelessWidget {
  const _NextButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      height: 56,
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
            child: const Center(
              child: Text(
                'التالي',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 21,
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
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // إنشاء حساب جديد - gradient
        SizedBox(
          width: double.infinity,
          height: 56,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [colorScheme.secondary, colorScheme.primary],
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onSignUp,
                child: const Center(
                  child: Text(
                    'إنشاء حساب جديد',
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
        ),
        const SizedBox(height: 16),
        // تسجيل الدخول - outline
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: onLogin,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: colorScheme.onBackground, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              foregroundColor: colorScheme.onBackground,
            ),
            child: const Text(
              'تسجيل الدخول',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 21),
            ),
          ),
        ),
      ],
    );
  }
}
