import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/theme_extensions.dart';

/// Consistent RTL page header with back navigation and optional actions.
class AppPageHeader extends StatelessWidget {
  const AppPageHeader({
    super.key,
    required this.title,
    this.onBack,
    this.actions,
    this.useGradient = true,
    this.subtitle,
  });

  final String title;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final bool useGradient;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
        padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        topPadding + AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        gradient: useGradient ? context.headerGradient : null,
        color: useGradient ? null : context.semantic.surfaceHeader,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.xxl),
        ),
        boxShadow: [
          BoxShadow(
            color: context.semantic.shadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  textDirection: TextDirection.rtl,
                  style: context.text.titleLarge?.copyWith(
                    color: context.semantic.textOnPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    subtitle!,
                    textDirection: TextDirection.rtl,
                    style: context.text.bodySmall?.copyWith(
                      color: context.semantic.textOnPrimary.withValues(
                        alpha: 0.85,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (actions != null) ...actions!,
          if (onBack != null)
            IconButton(
              onPressed: onBack,
              icon: Icon(
                Icons.arrow_forward_ios_rounded,
                color: context.semantic.textOnPrimary,
                size: 20,
              ),
              tooltip: 'رجوع',
            ),
        ],
      ),
    );
  }
}

/// Elevated surface card with consistent borders and shadows.
class AppSurfaceCard extends StatelessWidget {
  const AppSurfaceCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.margin,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: margin,
      padding: padding ?? const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: context.semantic.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.semantic.borderSubtle),
        boxShadow: context.cardShadows,
      ),
      child: child,
    );

    if (onTap == null) return card;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: card,
      ),
    );
  }
}
