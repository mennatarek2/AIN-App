import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/routes/app_routes.dart';

class HomeNavigationNotifier extends StateNotifier<int> {
  HomeNavigationNotifier() : super(0);

  void setSelectedIndex(int index) {
    if (index == 2) return;
    state = index;
  }
}

final homeNavigationProvider =
    StateNotifierProvider<HomeNavigationNotifier, int>((ref) {
      return HomeNavigationNotifier();
    });

/// Maps tab index to named route (legacy deep links).
const Map<int, String> bottomNavRoutes = {
  0: AppRoutes.home,
  1: AppRoutes.community,
  3: AppRoutes.sos,
  4: AppRoutes.profile,
};

/// Switches the main shell tab, resetting to [MainShellPage] when needed.
void navigateFromBottomNav(
  BuildContext context,
  WidgetRef ref,
  int index,
) {
  if (index == 2) return;
  ref.read(homeNavigationProvider.notifier).setSelectedIndex(index);

  final current = ModalRoute.of(context)?.settings.name;
  if (current == AppRoutes.home) return;

  Navigator.of(context).pushNamedAndRemoveUntil(
    AppRoutes.home,
    (route) => false,
  );
}
