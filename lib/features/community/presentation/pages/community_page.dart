import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../home/presentation/providers/home_navigation_provider.dart';
import '../providers/communities_provider.dart';
import 'community_info_page.dart';
import 'create_community_page.dart';
import '../../../home/presentation/widgets/bottom_nav_bar.dart';

class CommunityPage extends ConsumerStatefulWidget {
  const CommunityPage({super.key});

  @override
  ConsumerState<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends ConsumerState<CommunityPage> {
  @override
  void initState() {
    super.initState();
    ref.read(homeNavigationProvider.notifier).setSelectedIndex(2);
  }

  @override
  Widget build(BuildContext context) {
    final communities = ref.watch(filteredCommunitiesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          const _Header(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 76),
              child: ListView(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'المجتمعات الخاصة بي',
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontSize: 31 * 0.68,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...communities.map(
                    (community) => Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: _CommunityCard(
                        title: community.title,
                        membersPreview: community.membersPreview,
                        iconPath: community.iconPath,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CommunityInfoPage(
                                communityId: community.id,
                                communityName: community.title,
                                members: community.members,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _CreateGroupButton(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const CreateCommunityPage(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: ref.watch(homeNavigationProvider),
        onTap: (index) {
          if (index == 2) return;
          ref.read(homeNavigationProvider.notifier).setSelectedIndex(index);
          navigateFromBottomNav(context, index);
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;

    return Container(
      width: double.infinity,
      height: 100,
      color: isDark ? const Color(0xFF121A5C) : AppColors.primarySoft,
      child: Align(
        alignment: Alignment(0, 0.32),
        child: Text(
          'مجتمعي',
          textDirection: TextDirection.rtl,
          style: TextStyle(
            fontSize: 40 * 0.525,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

class _CommunityCard extends StatelessWidget {
  const _CommunityCard({
    required this.title,
    required this.membersPreview,
    required this.iconPath,
    required this.onTap,
  });

  final String title;
  final String membersPreview;
  final String iconPath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.backgroundDark : Colors.white;
    final borderColor = isDark
        ? AppColors.textPrimaryDark
        : const Color(0x66060C3A);
    final titleColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final membersColor = isDark
        ? AppColors.textPrimaryDark
        : const Color(0xB3060C3A);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 88,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              textDirection: TextDirection.rtl,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Image.asset(iconPath, width: 32, height: 32),
                const SizedBox(width: 4),
                Text(
                  title,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w400,
                    color: titleColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Text(
                membersPreview,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w400,
                  color: membersColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateGroupButton extends StatelessWidget {
  const _CreateGroupButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 203,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primary, AppColors.primarySoft],
          ),
        ),
        child: Text(
          'إنشاء مجموعة جديدة',
          textDirection: TextDirection.rtl,
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.backgroundLight,
          ),
        ),
      ),
    );
  }
}
