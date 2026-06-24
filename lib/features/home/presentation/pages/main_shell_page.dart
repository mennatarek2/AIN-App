import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../community/presentation/pages/community_page.dart';
import '../../../community/presentation/providers/communities_provider.dart';
import '../../../community/presentation/widgets/location_pending_banner.dart';
import '../../../home/presentation/pages/your_location_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../sos/presentation/pages/sos_page.dart';
import '../providers/home_navigation_provider.dart';
import '../widgets/bottom_nav_bar.dart';
import 'add_report_page.dart';
import 'home_page.dart';

/// Root authenticated shell: preserves tab state via [IndexedStack].
class MainShellPage extends ConsumerStatefulWidget {
  const MainShellPage({super.key});

  @override
  ConsumerState<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends ConsumerState<MainShellPage> {
  static int _stackIndex(int navIndex) {
    return switch (navIndex) {
      0 => 0,
      1 => 1,
      3 => 2,
      4 => 3,
      _ => 0,
    };
  }

  Future<void> _navigateToLocationSetup() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const YourLocationPage()),
    );
    if (!mounted) return;
    ref.read(communitiesProvider.notifier).onLocationShared();
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(homeNavigationProvider);

    // Drive the MaterialBanner imperatively from state changes.
    ref.listen<CommunitiesState>(communitiesProvider, (prev, next) {
      if (!mounted) return;
      if (next.showLocationBanner && prev?.showLocationBanner != true) {
        LocationPendingBanner.show(
          context,
          onSetLocation: _navigateToLocationSetup,
        );
      } else if (!next.showLocationBanner && prev?.showLocationBanner == true) {
        LocationPendingBanner.hide(context);
      }
    });

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: IndexedStack(
          index: _stackIndex(selectedIndex),
          children: const [
            HomePage(embeddedInShell: true),
            CommunityPage(embeddedInShell: true),
            SosPage(embeddedInShell: true),
            ProfilePage(embeddedInShell: true),
          ],
        ),
        bottomNavigationBar: BottomNavBar(
          selectedIndex: selectedIndex,
          onTap: (index) {
            if (index == 2) return;
            if (index == selectedIndex) return;
            ref.read(homeNavigationProvider.notifier).setSelectedIndex(index);
          },
          onReportTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const AddReportPage()),
            );
          },
        ),
      ),
    );
  }
}
