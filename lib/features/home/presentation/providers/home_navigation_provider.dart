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

const Map<int, String> _bottomNavRoutes = {
  0: AppRoutes.home,
  1: AppRoutes.myReports,
  2: AppRoutes.community,
  3: AppRoutes.notifications,
};

void navigateFromBottomNav(BuildContext context, int index) {
  final routeName = _bottomNavRoutes[index];
  if (routeName == null) return;

  Navigator.of(context).pushReplacementNamed(routeName);
}
