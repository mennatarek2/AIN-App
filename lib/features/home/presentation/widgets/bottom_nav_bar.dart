import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
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
    final semantic = context.semantic;
    final unselected = context.semantic.textMuted;
    final selected = context.colors.primary;

    return Container(
      height: 76,
      decoration: BoxDecoration(
        color: semantic.surfaceNavBar,
        border: Border(
          top: BorderSide(
            color: semantic.borderSubtle.withValues(alpha: 0.6),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: semantic.shadow,
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
            label: 'بيت',
            isSelected: selectedIndex == 0,
            selectedColor: selected,
            unselectedColor: unselected,
            onTap: () => onTap(0),
          ),
          _NavItem(
            icon: Icons.group_outlined,
            activeIcon: Icons.group_rounded,
            label: 'مجتمعاتي',
            isSelected: selectedIndex == 1,
            selectedColor: selected,
            unselectedColor: unselected,
            onTap: () => onTap(1),
          ),
          _ReportFab(onTap: onReportTap ?? () => onTap(2)),
          _SosNavItem(
            isSelected: selectedIndex == 3,
            selectedColor: selected,
            unselectedColor: unselected,
            badgeCount: sosBadge,
            onTap: () => onTap(3),
          ),
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
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isSelected
                    ? selectedColor.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  isSelected ? activeIcon : icon,
                  key: ValueKey(isSelected),
                  color: color,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportFab extends StatefulWidget {
  const _ReportFab({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_ReportFab> createState() => _ReportFabState();
}

class _ReportFabState extends State<_ReportFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseScale;
  late final Animation<double> _pulseOpacity;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _pulseScale = Tween<double>(begin: 1.0, end: 1.35).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
    _pulseOpacity = Tween<double>(begin: 0.35, end: 0.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: 64,
        height: 64,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseScale.value,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.colors.primary.withValues(
                        alpha: _pulseOpacity.value,
                      ),
                    ),
                  ),
                );
              },
            ),
            Transform.translate(
              offset: const Offset(0, -6),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: context.headerGradient,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: context.semantic.textOnPrimary.withValues(
                      alpha: 0.25,
                    ),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: context.colors.primary.withValues(alpha: 0.45),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.add_rounded,
                  color: context.semantic.textOnPrimary,
                  size: 30,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? selectedColor.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      isSelected
                          ? Icons.crisis_alert_rounded
                          : Icons.sos_rounded,
                      key: ValueKey(isSelected),
                      color: color,
                      size: 24,
                    ),
                  ),
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: -2,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: context.semantic.sos,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(
                          color: context.semantic.textOnPrimary,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        badgeCount > 99 ? '99+' : badgeCount.toString(),
                        style: TextStyle(
                          fontSize: 9,
                          color: context.semantic.textOnPrimary,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'نجدة',
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
