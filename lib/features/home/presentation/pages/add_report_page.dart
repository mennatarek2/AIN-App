import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/categories_provider.dart';
import '../providers/subcategories_provider.dart';
import 'select_report_location_page.dart';
import '../../../my_reports/presentation/providers/my_reports_provider.dart';
import '../../../reports/presentation/providers/create_report_notifier.dart';
import '../../../reports/presentation/providers/create_report_state.dart';

/// 3-step report creation wizard.
///
/// Step 0: Basic information (title, description, category, subcategory, visibility)
/// Step 1: Location (opens SelectReportLocationPage)
/// Step 2: Media attachments
class AddReportPage extends ConsumerStatefulWidget {
  const AddReportPage({super.key});

  @override
  ConsumerState<AddReportPage> createState() => _AddReportPageState();
}

class _AddReportPageState extends ConsumerState<AddReportPage> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _picker = ImagePicker();

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = ref.watch(createReportProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(isDark, s),
      body: Column(
        children: [
          _StepIndicator(currentStep: s.currentStep),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: KeyedSubtree(
                key: ValueKey(s.currentStep),
                child: _buildStep(s, isDark),
              ),
            ),
          ),
          // Upload progress bar
          if (s.isSubmitting && s.uploadProgress != null)
            _UploadProgressBar(progress: s.uploadProgress!),
          _buildNavBar(s, isDark),
        ],
      ),
    );
  }

  AppBar _buildAppBar(bool isDark, CreateReportState s) {
    return AppBar(
      backgroundColor: isDark ? const Color(0xFF121A5C) : AppColors.primarySoft,
      foregroundColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
      elevation: 0,
      title: const Text(
        'إضافة بلاغ',
        textDirection: TextDirection.rtl,
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
      ),
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }

  Widget _buildStep(CreateReportState s, bool isDark) {
    switch (s.currentStep) {
      case 0:
        return _Step1BasicInfo(
          titleController: _titleController,
          descController: _descController,
          isDark: isDark,
        );
      case 1:
        return _Step2Location(isDark: isDark);
      case 2:
        return _Step3Attachments(picker: _picker, isDark: isDark);
      default:
        return const SizedBox();
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Bottom navigation bar
  // ─────────────────────────────────────────────────────────────────

  Widget _buildNavBar(CreateReportState s, bool isDark) {
    final isLastStep = s.currentStep == 2;
    final canProceed = _canProceedFromStep(s);

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF2A3580) : const Color(0xFFD1D9F0),
          ),
        ),
      ),
      child: Row(
        children: [
          // Back button
          if (s.currentStep > 0)
            OutlinedButton(
              onPressed: s.isSubmitting
                  ? null
                  : () => ref.read(createReportProvider.notifier).prevStep(),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size(80, 48),
              ),
              child: const Text('السابق', textDirection: TextDirection.rtl),
            ),
          if (s.currentStep > 0) const SizedBox(width: 12),
          // Next / Submit button
          Expanded(
            child: ElevatedButton(
              onPressed: (!canProceed || s.isSubmitting)
                  ? null
                  : () => _onNextOrSubmit(s, isLastStep),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size.fromHeight(48),
                elevation: 0,
              ),
              child: s.isSubmitting
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      isLastStep ? 'إرسال البلاغ' : 'التالي',
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  bool _canProceedFromStep(CreateReportState s) {
    switch (s.currentStep) {
      case 0:
        return s.step1Valid;
      case 1:
        return s.hasLocation;
      case 2:
        return true; // attachments are optional
      default:
        return false;
    }
  }

  Future<void> _onNextOrSubmit(CreateReportState s, bool isLastStep) async {
    if (!isLastStep) {
      ref.read(createReportProvider.notifier).nextStep();
      return;
    }

    // Submit
    final error = await ref.read(createReportProvider.notifier).submit();
    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل إرسال البلاغ: $error', textDirection: TextDirection.rtl),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 5),
        ),
      );
      return;
    }

    // Success — invalidate my reports and navigate
    ref.invalidate(myReportsProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تم إرسال البلاغ بنجاح ✓',
            textDirection: TextDirection.rtl,
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    }
  }
}

