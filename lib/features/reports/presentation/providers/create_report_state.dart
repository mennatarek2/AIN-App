import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// The visibility options for a new report.
enum ReportVisibility {
  public('Public', 'عام'),
  confidential('Confidential', 'سري'),
  anonymous('Anonymous', 'مجهول');

  const ReportVisibility(this.apiValue, this.label);

  final String apiValue;
  final String label;
}

/// Immutable state for the 3-step report creation form.
@immutable
class CreateReportState {
  const CreateReportState({
    this.currentStep = 0,
    // Step 1
    this.title = '',
    this.description = '',
    this.categoryId = '',
    this.categoryName = '',
    this.subcategoryId = '',
    this.subcategoryName = '',
    this.visibility = ReportVisibility.public,
    // Step 2
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.locationName = '',
    // Step 3
    this.attachments = const [],
    this.videoThumbnails = const {},
    // Submission
    this.isSubmitting = false,
    this.uploadProgress,
    this.error,
  });

  final int currentStep;

  // ── Step 1 ──
  final String title;
  final String description;
  final String categoryId;
  final String categoryName;
  final String subcategoryId;
  final String subcategoryName;
  final ReportVisibility visibility;

  // ── Step 2 ──
  final double latitude;
  final double longitude;
  final String locationName;

  // ── Step 3 ──
  /// The list of selected files to attach.
  final List<XFile> attachments;

  /// Map from attachment path → thumbnail path (videos only).
  final Map<String, String> videoThumbnails;

  // ── Submission ──
  final bool isSubmitting;

  /// Upload progress in [0.0, 1.0], null when not uploading.
  final double? uploadProgress;
  final String? error;

  // ── Derived getters ──
  bool get step1Valid =>
      title.trim().length >= 3 &&
      title.trim().length <= 200 &&
      description.trim().length >= 10 &&
      description.trim().length <= 2000 &&
      categoryId.isNotEmpty &&
      subcategoryId.isNotEmpty;

  bool get step2Valid => latitude != 0.0 || longitude != 0.0;

  bool get hasLocation => latitude != 0.0 || longitude != 0.0;

  CreateReportState copyWith({
    int? currentStep,
    String? title,
    String? description,
    String? categoryId,
    String? categoryName,
    String? subcategoryId,
    String? subcategoryName,
    ReportVisibility? visibility,
    double? latitude,
    double? longitude,
    String? locationName,
    List<XFile>? attachments,
    Map<String, String>? videoThumbnails,
    bool? isSubmitting,
    double? uploadProgress,
    String? error,
    bool clearProgress = false,
    bool clearError = false,
  }) {
    return CreateReportState(
      currentStep: currentStep ?? this.currentStep,
      title: title ?? this.title,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      subcategoryId: subcategoryId ?? this.subcategoryId,
      subcategoryName: subcategoryName ?? this.subcategoryName,
      visibility: visibility ?? this.visibility,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationName: locationName ?? this.locationName,
      attachments: attachments ?? this.attachments,
      videoThumbnails: videoThumbnails ?? this.videoThumbnails,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      uploadProgress: clearProgress ? null : (uploadProgress ?? this.uploadProgress),
      error: clearError ? null : (error ?? this.error),
    );
  }
}
