import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/routes/app_routes.dart';

class HomeNavigationNotifier extends StateNotifier<int> {
  HomeNavigationNotifier() : super(0);

  void setSelectedIndex(int index) {
    state = index;
  }
}

final homeNavigationProvider =
    StateNotifierProvider<HomeNavigationNotifier, int>((ref) {
      return HomeNavigationNotifier();
    });

/// Maps tab index to named route.
/// Index 2 (Report) is a special action — not in this map.
const Map<int, String> bottomNavRoutes = {
  0: AppRoutes.home,
  1: AppRoutes.community,
  3: AppRoutes.sos,
  4: AppRoutes.profile,
};

void navigateFromBottomNav(BuildContext context, int index) {
  final routeName = bottomNavRoutes[index];
  if (routeName == null) return;
  Navigator.of(context).pushReplacementNamed(routeName);
}