// =============================================================================
// Step Indicator
// =============================================================================

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.currentStep});
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labels = ['المعلومات الأساسية', 'الموقع', 'المرفقات'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: isDark ? const Color(0xFF121A5C) : AppColors.primarySoft,
      child: Column(
        children: [
          Row(
            children: List.generate(3, (i) {
              final isActive = i <= currentStep;
              final isCurrent = i == currentStep;
              return Expanded(
                child: Row(
                  children: [
                    _StepDot(index: i + 1, isActive: isActive, isCurrent: isCurrent),
                    if (i < 2)
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 2,
                          color: i < currentStep
                              ? AppColors.primary
                              : (isDark
                                  ? const Color(0xFF2A3580)
                                  : const Color(0xFFB8C4D9)),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(3, (i) {
              final isCurrent = i == currentStep;
              return Text(
                labels[i],
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
                  color: isCurrent
                      ? AppColors.primary
                      : (isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.index,
    required this.isActive,
    required this.isCurrent,
  });

  final int index;
  final bool isActive;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isCurrent ? 32 : 24,
      height: isCurrent ? 32 : 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? AppColors.primary : const Color(0xFFB8C4D9),
        border: isCurrent
            ? Border.all(color: Colors.white, width: 2.5)
            : null,
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  blurRadius: 8,
                ),
              ]
            : null,
      ),
      child: Center(
        child: Text(
          '$index',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Upload progress
// =============================================================================

class _UploadProgressBar extends StatelessWidget {
  const _UploadProgressBar({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LinearProgressIndicator(
          value: progress,
          backgroundColor: const Color(0xFFD1D9F0),
          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          minHeight: 4,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'جاري الرفع... ${(progress * 100).toStringAsFixed(0)}%',
                textDirection: TextDirection.rtl,
                style: const TextStyle(fontSize: 12, color: AppColors.primary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Step 1 — Basic Information
// =============================================================================

class _Step1BasicInfo extends ConsumerWidget {
  const _Step1BasicInfo({
    required this.titleController,
    required this.descController,
    required this.isDark,
  });

  final TextEditingController titleController;
  final TextEditingController descController;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(createReportProvider);
    final n = ref.read(createReportProvider.notifier);

    final borderColor =
        isDark ? AppColors.textPrimaryDark : const Color(0xB3060C3A);
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final hintColor =
        isDark ? AppColors.textSecondaryDark : const Color(0x80060C3A);

    final categoriesAsync = ref.watch(categoriesProvider);
    final subcategoriesAsync = s.categoryId.isNotEmpty
        ? ref.watch(subcategoriesProvider(s.categoryId))
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Title ──
          _SectionLabel(label: 'عنوان البلاغ *', isDark: isDark),
          const SizedBox(height: 8),
          TextField(
            controller: titleController,
            textDirection: TextDirection.rtl,
            maxLength: 200,
            inputFormatters: [LengthLimitingTextInputFormatter(200)],
            decoration: _inputDecoration(
              hint: 'أدخل عنواناً واضحاً للبلاغ',
              borderColor: borderColor,
              hintColor: hintColor,
              textColor: textColor,
            ),
            style: TextStyle(color: textColor),
            onChanged: (v) => n.setTitle(v),
          ),
          const SizedBox(height: 16),

          // ── Description ──
          _SectionLabel(label: 'وصف البلاغ *', isDark: isDark),
          const SizedBox(height: 8),
          TextField(
            controller: descController,
            textDirection: TextDirection.rtl,
            maxLines: 5,
            maxLength: 2000,
            inputFormatters: [LengthLimitingTextInputFormatter(2000)],
            decoration: _inputDecoration(
              hint: 'صف الحادثة أو المشكلة بتفصيل',
              borderColor: borderColor,
              hintColor: hintColor,
              textColor: textColor,
            ),
            style: TextStyle(color: textColor),
            onChanged: (v) => n.setDescription(v),
          ),
          const SizedBox(height: 16),

          // ── Category ──
          _SectionLabel(label: 'التصنيف الرئيسي *', isDark: isDark),
          const SizedBox(height: 8),
          categoriesAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text(
              'فشل تحميل التصنيفات',
              style: TextStyle(color: Colors.red.shade400),
            ),
            data: (cats) => _StyledDropdown<String>(
              value: s.categoryId.isEmpty ? null : s.categoryId,
              hint: 'اختر التصنيف',
              borderColor: borderColor,
              textColor: textColor,
              items: cats
                  .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name, textDirection: TextDirection.rtl)))
                  .toList(),
              onChanged: (id) {
                if (id == null) return;
                final cat = cats.firstWhere((c) => c.id == id);
                n.setCategory(id: id, name: cat.name);
              },
            ),
          ),
          const SizedBox(height: 16),

          // ── Subcategory ──
          _SectionLabel(label: 'التصنيف الفرعي *', isDark: isDark),
          const SizedBox(height: 8),
          if (s.categoryId.isEmpty)
            _StyledDropdown<String>(
              value: null,
              hint: 'اختر التصنيف الرئيسي أولاً',
              borderColor: borderColor,
              textColor: hintColor,
              items: const [],
              onChanged: null,
            )
          else
            subcategoriesAsync!.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text(
                'فشل تحميل التصنيفات الفرعية',
                style: TextStyle(color: Colors.red.shade400),
              ),
              data: (subs) => _StyledDropdown<String>(
                value: s.subcategoryId.isEmpty ? null : s.subcategoryId,
                hint: subs.isEmpty ? 'لا يوجد تصنيف فرعي' : 'اختر التصنيف الفرعي',
                borderColor: borderColor,
                textColor: textColor,
                items: subs
                    .map((sub) => DropdownMenuItem(value: sub.id, child: Text(sub.name, textDirection: TextDirection.rtl)))
                    .toList(),
                onChanged: subs.isEmpty
                    ? null
                    : (id) {
                        if (id == null) return;
                        final sub = subs.firstWhere((s) => s.id == id);
                        n.setSubcategory(id: id, name: sub.name);
                      },
              ),
            ),
          const SizedBox(height: 24),

          // ── Visibility ──
          _SectionLabel(label: 'مستوى الظهور', isDark: isDark),
          const SizedBox(height: 8),
          _VisibilitySelector(
            selected: s.visibility,
            onSelected: n.setVisibility,
            isDark: isDark,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required Color borderColor,
    required Color hintColor,
    required Color textColor,
  }) {
    final border = OutlineInputBorder(
      borderSide: BorderSide(color: borderColor),
      borderRadius: BorderRadius.circular(10),
    );
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: hintColor),
      hintTextDirection: TextDirection.rtl,
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        borderRadius: BorderRadius.circular(10),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}

class _VisibilitySelector extends StatelessWidget {
  const _VisibilitySelector({
    required this.selected,
    required this.onSelected,
    required this.isDark,
  });

  final ReportVisibility selected;
  final void Function(ReportVisibility) onSelected;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      children: ReportVisibility.values.map((v) {
        final isSelected = v == selected;
        return Expanded(
          child: GestureDetector(
            onTap: () => onSelected(v),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? const Color(0xFF1A2070) : const Color(0xFFF0F4FF)),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? AppColors.primary : const Color(0xFFB8C4D9),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _iconFor(v),
                    size: 20,
                    color: isSelected ? Colors.white : AppColors.primary,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    v.label,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : (isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  IconData _iconFor(ReportVisibility v) {
    return switch (v) {
      ReportVisibility.public => Icons.public_rounded,
      ReportVisibility.confidential => Icons.lock_outline_rounded,
      ReportVisibility.anonymous => Icons.person_off_outlined,
    };
  }
}

// =============================================================================
// Step 2 — Location
// =============================================================================

class _Step2Location extends ConsumerWidget {
  const _Step2Location({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(createReportProvider);
    final n = ref.read(createReportProvider.notifier);
    final hasLocation = s.hasLocation;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Location display card
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: hasLocation
                  ? AppColors.primary.withValues(alpha: 0.08)
                  : (isDark
                      ? const Color(0xFF1A2070)
                      : const Color(0xFFF0F4FF)),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: hasLocation
                    ? AppColors.primary
                    : (isDark
                        ? const Color(0xFF2A3580)
                        : const Color(0xFFD1D9F0)),
                width: 1.5,
              ),
            ),
            child: hasLocation
                ? Column(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        color: AppColors.primary,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        s.locationName.isNotEmpty ? s.locationName : 'تم تحديد الموقع',
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${s.latitude.toStringAsFixed(5)}, ${s.longitude.toStringAsFixed(5)}',
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      Icon(
                        Icons.add_location_alt_outlined,
                        size: 64,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : const Color(0xFFB8C4D9),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'لم يتم تحديد الموقع بعد',
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : const Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'اضغط على الزر أدناه لفتح الخريطة وتحديد موقع البلاغ',
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : const Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => _openLocationPicker(context, ref, n),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              icon: Icon(
                hasLocation ? Icons.edit_location_alt_outlined : Icons.map_outlined,
              ),
              label: Text(
                hasLocation ? 'تغيير الموقع' : 'تحديد الموقع على الخريطة',
                textDirection: TextDirection.rtl,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openLocationPicker(
    BuildContext context,
    WidgetRef ref,
    CreateReportNotifier n,
  ) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute<dynamic>(
        builder: (_) => const SelectReportLocationPage(),
      ),
    );

    if (result == null) return;

    // SelectReportLocationPage returns a LatLng or a Map with lat/lng/address
    double lat, lng;
    String address = '';

    if (result is Map) {
      lat = (result['latitude'] as num?)?.toDouble() ?? 0.0;
      lng = (result['longitude'] as num?)?.toDouble() ?? 0.0;
      address = result['address']?.toString() ?? '';
    } else {
      // LatLng from google_maps_flutter
      try {
        lat = (result.latitude as num).toDouble();
        lng = (result.longitude as num).toDouble();
      } catch (_) {
        return;
      }
    }

    n.setLocation(latitude: lat, longitude: lng, locationName: address);
  }
}

// =============================================================================
// Step 3 — Attachments
// =============================================================================

class _Step3Attachments extends ConsumerStatefulWidget {
  const _Step3Attachments({required this.picker, required this.isDark});
  final ImagePicker picker;
  final bool isDark;

  @override
  ConsumerState<_Step3Attachments> createState() => _Step3AttachmentsState();
}

class _Step3AttachmentsState extends ConsumerState<_Step3Attachments> {
  bool _isPickingMedia = false;

  void _showErrors(List<String> errors) {
    if (errors.isEmpty || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          errors.join('\n'),
          textDirection: TextDirection.rtl,
        ),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _pickFromCamera({bool video = false}) async {
    if (_isPickingMedia) return;
    setState(() => _isPickingMedia = true);
    try {
      final XFile? file = video
          ? await widget.picker.pickVideo(source: ImageSource.camera)
          : await widget.picker.pickImage(source: ImageSource.camera, imageQuality: 85);
      if (file != null && mounted) {
        final errors = await ref
            .read(createReportProvider.notifier)
            .addAttachments([file]);
        _showErrors(errors);
      }
    } finally {
      if (mounted) setState(() => _isPickingMedia = false);
    }
  }

  Future<void> _pickFromGallery() async {
    if (_isPickingMedia) return;
    setState(() => _isPickingMedia = true);
    try {
      final files = await widget.picker.pickMultiImage(imageQuality: 85);
      if (files.isNotEmpty && mounted) {
        final errors = await ref
            .read(createReportProvider.notifier)
            .addAttachments(files);
        _showErrors(errors);
      }
    } finally {
      if (mounted) setState(() => _isPickingMedia = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(createReportProvider);
    final n = ref.read(createReportProvider.notifier);
    final attachments = s.attachments;

    return Column(
      children: [
        // Attachment actions
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Expanded(
                child: _AttachActionButton(
                  icon: Icons.camera_alt_outlined,
                  label: 'التقاط صورة',
                  onTap: n.canAddMore ? () => _pickFromCamera() : null,
                  isDark: widget.isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _AttachActionButton(
                  icon: Icons.videocam_outlined,
                  label: 'تسجيل فيديو',
                  onTap: n.canAddMore ? () => _pickFromCamera(video: true) : null,
                  isDark: widget.isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _AttachActionButton(
                  icon: Icons.photo_library_outlined,
                  label: 'من المعرض',
                  onTap: n.canAddMore ? () => _pickFromGallery() : null,
                  isDark: widget.isDark,
                ),
              ),
            ],
          ),
        ),
        // Counter
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '${attachments.length} / $kMaxAttachments مرفق',
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontSize: 12,
                  color: attachments.length >= kMaxAttachments
                      ? Colors.redAccent
                      : (widget.isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight),
                ),
              ),
            ],
          ),
        ),
        // Grid
        Expanded(
          child: attachments.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.attach_file_rounded,
                        size: 64,
                        color: widget.isDark
                            ? AppColors.textSecondaryDark
                            : const Color(0xFFB8C4D9),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'لا توجد مرفقات (اختياري)',
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontSize: 14,
                          color: widget.isDark
                              ? AppColors.textSecondaryDark
                              : const Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: attachments.length,
                  itemBuilder: (context, index) {
                    final file = attachments[index];
                    final thumbPath = s.videoThumbnails[file.path];
                    final isVideo = thumbPath != null;
                    return _AttachmentThumbnail(
                      filePath: isVideo ? thumbPath : file.path,
                      isVideo: isVideo,
                      onRemove: () => n.removeAttachment(index),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// =============================================================================
// Helper widgets
// =============================================================================

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.isDark});
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      textDirection: TextDirection.rtl,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
      ),
    );
  }
}

class _StyledDropdown<T> extends StatelessWidget {
  const _StyledDropdown({
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
    required this.borderColor,
    required this.textColor,
  });

  final T? value;
  final String hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final Color borderColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          dropdownColor:
              isDark ? const Color(0xFF1A2070) : Colors.white,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: textColor),
          hint: Align(
            alignment: Alignment.centerRight,
            child: Text(
              hint,
              textDirection: TextDirection.rtl,
              style: TextStyle(color: textColor, fontSize: 15),
            ),
          ),
          items: items,
          onChanged: onChanged,
          style: TextStyle(fontSize: 15, color: textColor),
        ),
      ),
    );
  }
}

class _AttachActionButton extends StatelessWidget {
  const _AttachActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: enabled ? 1.0 : 0.4,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A2070) : const Color(0xFFF0F4FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xFF2A3580) : const Color(0xFFD1D9F0),
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.primary, size: 24),
              const SizedBox(height: 6),
              Text(
                label,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttachmentThumbnail extends StatelessWidget {
  const _AttachmentThumbnail({
    required this.filePath,
    required this.isVideo,
    required this.onRemove,
  });

  final String filePath;
  final bool isVideo;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(
              File(filePath),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => Container(
                color: const Color(0xFF1A2070),
                child: const Icon(
                  Icons.broken_image_outlined,
                  color: Colors.white54,
                  size: 32,
                ),
              ),
            ),
          ),
        ),
        if (isVideo)
          const Positioned.fill(
            child: Center(
              child: Icon(
                Icons.play_circle_filled_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }
}
