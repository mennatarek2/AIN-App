import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';

class ProfileStateBanner extends StatelessWidget {
  const ProfileStateBanner({
    super.key,
    required this.isLoading,
    this.errorText,
    this.onRetry,
  });

  final bool isLoading;
  final String? errorText;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (errorText != null && errorText!.trim().isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          0,
        ),
        child: Container(
          key: const ValueKey('profile_state_error_banner'),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: context.semantic.errorContainer,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: context.semantic.error.withValues(alpha: 0.3)),
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Icon(
                Icons.error_outline,
                color: context.semantic.error,
                size: 18,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  errorText!,
                  textDirection: TextDirection.rtl,
                  style: context.text.bodySmall?.copyWith(
                    color: context.semantic.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (onRetry != null)
                TextButton(
                  onPressed: onRetry,
                  child: Text(
                    'إعادة المحاولة',
                    style: TextStyle(color: context.colors.primary),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    if (isLoading) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          0,
        ),
        child: Container(
          key: const ValueKey('profile_state_loading_banner'),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: context.semantic.infoContainer,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: context.semantic.info.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: context.colors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'جاري تحديث بيانات الملف الشخصي...',
                  textDirection: TextDirection.rtl,
                  style: context.text.bodySmall?.copyWith(
                    color: context.semantic.info,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
