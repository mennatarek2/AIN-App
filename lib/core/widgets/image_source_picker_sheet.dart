import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/theme_extensions.dart';

Future<ImageSource?> showImageSourcePickerSheet(
  BuildContext context, {
  required String title,
}) {
  return showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: sheetContext.semantic.borderStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                title,
                textAlign: TextAlign.center,
                style: sheetContext.text.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _ImageSourceOption(
                icon: Icons.camera_alt_outlined,
                label: 'التقاط صورة',
                onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
              ),
              const SizedBox(height: AppSpacing.xs),
              _ImageSourceOption(
                icon: Icons.photo_library_outlined,
                label: 'اختيار من المعرض',
                onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<XFile?> pickImageWithSourceChoice(
  BuildContext context,
  ImagePicker picker, {
  required String title,
  CameraDevice preferredCameraDevice = CameraDevice.rear,
  int imageQuality = 85,
}) async {
  final source = await showImageSourcePickerSheet(context, title: title);
  if (source == null || !context.mounted) {
    return null;
  }

  return picker.pickImage(
    source: source,
    preferredCameraDevice: preferredCameraDevice,
    imageQuality: imageQuality,
  );
}

class _ImageSourceOption extends StatelessWidget {
  const _ImageSourceOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.semantic.surfaceInput,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 2,
          ),
          child: Row(
            children: [
              Icon(icon, color: context.colors.primary, size: 24),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  style: context.text.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_left_rounded,
                color: context.semantic.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
