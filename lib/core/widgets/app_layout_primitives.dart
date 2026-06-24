import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/theme_extensions.dart';

/// Gradient dashboard header with optional search and trailing actions.
class AppDashboardHeader extends StatelessWidget {
  const AppDashboardHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.searchHint,
    this.searchController,
    this.onSearchChanged,
    this.trailing,
    this.bottom,
    this.compact = false,
  });

  final String title;
  final String? subtitle;
  final String? searchHint;
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;
  final List<Widget>? trailing;
  final Widget? bottom;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            context.semantic.headerGradientStart,
            context.semantic.headerGradientEnd,
          ],
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.xxl),
        ),
        boxShadow: [
          BoxShadow(
            color: context.semantic.shadow,
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.screenHorizontal,
          top + AppSpacing.sm,
          AppSpacing.screenHorizontal,
          compact ? AppSpacing.md : AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              textDirection: TextDirection.rtl,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        textDirection: TextDirection.rtl,
                        style: context.text.headlineSmall?.copyWith(
                          color: context.semantic.textOnPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          subtitle!,
                          textDirection: TextDirection.rtl,
                          style: context.text.bodySmall?.copyWith(
                            color: context.semantic.textOnPrimary.withValues(
                              alpha: 0.82,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...trailing!,
              ],
            ),
            if (searchHint != null && searchController != null) ...[
              const SizedBox(height: AppSpacing.md),
              _HeaderSearchField(
                hint: searchHint!,
                controller: searchController!,
                onChanged: onSearchChanged,
              ),
            ],
            if (bottom != null) ...[
              SizedBox(height: compact ? AppSpacing.sm : AppSpacing.md),
              bottom!,
            ],
          ],
        ),
      ),
    );
  }
}

class _HeaderSearchField extends StatelessWidget {
  const _HeaderSearchField({
    required this.hint,
    required this.controller,
    this.onChanged,
  });

  final String hint;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.semantic.surfaceContainer,
      elevation: 0,
      shadowColor: context.semantic.shadow,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textDirection: TextDirection.rtl,
        cursorColor: context.colors.primary,
        style: TextStyle(
          color: context.colors.onSurface,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintTextDirection: TextDirection.rtl,
          hintStyle: TextStyle(
            color: context.semantic.textMuted,
            fontSize: 15,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: context.colors.primary,
            size: 22,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            borderSide: BorderSide(color: context.colors.primary, width: 1.5),
          ),
          filled: true,
          fillColor: context.semantic.surfaceContainer,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

/// Horizontal quick-action chips for dashboards.
class AppQuickActionRow extends StatelessWidget {
  const AppQuickActionRow({super.key, required this.actions});

  final List<AppQuickAction> actions;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
        itemCount: actions.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final action = actions[index];
          return _QuickActionTile(action: action);
        },
      ),
    );
  }
}

class AppQuickAction {
  const AppQuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final bool isDestructive;
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.action});

  final AppQuickAction action;

  @override
  Widget build(BuildContext context) {
    final accent = action.color ??
        (action.isDestructive
            ? context.semantic.sos
            : context.colors.primary);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          width: 88,
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm,
            horizontal: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: context.semantic.surfaceContainer,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: context.semantic.borderSubtle),
            boxShadow: context.cardShadows,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(action.icon, color: accent, size: 22),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                action.label,
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.text.labelSmall?.copyWith(
                  color: context.colors.onSurface,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Section title with optional trailing action.
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.padding,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ??
          const EdgeInsets.fromLTRB(
            AppSpacing.screenHorizontal,
            AppSpacing.md,
            AppSpacing.screenHorizontal,
            AppSpacing.xs,
          ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Expanded(
            child: Text(
              title,
              textDirection: TextDirection.rtl,
              style: context.text.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                actionLabel!,
                style: TextStyle(
                  color: context.colors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Elevated form card for auth and onboarding flows.
class AppFormCard extends StatelessWidget {
  const AppFormCard({super.key, required this.child, this.title, this.subtitle});

  final Widget child;
  final String? title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: context.semantic.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: context.semantic.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: context.semantic.shadow,
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Text(
              title!,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: context.text.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle!,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
                style: context.text.bodySmall,
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
          ],
          child,
        ],
      ),
    );
  }
}

/// Trust indicator pills for auth/marketing surfaces.
class AppTrustIndicators extends StatelessWidget {
  const AppTrustIndicators({super.key});

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.verified_user_outlined, 'موثوق'),
      (Icons.shield_outlined, 'آمن'),
      (Icons.speed_outlined, 'سريع'),
    ];

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: [
        for (final item in items) _TrustPill(icon: item.$1, label: item.$2),
      ],
    );
  }
}

class _TrustPill extends StatelessWidget {
  const _TrustPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: context.colors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: context.colors.primary.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: context.colors.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: context.text.labelSmall?.copyWith(
              color: context.colors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Visual theme preview cards for settings.
class AppThemePreviewSelector extends StatelessWidget {
  const AppThemePreviewSelector({
    super.key,
    required this.isDarkMode,
    required this.onChanged,
  });

  final bool isDarkMode;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ThemePreviewCard(
            label: 'فاتح',
            isSelected: !isDarkMode,
            isDark: false,
            onTap: () => onChanged(false),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _ThemePreviewCard(
            label: 'داكن',
            isSelected: isDarkMode,
            isDark: true,
            onTap: () => onChanged(true),
          ),
        ),
      ],
    );
  }
}

class _ThemePreviewCard extends StatelessWidget {
  const _ThemePreviewCard({
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final accent = isDark ? AppColors.primarySoft : AppColors.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: context.semantic.surfaceContainer,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: isSelected
                  ? context.colors.primary
                  : context.semantic.borderSubtle,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Container(
                height: 64,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: context.semantic.borderSubtle),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        height: 20,
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: context.semantic.borderSubtle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isSelected)
                    Icon(Icons.check_circle_rounded,
                        size: 16, color: context.colors.primary),
                  if (isSelected) const SizedBox(width: 4),
                  Text(
                    label,
                    style: context.text.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? context.colors.primary
                          : context.colors.onSurface,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
