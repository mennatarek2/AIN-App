import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/sos_badge_provider.dart';

class BottomNavBar extends ConsumerWidget {
  const BottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
    this.onReportTap,
  });

  final int selectedIndex;
  final ValueChanged<int> onTap;

  /// Called when the central Report FAB is tapped.
  /// If null, tapping Report falls through to [onTap] with index 2.
  final VoidCallback? onReportTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sosBadge = ref.watch(sosBadgeCountProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navBg = isDark ? const Color(0xFF0D1230) : Colors.white;
    final unselected =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final selected = AppColors.primary;

    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: navBg,
        border: Border(
          top: BorderSide(
            color: isDark
                ? const Color(0xFF1E2D6B).withValues(alpha: 0.6)
                : const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Tab 0 — Home
          _NavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
            label: 'بيت',
            isSelected: selectedIndex == 0,
            selectedColor: selected,
            unselectedColor: unselected,
            onTap: () => onTap(0),
          ),
          // Tab 1 — Communities
          _NavItem(
            icon: Icons.group_outlined,
            activeIcon: Icons.group_rounded,
            label: 'مجتمعاتي',
            isSelected: selectedIndex == 1,
            selectedColor: selected,
            unselectedColor: unselected,
            onTap: () => onTap(1),
          ),
          // Tab 2 — Report (central FAB)
          _ReportFab(
            onTap: onReportTap ?? () => onTap(2),
            isDark: isDark,
          ),
          // Tab 3 — SOS
          _SosNavItem(
            isSelected: selectedIndex == 3,
            selectedColor: selected,
            unselectedColor: unselected,
            badgeCount: sosBadge,
            onTap: () => onTap(3),
          ),
          // Tab 4 — Profile
          _NavItem(
            icon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded,
            label: 'حسابي',
            isSelected: selectedIndex == 4,
            selectedColor: selected,
            unselectedColor: unselected,
            onTap: () => onTap(4),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Simple nav item
// ---------------------------------------------------------------------------
class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.selectedColor,
    required this.unselectedColor,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final Color selectedColor;
  final Color unselectedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? selectedColor : unselectedColor;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isSelected ? activeIcon : icon,
                key: ValueKey(isSelected),
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Central Report FAB
// ---------------------------------------------------------------------------
class _ReportFab extends StatelessWidget {
  const _ReportFab({required this.onTap, required this.isDark});

  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.primaryDark],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.40),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SOS nav item with badge
// ---------------------------------------------------------------------------
class _SosNavItem extends StatelessWidget {
  const _SosNavItem({
    required this.isSelected,
    required this.selectedColor,
    required this.unselectedColor,
    required this.badgeCount,
    required this.onTap,
  });

  final bool isSelected;
  final Color selectedColor;
  final Color unselectedColor;
  final int badgeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? selectedColor : unselectedColor;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    isSelected ? Icons.crisis_alert_rounded : Icons.sos_rounded,
                    key: ValueKey(isSelected),
                    color: color,
                    size: 24,
                  ),
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: -4,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white, width: 1.2),
                      ),
                      child: Text(
                        badgeCount > 99 ? '99+' : badgeCount.toString(),
                        style: const TextStyle(
                          fontSize: 9,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              'نجدة',
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
