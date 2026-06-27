import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../config/routes/app_routes.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/app_layout_primitives.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/image_source_picker_sheet.dart';
import '../../data/attachment_store.dart';

class IdVerificationPage extends StatefulWidget {
  const IdVerificationPage({super.key});

  @override
  State<IdVerificationPage> createState() => _IdVerificationPageState();
}

class _IdVerificationPageState extends State<IdVerificationPage> {
  final ImagePicker _picker = ImagePicker();
  String? _frontPath;
  String? _backPath;

  Future<void> _pickFront() async {
    final XFile? file = await pickImageWithSourceChoice(
      context,
      _picker,
      title: 'الوجه الأمامي للبطاقة',
      preferredCameraDevice: CameraDevice.rear,
    );
    if (file != null) {
      setState(() {
        _frontPath = file.path;
        AttachmentStore.idFrontPath = file.path;
      });
    }
  }

  Future<void> _pickBack() async {
    final XFile? file = await pickImageWithSourceChoice(
      context,
      _picker,
      title: 'الوجه الخلفي للبطاقة',
      preferredCameraDevice: CameraDevice.rear,
    );
    if (file != null) {
      setState(() {
        _backPath = file.path;
        AttachmentStore.idBackPath = file.path;
      });
    }
  }

  bool get _canContinue => _frontPath != null && _backPath != null;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Column(
          children: [
            AppPageHeader(
              title: 'صور الهوية',
              subtitle: 'الخطوة 1 من 2',
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Transform.translate(
                  offset: const Offset(0, -AppSpacing.md),
                  child: AppFormCard(
                    title: 'بطاقة الرقم القومي',
                    subtitle:
                        'التقط صورة أو اختر من المعرض للوجهين الأمامي والخلفي',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _IdCaptureCard(
                                label: 'الوجه الأمامي',
                                icon: Icons.credit_card_outlined,
                                imagePath: _frontPath,
                                onTap: _pickFront,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: _IdCaptureCard(
                                label: 'الوجه الخلفي',
                                icon: Icons.flip_to_back_outlined,
                                imagePath: _backPath,
                                onTap: _pickBack,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: context.colors.primary
                                .withValues(alpha: 0.08),
                            borderRadius:
                                BorderRadius.circular(AppRadius.lg),
                            border: Border.all(
                              color: context.colors.primary
                                  .withValues(alpha: 0.18),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.lightbulb_outline_rounded,
                                size: 20,
                                color: context.colors.primary,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Expanded(
                                child: Text(
                                  'تأكد من وضوح الصورة وإضاءة جيدة',
                                  style: context.text.bodySmall?.copyWith(
                                    color: context.colors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        SizedBox(
                          height: 52,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.xl),
                              gradient: _canContinue
                                  ? context.primaryGradient
                                  : null,
                              color: _canContinue
                                  ? null
                                  : context.semantic.borderStrong,
                              boxShadow: _canContinue
                                  ? [
                                      BoxShadow(
                                        color: context.colors.primary
                                            .withValues(alpha: 0.35),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.xl),
                                onTap: _canContinue
                                    ? () {
                                        Navigator.of(context).pushNamed(
                                          AppRoutes.selfieCapture,
                                        );
                                      }
                                    : null,
                                child: Center(
                                  child: Text(
                                    'المتابعة',
                                    style: context.text.titleMedium?.copyWith(
                                      color: context.semantic.textOnPrimary
                                          .withValues(
                                        alpha: _canContinue ? 1.0 : 0.6,
                                      ),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IdCaptureCard extends StatelessWidget {
  const _IdCaptureCard({
    required this.label,
    required this.icon,
    required this.onTap,
    this.imagePath,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          height: 140,
          decoration: BoxDecoration(
            color: context.semantic.surfaceInput,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: hasImage
                  ? context.colors.primary
                  : context.semantic.borderSubtle,
              width: hasImage ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!hasImage) ...[
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: context.colors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: context.colors.primary, size: 24),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: context.text.bodySmall?.copyWith(
                    color: context.semantic.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ] else ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: Image.file(
                    File(imagePath!),
                    width: 100,
                    height: 72,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 16,
                      color: context.semantic.success,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'تمت إضافة الصورة',
                      style: context.text.labelSmall?.copyWith(
                        color: context.semantic.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
