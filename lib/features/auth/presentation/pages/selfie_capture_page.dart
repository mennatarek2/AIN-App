import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../config/routes/app_routes.dart';
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

  Future<void> _captureSelfie() async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 85,
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
        const SnackBar(
          content: Text('يرجى إكمال جميع الصور المطلوبة'),
          backgroundColor: Colors.red,
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
    final colorScheme = Theme.of(context).colorScheme;
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
            backgroundColor: Colors.red,
          ),
        );
        Future.microtask(
          () => ref.read(idVerificationNotifierProvider.notifier).reset(),
        );
      }
    });

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: colorScheme.onBackground,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'التقط صورتك الشخصية',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onBackground,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: GestureDetector(
                    onTap: _captureSelfie,
                    child: Container(
                      color: colorScheme.surface.withOpacity(0.5),
                      alignment: Alignment.center,
                      child: _selfiePath == null
                          ? Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    colorScheme.secondary,
                                    colorScheme.primary,
                                  ],
                                ),
                              ),
                              child: const Icon(
                                Icons.camera_alt_outlined,
                                color: Colors.white,
                                size: 28,
                              ),
                            )
                          : ClipOval(
                              child: Image.file(
                                File(_selfiePath!),
                                width: 180,
                                height: 180,
                                fit: BoxFit.cover,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 66,
                  vertical: 32,
                ),
                child: SizedBox(
                  height: 56,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [colorScheme.secondary, colorScheme.primary],
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: isLoading || _selfiePath == null
                            ? null
                            : _handleContinue,
                        child: Center(
                          child: isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text(
                                  'المتابعة',
                                  style: TextStyle(
                                    color: _selfiePath != null
                                        ? Colors.white
                                        : Colors.white.withOpacity(0.6),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18,
                                  ),
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
    );
  }
}
