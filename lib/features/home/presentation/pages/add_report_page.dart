import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/app_layout_primitives.dart';
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
    final s = ref.watch(createReportProvider);

    return Scaffold(
      backgroundColor: context.colors.surface,
      body: Column(
        children: [
          AppDashboardHeader(
            title: 'إضافة بلاغ',
            subtitle: _stepSubtitle(s.currentStep),
            compact: true,
            trailing: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(
                  Icons.close_rounded,
                  color: context.semantic.textOnPrimary,
                ),
                tooltip: 'إغلاق',
              ),
            ],
            bottom: _StepIndicator(currentStep: s.currentStep),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: KeyedSubtree(
                key: ValueKey(s.currentStep),
                child: _buildStep(context, s),
              ),
            ),
          ),
          if (s.isSubmitting && s.uploadProgress != null)
            _UploadProgressBar(progress: s.uploadProgress!),
          _buildNavBar(context, s),
        ],
      ),
    );
  }

  String _stepSubtitle(int step) {
    return switch (step) {
      0 => 'الخطوة 1 من 3 — المعلومات الأساسية',
      1 => 'الخطوة 2 من 3 — تحديد الموقع',
      2 => 'الخطوة 3 من 3 — المرفقات',
      _ => '',
    };
  }

  Widget _buildStep(BuildContext context, CreateReportState s) {
    switch (s.currentStep) {
      case 0:
        return _Step1BasicInfo(
          titleController: _titleController,
          descController: _descController,
        );
      case 1:
        return const _Step2Location();
      case 2:
        return _Step3Attachments(picker: _picker);
      default:
        return const SizedBox();
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Bottom navigation bar
  // ─────────────────────────────────────────────────────────────────

  Widget _buildNavBar(BuildContext context, CreateReportState s) {
    final isLastStep = s.currentStep == 2;
    final canProceed = _canProceedFromStep(s);

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        AppSpacing.sm,
        AppSpacing.screenHorizontal,
        AppSpacing.sm + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(
          top: BorderSide(color: context.semantic.borderSubtle),
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
                foregroundColor: context.colors.primary,
                side: BorderSide(color: context.colors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
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
                backgroundColor: context.colors.primary,
                foregroundColor: context.semantic.textOnPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                minimumSize: const Size.fromHeight(48),
                elevation: 0,
              ),
              child: s.isSubmitting
                  ? SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: context.semantic.textOnPrimary,
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
          content: Text(
            'فشل إرسال البلاغ: $error',
            textDirection: TextDirection.rtl,
          ),
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
    final labels = ['المعلومات', 'الموقع', 'المرفقات'];

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: context.semantic.textOnPrimary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: context.semantic.textOnPrimary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: List.generate(3, (i) {
          final isActive = i <= currentStep;
          final isCurrent = i == currentStep;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: isCurrent
                    ? context.semantic.textOnPrimary
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${i + 1}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isCurrent
                          ? context.colors.primary
                          : context.semantic.textOnPrimary.withValues(
                              alpha: isActive ? 0.9 : 0.55,
                            ),
                    ),
                  ),
                  Text(
                    labels[i],
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight:
                          isCurrent ? FontWeight.w700 : FontWeight.w500,
                      color: isCurrent
                          ? context.colors.primary
                          : context.semantic.textOnPrimary.withValues(
                              alpha: isActive ? 0.85 : 0.5,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
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
          backgroundColor: context.semantic.borderSubtle,
          valueColor: AlwaysStoppedAnimation<Color>(context.colors.primary),
          minHeight: 4,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xxs,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'جاري الرفع... ${(progress * 100).toStringAsFixed(0)}%',
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontSize: 12,
                  color: context.colors.primary,
                ),
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
  });

  final TextEditingController titleController;
  final TextEditingController descController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(createReportProvider);
    final n = ref.read(createReportProvider.notifier);

    final borderColor = context.isDarkMode
        ? context.colors.onSurface
        : context.colors.onSurface.withValues(alpha: 0.7);
    final textColor = context.colors.onSurface;
    final hintColor = context.semantic.textMuted;

    final categoriesAsync = ref.watch(categoriesProvider);
    final subcategoriesAsync = s.categoryId.isNotEmpty
        ? ref.watch(subcategoriesProvider(s.categoryId))
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppFormCard(
            title: 'تفاصيل البلاغ',
            subtitle: 'أدخل عنواناً ووصفاً واضحاً',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SectionLabel(label: 'عنوان البلاغ *'),
                const SizedBox(height: AppSpacing.xs),
                TextField(
                  controller: titleController,
                  textDirection: TextDirection.rtl,
                  maxLength: 200,
                  inputFormatters: [LengthLimitingTextInputFormatter(200)],
                  decoration: _inputDecoration(
                    context,
                    hint: 'أدخل عنواناً واضحاً للبلاغ',
                    borderColor: borderColor,
                    hintColor: hintColor,
                    textColor: textColor,
                  ),
                  style: TextStyle(color: textColor),
                  onChanged: (v) => n.setTitle(v),
                ),
                const SizedBox(height: AppSpacing.md),
                _SectionLabel(label: 'وصف البلاغ *'),
                const SizedBox(height: AppSpacing.xs),
                TextField(
                  controller: descController,
                  textDirection: TextDirection.rtl,
                  maxLines: 5,
                  maxLength: 2000,
                  inputFormatters: [LengthLimitingTextInputFormatter(2000)],
                  decoration: _inputDecoration(
                    context,
                    hint: 'صف الحادثة أو المشكلة بتفصيل',
                    borderColor: borderColor,
                    hintColor: hintColor,
                    textColor: textColor,
                  ),
                  style: TextStyle(color: textColor),
                  onChanged: (v) => n.setDescription(v),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppFormCard(
            title: 'التصنيف',
            subtitle: 'اختر التصنيف المناسب للبلاغ',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SectionLabel(label: 'التصنيف الرئيسي *'),
                const SizedBox(height: AppSpacing.xs),
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
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(
                              c.name,
                              textDirection: TextDirection.rtl,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (id) {
                      if (id == null) return;
                      final cat = cats.firstWhere((c) => c.id == id);
                      n.setCategory(id: id, name: cat.name);
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _SectionLabel(label: 'التصنيف الفرعي *'),
                const SizedBox(height: AppSpacing.xs),
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
                      hint: subs.isEmpty
                          ? 'لا يوجد تصنيف فرعي'
                          : 'اختر التصنيف الفرعي',
                      borderColor: borderColor,
                      textColor: textColor,
                      items: subs
                          .map(
                            (sub) => DropdownMenuItem(
                              value: sub.id,
                              child: Text(
                                sub.name,
                                textDirection: TextDirection.rtl,
                              ),
                            ),
                          )
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
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppFormCard(
            title: 'مستوى الظهور',
            subtitle: 'حدد من يمكنه رؤية بلاغك',
            child: _VisibilitySelector(
              selected: s.visibility,
              onSelected: n.setVisibility,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(
    BuildContext context, {
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
        borderSide: BorderSide(color: context.colors.primary, width: 1.5),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}

class _VisibilitySelector extends StatelessWidget {
  const _VisibilitySelector({
    required this.selected,
    required this.onSelected,
  });

  final ReportVisibility selected;
  final void Function(ReportVisibility) onSelected;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semantic;
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
                    ? context.colors.primary
                    : semantic.chipBackground,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(
                  color: isSelected
                      ? context.colors.primary
                      : semantic.borderStrong,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _iconFor(v),
                    size: 20,
                    color: isSelected
                        ? context.semantic.textOnPrimary
                        : context.colors.primary,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    v.label,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? context.semantic.textOnPrimary
                          : context.colors.onSurface,
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
  const _Step2Location();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(createReportProvider);
    final n = ref.read(createReportProvider.notifier);
    final hasLocation = s.hasLocation;
    final semantic = context.semantic;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
        vertical: AppSpacing.md,
      ),
      child: AppFormCard(
        title: 'موقع البلاغ',
        subtitle: hasLocation
            ? 'تم تحديد الموقع بنجاح'
            : 'حدد موقع الحادثة على الخريطة',
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: hasLocation
                    ? context.colors.primary.withValues(alpha: 0.08)
                    : semantic.chipBackground,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: hasLocation
                      ? context.colors.primary.withValues(alpha: 0.4)
                      : semantic.borderSubtle,
                ),
              ),
              child: hasLocation
                  ? Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: context.colors.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.location_on_rounded,
                            color: context.colors.primary,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          s.locationName.isNotEmpty
                              ? s.locationName
                              : 'تم تحديد الموقع',
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.center,
                          style: context.text.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          '${s.latitude.toStringAsFixed(5)}, ${s.longitude.toStringAsFixed(5)}',
                          textDirection: TextDirection.ltr,
                          style: context.text.labelSmall?.copyWith(
                            color: context.colors.primary,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        Icon(
                          Icons.add_location_alt_outlined,
                          size: 56,
                          color: semantic.borderStrong,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'لم يتم تحديد الموقع بعد',
                          textDirection: TextDirection.rtl,
                          style: context.text.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: semantic.textMuted,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'اضغط على الزر أدناه لفتح الخريطة وتحديد موقع البلاغ',
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.center,
                          style: context.text.bodySmall?.copyWith(
                            color: semantic.textMuted,
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => _openLocationPicker(context, ref, n),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.primary,
                  foregroundColor: context.semantic.textOnPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  elevation: 0,
                ),
                icon: Icon(
                  hasLocation
                      ? Icons.edit_location_alt_outlined
                      : Icons.map_outlined,
                ),
                label: Text(
                  hasLocation ? 'تغيير الموقع' : 'تحديد الموقع على الخريطة',
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
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
  const _Step3Attachments({required this.picker});
  final ImagePicker picker;

  @override
  ConsumerState<_Step3Attachments> createState() => _Step3AttachmentsState();
}

class _Step3AttachmentsState extends ConsumerState<_Step3Attachments> {
  bool _isPickingMedia = false;

  void _showErrors(List<String> errors) {
    if (errors.isEmpty || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errors.join('\n'), textDirection: TextDirection.rtl),
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
          : await widget.picker.pickImage(
              source: ImageSource.camera,
              imageQuality: 85,
            );
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
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenHorizontal,
            AppSpacing.md,
            AppSpacing.screenHorizontal,
            0,
          ),
          child: AppFormCard(
            title: 'المرفقات',
            subtitle: 'اختياري — حتى $kMaxAttachments ملف',
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                Expanded(
                  child: _AttachActionButton(
                    icon: Icons.camera_alt_outlined,
                    label: 'التقاط صورة',
                    onTap: n.canAddMore ? () => _pickFromCamera() : null,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: _AttachActionButton(
                    icon: Icons.videocam_outlined,
                    label: 'تسجيل فيديو',
                    onTap: n.canAddMore
                        ? () => _pickFromCamera(video: true)
                        : null,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: _AttachActionButton(
                    icon: Icons.photo_library_outlined,
                    label: 'من المعرض',
                    onTap: n.canAddMore ? () => _pickFromGallery() : null,
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '${attachments.length} / $kMaxAttachments مرفق',
                textDirection: TextDirection.rtl,
                style: context.text.labelSmall?.copyWith(
                  color: attachments.length >= kMaxAttachments
                      ? context.semantic.error
                      : context.semantic.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: attachments.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: context.semantic.chipBackground,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.attach_file_rounded,
                          size: 32,
                          color: context.semantic.borderStrong,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'لا توجد مرفقات (اختياري)',
                        textDirection: TextDirection.rtl,
                        style: context.text.bodyMedium?.copyWith(
                          color: context.semantic.textMuted,
                        ),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: AppSpacing.xs,
                    mainAxisSpacing: AppSpacing.xs,
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
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      textDirection: TextDirection.rtl,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: context.colors.onSurface,
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
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          dropdownColor: context.semantic.surfaceContainer,
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
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semantic;
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: enabled ? 1.0 : 0.4,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: semantic.chipBackground,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: semantic.borderSubtle),
          ),
          child: Column(
            children: [
              Icon(icon, color: context.colors.primary, size: 24),
              const SizedBox(height: 6),
              Text(
                label,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: context.colors.onSurface,
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
                color: context.semantic.chipBackground,
                child: Icon(
                  Icons.broken_image_outlined,
                  color: context.semantic.textMuted,
                  size: 32,
                ),
              ),
            ),
          ),
        ),
        if (isVideo)
          Positioned.fill(
            child: Center(
              child: Icon(
                Icons.play_circle_filled_rounded,
                color: context.semantic.textOnPrimary,
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
                color: context.semantic.overlay,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                color: context.semantic.textOnPrimary,
                size: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
