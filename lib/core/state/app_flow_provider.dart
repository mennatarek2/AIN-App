import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/routes/app_routes.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/state/auth_state_simple.dart';

class AppFlowState {
  const AppFlowState({required this.onboardingCompleted});

  final bool onboardingCompleted;

  AppFlowState copyWith({bool? onboardingCompleted}) {
    return AppFlowState(
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }
}

class AppFlowNotifier extends StateNotifier<AppFlowState> {
  AppFlowNotifier() : super(const AppFlowState(onboardingCompleted: false));

  void completeOnboarding() {
    state = state.copyWith(onboardingCompleted: true);
  }
}

final appFlowProvider = StateNotifierProvider<AppFlowNotifier, AppFlowState>((
  ref,
) {
  return AppFlowNotifier();
});

final appLaunchRouteProvider = Provider<String>((ref) {
  final authState = ref.watch(authNotifierProvider);
  final onboardingCompleted = ref.watch(appFlowProvider).onboardingCompleted;

  if (authState is AuthInitial || authState is AuthLoading) {
    return AppRoutes.splash;
  }

  if (authState is AuthAuthenticated) {
    return AppRoutes.home;
  }

  return onboardingCompleted ? AppRoutes.login : AppRoutes.onboarding;
});
