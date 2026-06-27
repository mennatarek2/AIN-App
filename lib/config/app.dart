import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/notifications/local_notification_service.dart';
import '../core/notifications/notification_bootstrap.dart';
import '../core/realtime/signalr_bridge.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_mode_provider.dart';
import '../features/auth/data/data_sources/user_local_data_source.dart';
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
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/auth/presentation/state/auth_state_simple.dart';
import '../features/chatbot/presentation/pages/chatbot_page.dart';
import '../features/community/presentation/pages/community_page.dart';
import '../features/home/presentation/pages/main_shell_page.dart';
import '../features/home/presentation/pages/map_page.dart';
import '../features/my_reports/presentation/pages/my_reports_page.dart';
import '../features/notifications/presentation/pages/notifications_page.dart';
import '../features/onboarding/presentation/pages/onboarding_page.dart';
import '../features/profile/presentation/pages/profile_page.dart';
import '../features/profile/presentation/pages/edit_password_page.dart';
import '../features/reports/presentation/pages/report_detail_page.dart';
import '../features/reports/presentation/providers/report_sync_provider.dart';
import '../features/sos/presentation/pages/sos_page.dart';
import '../features/splash/presentation/pages/splash_page.dart';
import 'routes/app_routes.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  @override
  void initState() {
    super.initState();
    // If already authenticated on cold start, connect SignalR.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeBootstrapSignalR();
    });
  }

  Future<void> _maybeBootstrapSignalR() async {
    final authState = ref.read(authNotifierProvider);
    if (authState is AuthAuthenticated) {
      final token = await UserLocalDataSource().getCachedToken();
      if (token != null && token.isNotEmpty) {
        await ref.read(signalRBridgeProvider).start(token: token);
      }
      await ref.read(notificationBootstrapProvider).onAuthenticated();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(reportSyncBootstrapProvider);
    ref.watch(notificationAuthListenerProvider);
    final themeMode = ref.watch(appSettingsProvider).themeMode;

    // Listen for auth state changes → start/stop SignalR automatically.
    ref.listen<AuthState>(authNotifierProvider, (previous, next) async {
      final bridge = ref.read(signalRBridgeProvider);
      if (next is AuthAuthenticated) {
        final token = await UserLocalDataSource().getCachedToken();
        if (token != null && token.isNotEmpty) {
          await bridge.start(token: token);
        }
      } else if (next is AuthUnauthenticated) {
        await bridge.stop();
      }
    });

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
      // Global navigator key — used by LocalNotificationService tap handler
      // and SOS background notification navigation.
      navigatorKey: appNavigatorKey,
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
        AppRoutes.home: (_) => const MainShellPage(),
        AppRoutes.map: (_) => const MapPage(),
        AppRoutes.myReports: (_) => const MyReportsPage(),
        AppRoutes.community: (_) => const CommunityPage(),
        AppRoutes.notifications: (_) => const NotificationsPage(),
        AppRoutes.profile: (_) => const ProfilePage(),
        AppRoutes.changePassword: (_) => const EditPasswordPage(),
        AppRoutes.sos: (_) => const SosPage(),
        AppRoutes.chatbot: (_) => const ChatbotPage(),
      },
      // Routes that require arguments cannot use the static routes table.
      onGenerateRoute: (settings) {
        if (settings.name == AppRoutes.reportDetail) {
          final reportId = settings.arguments as String?;
          if (reportId != null && reportId.isNotEmpty) {
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => ReportDetailPage(reportId: reportId),
            );
          }
        }
        return null;
      },
    );
  }
}
