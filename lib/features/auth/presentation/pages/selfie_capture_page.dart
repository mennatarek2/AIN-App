import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../config/routes/app_routes.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/app_layout_primitives.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/image_source_picker_sheet.dart';
import '../../data/attachment_store.dart';
import '../notifiers/id_verification_notifier.dart';
import '../state/form_state_simple.dart' as auth_form;

class SelfieCapturePage extends ConsumerStatefulWidget {
  const SelfieCapturePage({super.key});

  @override
  ConsumerState<SelfieCapturePage> createState() => _SelfieCapturePageState();
}

class _SelfieCapturePageState extends ConsumerState<SelfieCapturePage> {
  final ImagePicker _picker = ImagePicker();
  String? _selfiePath;

  Future<void> _pickSelfie() async {
    final XFile? file = await pickImageWithSourceChoice(
      context,
      _picker,
      title: 'الصورة الشخصية',
      preferredCameraDevice: CameraDevice.front,
    );
    if (file != null) {
      setState(() {
        _selfiePath = file.path;
        AttachmentStore.selfiePath = file.path;
      });
    }
  }

  Future<void> _handleContinue() async {
    if (_selfiePath == null ||
        AttachmentStore.idFrontPath == null ||
        AttachmentStore.idBackPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('يرجى إكمال جميع الصور المطلوبة'),
          backgroundColor: context.semantic.error,
        ),
      );
      return;
    }

    final notifier = ref.read(idVerificationNotifierProvider.notifier);
    final success = await notifier.uploadIdDocuments(
      frontImagePath: AttachmentStore.idFrontPath!,
      backImagePath: AttachmentStore.idBackPath!,
      selfieImagePath: _selfiePath!,
    );

    if (success && mounted) {
      Navigator.of(
        context,
      ).pushReplacementNamed(AppRoutes.verificationProgress);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(idVerificationNotifierProvider);
    final isLoading = formState is auth_form.FormLoading;

    ref.listen<auth_form.FormState>(idVerificationNotifierProvider, (
      previous,
      next,
    ) {
      if (next is auth_form.FormError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.failure.message),
            backgroundColor: context.semantic.error,
          ),
        );
        Future.microtask(
          () => ref.read(idVerificationNotifierProvider.notifier).reset(),
        );
      }
    });

    final canContinue = _selfiePath != null && !isLoading;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Column(
          children: [
            AppPageHeader(
              title: 'الصورة الشخصية',
              subtitle: 'الخطوة 2 من 2',
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Transform.translate(
                  offset: const Offset(0, -AppSpacing.md),
                  child: AppFormCard(
                    title: 'أضف صورتك الشخصية',
                    subtitle: 'التقط صورة أو اختر من المعرض مع إضاءة جيدة',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        GestureDetector(
                          onTap: _pickSelfie,
                          child: Container(
                            height: 260,
                            decoration: BoxDecoration(
                              color: context.semantic.surfaceInput,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.xxl),
                              border: Border.all(
                                color: _selfiePath != null
                                    ? context.colors.primary
                                    : context.semantic.borderSubtle,
                                width: _selfiePath != null ? 2 : 1,
                              ),
                            ),
                            child: _selfiePath == null
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: context.primaryGradient,
                                          boxShadow: [
                                            BoxShadow(
                                              color: context.colors.primary
                                                  .withValues(alpha: 0.3),
                                              blurRadius: 16,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          Icons.camera_alt_outlined,
                                          color: context.semantic.textOnPrimary,
                                          size: 36,
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.md),
                                      Text(
                                        'اضغط لإضافة الصورة',
                                        style: context.text.bodyMedium
                                            ?.copyWith(
                                          color: context.semantic.textMuted,
                                        ),
                                      ),
                                    ],
                                  )
                                : Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: context.colors.primary,
                                              width: 3,
                                            ),
                                          ),
                                          child: ClipOval(
                                            child: Image.file(
                                              File(_selfiePath!),
                                              width: 180,
                                              height: 180,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: AppSpacing.sm),
                                        TextButton.icon(
                                          onPressed: _pickSelfie,
                                          icon: const Icon(
                                            Icons.refresh_rounded,
                                            size: 18,
                                          ),
                                          label: const Text('تغيير الصورة'),
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        SizedBox(
                          height: 52,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.xl),
                              gradient: canContinue
                                  ? context.primaryGradient
                                  : null,
                              color: canContinue
                                  ? null
                                  : context.semantic.borderStrong,
                              boxShadow: canContinue
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
                                onTap: canContinue ? _handleContinue : null,
                                child: Center(
                                  child: isLoading
                                      ? SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            color: context
                                                .semantic.textOnPrimary,
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : Text(
                                          'المتابعة',
                                          style: context.text.titleMedium
                                              ?.copyWith(
                                            color: context
                                                .semantic.textOnPrimary
                                                .withValues(
                                              alpha: canContinue ? 1.0 : 0.6,
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
