import 'dart:io';

import 'package:flutter/material.dart' show Color;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../../../../core/network/api_exception.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/state/auth_state_simple.dart';
import '../../domain/report_model.dart';
import 'create_report_state.dart';
import 'report_data_providers.dart';

/// Maximum number of attachments.
const int kMaxAttachments = 10;

/// Maximum file size in bytes (20 MB).
const int kMaxFileSizeBytes = 20 * 1024 * 1024;

class CreateReportNotifier extends StateNotifier<CreateReportState> {
  CreateReportNotifier(this._ref) : super(const CreateReportState());

  final Ref _ref;

  // ─────────────────────────────────────────────────────────────────
  // Step navigation
  // ─────────────────────────────────────────────────────────────────

  void nextStep() {
    if (state.currentStep < 2) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void prevStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  void goToStep(int step) {
    state = state.copyWith(currentStep: step.clamp(0, 2));
  }

  // ─────────────────────────────────────────────────────────────────
  // Step 1: Basic information
  // ─────────────────────────────────────────────────────────────────

  void setTitle(String value) => state = state.copyWith(title: value);

  void setDescription(String value) =>
      state = state.copyWith(description: value);

  void setCategory({required String id, required String name}) {
    state = state.copyWith(
      categoryId: id,
      categoryName: name,
      // Reset subcategory when category changes
      subcategoryId: '',
      subcategoryName: '',
    );
  }

  void setSubcategory({required String id, required String name}) {
    state = state.copyWith(subcategoryId: id, subcategoryName: name);
  }

  void setVisibility(ReportVisibility visibility) {
    state = state.copyWith(visibility: visibility);
  }

  // ─────────────────────────────────────────────────────────────────
  // Step 2: Location
  // ─────────────────────────────────────────────────────────────────

  void setLocation({
    required double latitude,
    required double longitude,
    required String locationName,
  }) {
    state = state.copyWith(
      latitude: latitude,
      longitude: longitude,
      locationName: locationName,
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // Step 3: Attachments
  // ─────────────────────────────────────────────────────────────────

  /// Validate a file for size constraints.
  /// Returns an error message, or null if valid.
  String? validateFile(XFile file) {
    final fileObj = File(file.path);
    if (!fileObj.existsSync()) return null; // skip missing files
    final bytes = fileObj.lengthSync();
    if (bytes > kMaxFileSizeBytes) {
      final name = file.name.isNotEmpty ? file.name : file.path.split('/').last;
      return 'الملف "$name" يتجاوز الحد الأقصى (20 ميغابايت)';
    }
    return null;
  }

  /// Add files to the attachment list.
  /// Returns a list of validation error messages (empty if all ok).
  Future<List<String>> addAttachments(List<XFile> files) async {
    final errors = <String>[];
    final toAdd = <XFile>[];

    for (final file in files) {
      if (state.attachments.length + toAdd.length >= kMaxAttachments) {
        errors.add('لا يمكن إضافة أكثر من $kMaxAttachments مرفقات');
        break;
      }
      final err = validateFile(file);
      if (err != null) {
        errors.add(err);
      } else {
        toAdd.add(file);
      }
    }

    if (toAdd.isEmpty) return errors;

    final newAttachments = [...state.attachments, ...toAdd];
    final updatedThumbnails = Map<String, String>.from(state.videoThumbnails);

    // Generate video thumbnails for video files.
    for (final file in toAdd) {
      if (_isVideo(file.path)) {
        final thumb = await _generateVideoThumbnail(file.path);
        if (thumb != null) {
          updatedThumbnails[file.path] = thumb;
        }
      }
    }

    state = state.copyWith(
      attachments: newAttachments,
      videoThumbnails: updatedThumbnails,
    );
    return errors;
  }

  void removeAttachment(int index) {
    final current = [...state.attachments];
    if (index < 0 || index >= current.length) return;
    final removed = current.removeAt(index);
    final thumbs = Map<String, String>.from(state.videoThumbnails)
      ..remove(removed.path);
    state = state.copyWith(attachments: current, videoThumbnails: thumbs);
  }

  bool get canAddMore => state.attachments.length < kMaxAttachments;

  // ─────────────────────────────────────────────────────────────────
  // Submission
  // ─────────────────────────────────────────────────────────────────

  Future<String?> submit() async {
    if (state.isSubmitting) return null;

    state = state.copyWith(
      isSubmitting: true,
      uploadProgress: 0.0,
      clearError: true,
    );

    try {
      // Verify auth state before attempting submission.
      final authState = _ref.read(authNotifierProvider);
      if (authState is! AuthAuthenticated) {
        throw Exception('يجب تسجيل الدخول لإرسال بلاغ');
      }

      // Build a minimal ReportModel from the collected form state.
      // The repository's submitReportWithProgress handles multipart packing.
      final report = ReportModel(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: state.title.trim(),
        description: state.description.trim(),
        fullDescription: state.description.trim(),
        reportType: state.subcategoryName,
        // imagePath: empty — we pass explicit attachmentPaths to submitReportWithProgress
        imagePath: '',
        progressIndex: 0,
        statusLabel: 'تم الاستلام',
        statusColor: const Color(0xFF38A0FA),
        latitude: state.latitude,
        longitude: state.longitude,
        locationAddress: state.locationName,
        isSynced: false,
        categoryName: state.categoryName,
        subCategoryName: state.subcategoryName,
        subCategoryId: state.subcategoryId,
        visibility: state.visibility.apiValue,
        localId: 'local-${DateTime.now().microsecondsSinceEpoch}',
        submittedAgo: 'الآن',
      );

      final repo = _ref.read(reportRepositoryProvider);
      final attachmentPaths = state.attachments.map((f) => f.path).toList();

      await repo.submitReportWithProgress(
        report,
        onProgress: (p) {
          if (mounted) {
            state = state.copyWith(uploadProgress: p);
          }
        },
        attachmentPaths: attachmentPaths,
      );

      if (mounted) {
        state = state.copyWith(isSubmitting: false, clearProgress: true);
      }
      return null; // success
    } on ApiException catch (e) {
      if (mounted) {
        state = state.copyWith(
          isSubmitting: false,
          clearProgress: true,
          error: e.message,
        );
      }
      return e.message;
    } catch (e) {
      final msg = e.toString();
      if (mounted) {
        state = state.copyWith(
          isSubmitting: false,
          clearProgress: true,
          error: msg,
        );
      }
      return msg;
    }
  }

  void reset() => state = const CreateReportState();

  // ─────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────

  static bool _isVideo(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.avi') ||
        lower.endsWith('.mkv') ||
        lower.endsWith('.webm');
  }

  Future<String?> _generateVideoThumbnail(String videoPath) async {
    try {
      final thumbPath = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 300,
        quality: 75,
        timeMs: 0, // capture first frame
      );
      return thumbPath;
    } catch (_) {
      return null;
    }
  }
}

/// The provider is auto-disposed so each route push gets a fresh form.
final createReportProvider =
    StateNotifierProvider.autoDispose<CreateReportNotifier, CreateReportState>(
      (ref) => CreateReportNotifier(ref),
    );
