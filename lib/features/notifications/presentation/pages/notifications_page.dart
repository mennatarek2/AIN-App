import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../home/presentation/providers/home_navigation_provider.dart';
import '../../../home/presentation/widgets/bottom_nav_bar.dart';
import '../providers/notifications_provider.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    ref.read(homeNavigationProvider.notifier).setSelectedIndex(3);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notificationsState = ref.watch(notificationsProvider);
    final todayItems = notificationsState.itemsForSection(
      NotificationSection.today,
    );
    final weekItems = notificationsState.itemsForSection(
      NotificationSection.thisWeek,
    );

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF060C3A)
          : AppColors.backgroundLight,
      body: Column(
        children: [
          const _Header(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              children: [
                _SectionTitle('اليوم'),
                const SizedBox(height: 8),
                ...todayItems.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _NotificationCard(
                      text: item.text,
                      highlighted: item.highlighted,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                _SectionTitle('هذا الأسبوع'),
                const SizedBox(height: 8),
                ...weekItems.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _NotificationCard(
                      text: item.text,
                      highlighted: item.highlighted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: ref.watch(homeNavigationProvider),
        onTap: (index) {
          if (index == 3) return;
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
    final titleColor = isDark
        ? const Color(0xFFF3F6F9)
        : AppColors.textPrimaryLight;

    return Container(
      width: double.infinity,
      height: 100,
      color: isDark ? const Color(0xFF121A5C) : AppColors.primarySoft,
      child: Align(
        alignment: Alignment(0, 0.32),
        child: Text(
          'الإشعارات',
          textDirection: TextDirection.rtl,
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w600,
            color: titleColor,
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        title,
        textDirection: TextDirection.rtl,
        style: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w400,
          color: isDark ? const Color(0xFFF3F6F9) : AppColors.textPrimaryLight,
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.text, this.highlighted = false});

  final String text;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: highlighted
            ? (isDark
                  ? const Color(0x3366C8FF)
                  : AppColors.primarySoft.withValues(alpha: 0.2))
            : (isDark ? const Color(0xFF060C3A) : Colors.white),
        borderRadius: BorderRadius.circular(10),
        border: highlighted
            ? null
            : Border.all(
                color: isDark
                    ? const Color(0xFFF3F6F9)
                    : const Color(0x66060C3A),
                width: 1,
              ),
      ),
      alignment: Alignment.centerRight,
      child: Text(
        text,
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w400,
          color: isDark ? const Color(0xFFF3F6F9) : AppColors.textPrimaryLight,
        ),
      ),
    );
  }
}
