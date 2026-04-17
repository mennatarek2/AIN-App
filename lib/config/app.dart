import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/theme_mode_provider.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/sign_up_page.dart';
import '../features/auth/presentation/pages/forgot_password_page.dart';
import '../features/auth/presentation/pages/email_verification_page.dart';
import '../features/auth/presentation/pages/email_verification_success_page.dart';
import '../features/auth/presentation/pages/reset_password_page.dart';
import '../features/auth/presentation/pages/password_changed_success_page.dart';
import '../features/auth/presentation/pages/id_verification_page.dart';
import '../features/auth/presentation/pages/id_verification_intro_page.dart';
import '../features/auth/presentation/pages/selfie_capture_page.dart';
import '../features/auth/presentation/pages/verification_progress_page.dart';
import '../features/auth/presentation/pages/verification_success_page.dart';
import '../features/community/presentation/pages/community_page.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/my_reports/presentation/pages/my_reports_page.dart';
import '../features/notifications/presentation/pages/notifications_page.dart';
import '../features/onboarding/presentation/pages/onboarding_page.dart';
import '../features/reports/presentation/providers/report_sync_provider.dart';
import '../features/splash/presentation/pages/splash_page.dart';
import 'routes/app_routes.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(reportSyncBootstrapProvider);
    final themeMode = ref.watch(appSettingsProvider).themeMode;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ai-N',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash: (_) => const SplashPage(),
        AppRoutes.onboarding: (_) => const OnboardingPage(),
        AppRoutes.signUp: (_) => const SignUpPage(),
        AppRoutes.login: (_) => const LoginPage(),
        AppRoutes.forgotPassword: (_) => const ForgotPasswordPage(),
        AppRoutes.emailVerification: (_) => const EmailVerificationPage(),
        AppRoutes.emailVerificationSuccess: (_) =>
            const EmailVerificationSuccessPage(),
        AppRoutes.resetPassword: (_) => const ResetPasswordPage(),
        AppRoutes.passwordChanged: (_) => const PasswordChangedSuccessPage(),
        AppRoutes.idVerification: (_) => const IdVerificationPage(),
        AppRoutes.idVerificationIntro: (_) => const IdVerificationIntroPage(),
        AppRoutes.selfieCapture: (_) => const SelfieCapturePage(),
        AppRoutes.verificationProgress: (_) => const VerificationProgressPage(),
        AppRoutes.verificationSuccess: (_) => const VerificationSuccessPage(),
        AppRoutes.home: (_) => const HomePage(),
        AppRoutes.myReports: (_) => const MyReportsPage(),
        AppRoutes.community: (_) => const CommunityPage(),
        AppRoutes.notifications: (_) => const NotificationsPage(),
      },
    );
  }
}
