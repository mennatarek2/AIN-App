import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/theme_extensions.dart';

/// Loading, empty, and error states with consistent styling.
class AppLoadingView extends StatelessWidget {
  const AppLoadingView({super.key, this.message = 'جاري التحميل...'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: context.colors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            textDirection: TextDirection.rtl,
            style: context.text.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class AppEmptyView extends StatelessWidget {
  const AppEmptyView({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: context.colors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: context.colors.primary),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: context.text.titleMedium,
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
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(160, 44),
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AppErrorView extends StatelessWidget {
  const AppErrorView({
    super.key,
    required this.message,
    this.onRetry,
    this.retryLabel = 'إعادة المحاولة',
  });

  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: context.semantic.error,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: context.text.titleMedium,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.md),
              TextButton.icon(
                onPressed: onRetry,
                icon: Icon(Icons.refresh_rounded, color: context.colors.primary),
                label: Text(
                  retryLabel,
                  style: TextStyle(color: context.colors.primary),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Animated theme mode toggle pill for settings.
class AppThemeModeToggle extends StatelessWidget {
  const AppThemeModeToggle({
    super.key,
    required this.isDarkMode,
    required this.onChanged,
  });

  final bool isDarkMode;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: isDarkMode ? 'الوضع الداكن مفعّل' : 'الوضع الفاتح مفعّل',
      toggled: isDarkMode,
      child: GestureDetector(
        onTap: () => onChanged(!isDarkMode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: 96,
          height: 38,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: isDarkMode
                ? context.colors.primary
                : context.semantic.borderStrong,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: context.semantic.borderSubtle),
          ),
          child: Stack(
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                alignment: isDarkMode
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: context.semantic.textOnPrimary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: context.semantic.shadow,
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Icon(
                    isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    size: 18,
                    color: isDarkMode
                        ? context.colors.primary
                        : context.semantic.warning,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Settings section with grouped tiles — RTL-first layout.
class AppSettingsSection extends StatelessWidget {
  const AppSettingsSection({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.xxs, bottom: AppSpacing.xs),
          child: Text(
            title,
            textDirection: TextDirection.rtl,
            style: context.text.labelMedium,
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: context.semantic.surfaceContainer,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: context.semantic.borderSubtle),
            boxShadow: context.cardShadows,
          ),
          child: Column(
            children: [
              for (int i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1)
                  Divider(
                    height: 1,
                    indent: 52,
                    endIndent: AppSpacing.md,
                    color: context.semantic.divider,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class AppSettingsTile extends StatelessWidget {
  const AppSettingsTile({
    super.key,
    required this.icon,
    required this.label,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.iconColor,
    this.labelColor,
    this.showChevron = true,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? iconColor;
  final Color? labelColor;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? context.colors.onSurface;
    final effectiveLabelColor = labelColor ?? context.colors.onSurface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.listItemVertical,
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: effectiveIconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, color: effectiveIconColor, size: 20),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      textDirection: TextDirection.rtl,
                      style: context.text.titleSmall?.copyWith(
                        color: effectiveLabelColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        textDirection: TextDirection.rtl,
                        style: context.text.bodySmall,
                      ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
              if (showChevron && trailing == null)
                Icon(
                  Icons.chevron_left_rounded,
                  color: context.semantic.textMuted.withValues(alpha: 0.5),
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Coming-soon badge for future customization options.
class AppComingSoonBadge extends StatelessWidget {
  const AppComingSoonBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: context.semantic.infoContainer,
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Text(
        'قريباً',
        style: context.text.labelSmall?.copyWith(
          color: context.semantic.info,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
