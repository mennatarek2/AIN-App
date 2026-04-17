import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../config/routes/app_routes.dart';
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

  Future<void> _captureFront() async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.rear,
      imageQuality: 85,
    );
    if (file != null) {
      setState(() {
        _frontPath = file.path;
        AttachmentStore.idFrontPath = file.path;
      });
    }
  }

  Future<void> _captureBack() async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.rear,
      imageQuality: 85,
    );
    if (file != null) {
      setState(() {
        _backPath = file.path;
        AttachmentStore.idBackPath = file.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_forward_ios,
                      color: colorScheme.onBackground,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.outlineVariant,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        'قم بتصوير الوجهين الأمامي والخلفي للبطاقة.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colorScheme.outline,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: _IdCaptureCard(
                              label: 'التقط صورة للوجه الأمامي',
                              imagePath: _frontPath,
                              onTap: _captureFront,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _IdCaptureCard(
                              label: 'التقط صورة للوجه الخلفي',
                              imagePath: _backPath,
                              onTap: _captureBack,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 65),
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
                          onTap: (_frontPath != null && _backPath != null)
                              ? () {
                                  Navigator.of(
                                    context,
                                  ).pushNamed(AppRoutes.selfieCapture);
                                }
                              : null,
                          child: Center(
                            child: Text(
                              'المتابعة',
                              style: TextStyle(
                                color: (_frontPath != null && _backPath != null)
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.6),
                                fontWeight: FontWeight.w700,
                                fontSize: 22,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IdCaptureCard extends StatelessWidget {
  const _IdCaptureCard({
    required this.label,
    required this.onTap,
    this.imagePath,
  });

  final String label;
  final VoidCallback onTap;
  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant,
          width: 1,
          style: BorderStyle.solid,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (imagePath == null) ...[
              Icon(
                Icons.camera_alt_outlined,
                color: colorScheme.primary,
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.outline, fontSize: 18),
              ),
            ] else ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(imagePath!),
                  width: 100,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'تم التقاط الصورة',
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.outline, fontSize: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
