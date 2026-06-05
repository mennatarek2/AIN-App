import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../location/data/location_service.dart';
import '../../../location/presentation/providers/location_providers.dart';
import '../../../location/presentation/widgets/map_screen.dart';
import '../../../notifications/presentation/providers/notifications_provider.dart';
import '../providers/home_feed_provider.dart';
import '../../../my_reports/presentation/providers/my_reports_provider.dart';
import 'add_report_success_page.dart';
import 'select_report_location_page.dart';

class CategoryOption {
  const CategoryOption({required this.name, required this.subCategories});

  final String name;
  final List<SubCategoryOption> subCategories;
}

class SubCategoryOption {
  const SubCategoryOption({required this.id, required this.name});

  final String id;
  final String name;
}

class AddReportPage extends ConsumerStatefulWidget {
  const AddReportPage({super.key});

  @override
  ConsumerState<AddReportPage> createState() => _AddReportPageState();
}

class _AddReportPageState extends ConsumerState<AddReportPage> {
  CategoryOption? _selectedCategory;
  SubCategoryOption? _selectedSubCategory;
  String? _visibility;
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final ImagePicker _imagePicker;
  XFile? _selectedImage;
  bool _isSubmitting = false;

  final _categoryOptions = const [
    CategoryOption(
      name: 'الأمن',
      subCategories: [
        SubCategoryOption(
          id: '4364b582-d500-4762-80fb-4ef7501a7ec6',
          name: 'ﺳطو',
        ),
        SubCategoryOption(
          id: '3087d4ea-352b-4c35-8f1f-e5f508b009fd',
          name: 'ﺳرﻗﺔ',
        ),
      ],
    ),
    CategoryOption(
      name: 'السلامة العامة',
      subCategories: [
        SubCategoryOption(
          id: '0d7b168e-d6ea-48b9-b78f-6bdb70a7e1a1',
          name: 'ﻣواد ﺧطرة',
        ),
        SubCategoryOption(
          id: '59eb1e96-57be-4d3b-a131-520fdc5e69d7',
          name: 'مشاكل المواصلات',
        ),
        SubCategoryOption(
          id: '660e8400-e29b-41d4-a716-446655440000',
          name: 'تلف الطرق',
        ),
      ],
    ),
    CategoryOption(
      name: 'الحوادث المنزلية',
      subCategories: [
        SubCategoryOption(
          id: 'b8c89a18-86cc-49f4-bd4d-a6e771625056',
          name: 'حوادث داخل المنزل',
        ),
        SubCategoryOption(
          id: 'd445ddd4-f37d-4866-a774-b26d7b481ca7',
          name: 'إصابات منزلية',
        ),
        SubCategoryOption(
          id: '1c556438-f145-4298-97e6-d9af5ad6ab17',
          name: 'حرائق',
        ),
      ],
    ),
    CategoryOption(
      name: 'المرافق العامة',
      subCategories: [
        SubCategoryOption(
          id: 'fee18c42-a2a1-4db6-9be0-c3fd83886f6f',
          name: 'انقطاع المياه',
        ),
        SubCategoryOption(
          id: '034e5a26-4fd8-4f83-ac4f-c40d4c5f2364',
          name: 'انقطاع الكهرباء',
        ),
        SubCategoryOption(
          id: '8f5d66d4-6a48-4754-a2f0-cce8a48457ef',
          name: 'مشاكل الصرف الصحي',
        ),
      ],
    ),
    CategoryOption(
      name: 'مشاكل إلكترونية',
      subCategories: [
        SubCategoryOption(
          id: '4379a043-16e7-4206-94fc-4d30097cd84d',
          name: 'الاختراق',
        ),
        SubCategoryOption(
          id: 'a69a3f06-152b-44a8-a6f7-34e7343dba5a',
          name: 'التنمر الإلكتروني',
        ),
        SubCategoryOption(
          id: '5a19f80f-f265-46cb-b53c-a0890c72ca58',
          name: 'الاحتيال',
        ),
        SubCategoryOption(
          id: 'd5f4f7c4-34c7-4fbf-a4ec-56f95ed9f1d4',
          name: 'إساءة الاستخدام',
        ),
      ],
    ),
    CategoryOption(name: 'أخرى', subCategories: []),
  ];
  final _visibilityOptions = const ['عام', 'مجهول', 'سري'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _imagePicker = ImagePicker();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reportLocationProvider.notifier).initialize();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final width = media.size.width;
    ref.listen<ReportLocationState>(reportLocationProvider, (previous, next) {
      final hasNewError =
          next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage;
      if (!hasNewError || !mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(next.errorMessage!)));
    });

    final reportLocationState = ref.watch(reportLocationProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final headerColor = isDark
        ? const Color(0xFF121A5C)
        : AppColors.primarySoft;
    final headerTextColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final fieldBorderColor = isDark
        ? AppColors.textPrimaryDark
        : const Color(0xB3060C3A);
    final fieldTextColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final hintColor = isDark
        ? AppColors.textSecondaryDark
        : const Color(0x80060C3A);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(
                context,
                headerColor: headerColor,
                headerTextColor: headerTextColor,
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 17),
                child: Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: _buildCategoryDropdown(
                          textColor: fieldTextColor,
                          borderColor: fieldBorderColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: _buildSubCategoryDropdown(
                          textColor: fieldTextColor,
                          borderColor: fieldBorderColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 17),
                child: SizedBox(
                  height: 48,
                  child: _buildDropdown(
                    value: _visibility,
                    hint: 'الظهور',
                    items: _visibilityOptions,
                    textColor: fieldTextColor,
                    borderColor: fieldBorderColor,
                    onChanged: (value) => setState(() => _visibility = value),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 17),
                child: _InputBox(
                  height: 48,
                  hint: 'عنوان البلاغ',
                  borderColor: fieldBorderColor,
                  hintColor: hintColor,
                  textColor: fieldTextColor,
                  controller: _titleController,
                  maxLines: 1,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 17),
                child: _InputBox(
                  height: 116,
                  hint: 'وصف البلاغ',
                  borderColor: fieldBorderColor,
                  hintColor: hintColor,
                  textColor: fieldTextColor,
                  controller: _descriptionController,
                  maxLines: 5,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 17),
                child: Container(
                  height: 144,
                  decoration: BoxDecoration(
                    border: Border.all(color: fieldBorderColor, width: 1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _selectedImage == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 16),
                                child: Text(
                                  'قم بتحميل أو التقاط صورة تعبر عن البلاغ',
                                  textDirection: TextDirection.rtl,
                                  textAlign: TextAlign.start,
                                  style: TextStyle(
                                    fontSize: 17,
                                    color: hintColor,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              textDirection: TextDirection.rtl,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _UploadActionBox(
                                  icon: Icons.photo_camera_outlined,
                                  label: 'التقاط صورة',
                                  borderColor: hintColor,
                                  textColor: hintColor,
                                  onTap: () => _pickImage(ImageSource.camera),
                                ),
                                const SizedBox(width: 46),
                                _UploadActionBox(
                                  icon: Icons.file_upload_outlined,
                                  label: 'تحميل صورة',
                                  borderColor: hintColor,
                                  textColor: hintColor,
                                  onTap: () => _pickImage(ImageSource.gallery),
                                ),
                              ],
                            ),
                          ],
                        )
                      : Stack(
                          children: [
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(
                                  File(_selectedImage!.path),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              left: 8,
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedImage = null),
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.35),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),
              _buildLocationSelector(
                locationState: reportLocationState,
                borderColor: fieldBorderColor,
              ),
              const SizedBox(height: 36),
              Align(
                child: Container(
                  width: width < 330 ? width - 40 : 300,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF0099FF), Color(0xFF66C8FF)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextButton(
                    onPressed: _isSubmitting
                        ? null
                        : () async {
                            if (!_isFormValid) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'يرجى تعبئة جميع الحقول المطلوبة',
                                  ),
                                ),
                              );
                              return;
                            }

                            final location = ref
                                .read(reportLocationProvider)
                                .selectedLatLng;
                            if (location == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'يرجى اختيار موقع البلاغ على الخريطة',
                                  ),
                                ),
                              );
                              return;
                            }

                            final address = ref
                                .read(reportLocationProvider)
                                .selectedAddress;

                            final category = _selectedCategory!;
                            final subCategory = _resolveSubCategory();
                            final subCategoryId = _resolveSubCategoryId();
                            final hasSubCategories =
                                (category.subCategories).isNotEmpty;

                            if (subCategory == null || subCategory.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'يرجى اختيار التصنيف الفرعي قبل الإرسال',
                                  ),
                                ),
                              );
                              return;
                            }
                            if (hasSubCategories &&
                                (subCategoryId == null ||
                                    subCategoryId.isEmpty)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'تعذر تحديد معرف التصنيف الفرعي، يرجى إعادة الاختيار',
                                  ),
                                ),
                              );
                              return;
                            }

                            final reportType = subCategory;
                            final apiVisibility = _mapVisibilityToApi(
                              _visibility!,
                            );

                            // Show loading state
                            if (!mounted) return;
                            setState(() => _isSubmitting = true);

                            try {
                              // Add report locally
                              await ref
                                  .read(myReportsProvider.notifier)
                                  .addReportFromSubmission(
                                    title: _titleController.text.trim(),
                                    description: _descriptionController.text
                                        .trim(),
                                    categoryName: category.name,
                                    subCategoryName: reportType,
                                    subCategoryId: subCategoryId ?? '',
                                    latitude: location.latitude,
                                    longitude: location.longitude,
                                    locationAddress: address,
                                    visibility: apiVisibility,
                                    imagePath: _selectedImage?.path,
                                  );

                              // Refresh feed from API
                              await ref
                                  .read(homeFeedProvider.notifier)
                                  .refreshReportsFromApi();

                              // Send notification
                              await ref
                                  .read(notificationsProvider.notifier)
                                  .notifyReportSubmitted(
                                    reportTitle: _titleController.text.trim(),
                                    reportType: reportType,
                                  );

                              if (!mounted) return;
                              setState(() => _isSubmitting = false);

                              // Navigate to success page
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const AddReportSuccessPage(),
                                ),
                              );
                            } catch (e) {
                              if (!mounted) return;
                              setState(() => _isSubmitting = false);

                              // Show error message
                              final errorMessage = _extractErrorMessage(e);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'حدث خطأ أثناء إرسال البلاغ: $errorMessage',
                                    textDirection: TextDirection.rtl,
                                  ),
                                  backgroundColor: Colors.red,
                                  duration: const Duration(seconds: 4),
                                ),
                              );
                            }
                          },
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFF3F6F9),
                      disabledForegroundColor: const Color(0xFFF3F6F9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFFF3F6F9),
                              ),
                            ),
                          )
                        : const Text(
                            'إرسال',
                            textDirection: TextDirection.rtl,
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w600,
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
    );
  }

  bool get _isFormValid {
    final selectedLocation = ref.read(reportLocationProvider).selectedLatLng;
    final hasSubCategory = _resolveSubCategory()?.trim().isNotEmpty == true;
    final hasSubCategoryId =
        (_selectedCategory?.subCategories ?? []).isEmpty ||
        _resolveSubCategoryId() != null;

    return _selectedCategory != null &&
        hasSubCategory &&
        hasSubCategoryId &&
        _visibility != null &&
        _titleController.text.trim().isNotEmpty &&
        _descriptionController.text.trim().isNotEmpty &&
        selectedLocation != null;
  }

  String _mapVisibilityToApi(String value) {
    switch (value) {
      case 'عام':
        return 'Public';
      case 'مجهول':
        return 'Anonymous';
      case 'سري':
        return 'Confidential';
      default:
        return 'Public';
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _imagePicker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1440,
    );
    if (!mounted || picked == null) return;
    setState(() {
      _selectedImage = picked;
    });
  }

  Widget _buildHeader(
    BuildContext context, {
    required Color headerColor,
    required Color headerTextColor,
  }) {
    return Container(
      height: 100,
      color: headerColor,
      child: Stack(
        children: [
          Positioned(
            left: 16,
            top: 52,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Icon(
                Icons.arrow_forward_ios,
                color: headerTextColor,
                size: 24,
              ),
            ),
          ),
          Positioned.fill(
            child: Align(
              alignment: Alignment(0, 0.32),
              child: Text(
                'إضافة بلاغ',
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontSize: 40 * 0.525,
                  fontWeight: FontWeight.w600,
                  color: headerTextColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required Color borderColor,
    required Color textColor,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: Theme.of(context).scaffoldBackgroundColor,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: textColor),
          style: TextStyle(
            fontSize: 17,
            color: textColor,
            fontWeight: FontWeight.w400,
          ),
          hint: Align(
            alignment: Alignment.centerRight,
            child: Text(
              hint,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontSize: 17,
                color: textColor,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          onChanged: onChanged,
          items: items
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  alignment: Alignment.centerRight,
                  child: Text(item, textDirection: TextDirection.rtl),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown({
    required Color borderColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<CategoryOption>(
          value: _selectedCategory,
          isExpanded: true,
          dropdownColor: Theme.of(context).scaffoldBackgroundColor,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: textColor),
          style: TextStyle(
            fontSize: 17,
            color: textColor,
            fontWeight: FontWeight.w400,
          ),
          hint: Align(
            alignment: Alignment.centerRight,
            child: Text(
              'التصنيف الرئيسي',
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontSize: 17,
                color: textColor,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          onChanged: (value) {
            setState(() {
              _selectedCategory = value;
              _selectedSubCategory = null;
            });
          },
          items: _categoryOptions
              .map(
                (option) => DropdownMenuItem<CategoryOption>(
                  value: option,
                  alignment: Alignment.centerRight,
                  child: Text(option.name, textDirection: TextDirection.rtl),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildSubCategoryDropdown({
    required Color borderColor,
    required Color textColor,
  }) {
    final subCategories =
        _selectedCategory?.subCategories ?? const <SubCategoryOption>[];
    final hasSubCategories = subCategories.isNotEmpty;
    final hasCategory = _selectedCategory != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<SubCategoryOption>(
          value: _selectedSubCategory,
          isExpanded: true,
          dropdownColor: Theme.of(context).scaffoldBackgroundColor,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: textColor),
          style: TextStyle(
            fontSize: 17,
            color: textColor,
            fontWeight: FontWeight.w400,
          ),
          hint: Align(
            alignment: Alignment.centerRight,
            child: Text(
              hasCategory
                  ? (hasSubCategories ? 'التصنيف الفرعي' : 'لا يوجد تصنيف فرعي')
                  : 'التصنيف الفرعي',
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontSize: 17,
                color: textColor,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          onChanged: hasSubCategories
              ? (value) => setState(() => _selectedSubCategory = value)
              : null,
          items: subCategories
              .map(
                (option) => DropdownMenuItem<SubCategoryOption>(
                  value: option,
                  alignment: Alignment.centerRight,
                  child: Text(option.name, textDirection: TextDirection.rtl),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  String? _resolveSubCategory() {
    final category = _selectedCategory;
    if (category == null) return null;
    if (category.subCategories.isEmpty) return category.name;
    return _selectedSubCategory?.name;
  }

  String? _resolveSubCategoryId() {
    final category = _selectedCategory;
    if (category == null || category.subCategories.isEmpty) return null;
    return _selectedSubCategory?.id;
  }

  Widget _buildLocationSelector({
    required ReportLocationState locationState,
    required Color borderColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 17),
      child: GestureDetector(
        onTap: () => _handleLocationSelectorTap(locationState),
        child: Container(
          height: 190,
          decoration: BoxDecoration(
            border: Border.all(color: borderColor, width: 1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                Positioned.fill(child: _buildLocationPreview(locationState)),
                Positioned(
                  right: 10,
                  left: 10,
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _locationCaption(locationState),
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.map_outlined, size: 16),
                        SizedBox(width: 6),
                        Text('اختيار من الخريطة'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationPreview(ReportLocationState locationState) {
    if (locationState.isLoading) {
      return Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      );
    }

    if (!locationState.canShowMap) {
      return Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_disabled_outlined, size: 40),
            const SizedBox(height: 8),
            Text(
              _accessStatusHint(locationState.accessStatus),
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    if (locationState.canShowMap && locationState.selectedLatLng != null) {
      final selected = locationState.selectedLatLng!;

      return IgnorePointer(
        child: MapScreen(
          initialTarget: selected,
          initialZoom: 15,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          markers: {
            Marker(
              markerId: const MarkerId('selected-report-location-preview'),
              position: selected,
            ),
          },
        ),
      );
    }

    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: const Icon(Icons.location_on_outlined, size: 42),
    );
  }

  String _locationCaption(ReportLocationState state) {
    if (!state.canShowMap) {
      return _accessStatusHint(state.accessStatus);
    }

    if (state.selectedLatLng == null) {
      if (state.isLoading) {
        return 'جاري تحديد موقعك الحالي...';
      }
      return 'اضغط لاختيار موقع البلاغ من الخريطة';
    }

    final position = state.selectedLatLng!;
    final fallback =
        'Lat: ${position.latitude.toStringAsFixed(5)} - Lng: ${position.longitude.toStringAsFixed(5)}';

    if (state.isResolvingAddress) {
      return 'جاري جلب العنوان... $fallback';
    }

    if (state.selectedAddress != null && state.selectedAddress!.isNotEmpty) {
      return state.selectedAddress!;
    }

    return fallback;
  }

  String _accessStatusHint(LocationAccessStatus status) {
    return switch (status) {
      LocationAccessStatus.serviceDisabled =>
        'خدمة الموقع متوقفة. اضغط لفتح إعدادات الموقع',
      LocationAccessStatus.permanentlyDenied =>
        'إذن الموقع مرفوض نهائيا. اضغط لفتح إعدادات التطبيق',
      LocationAccessStatus.denied =>
        'يرجى السماح بإذن الموقع لاختيار موقع البلاغ',
      LocationAccessStatus.granted => 'اضغط لاختيار موقع البلاغ من الخريطة',
    };
  }

  Future<void> _handleLocationSelectorTap(
    ReportLocationState locationState,
  ) async {
    final notifier = ref.read(reportLocationProvider.notifier);

    if (!locationState.canShowMap) {
      switch (locationState.accessStatus) {
        case LocationAccessStatus.serviceDisabled:
          await notifier.openDeviceLocationSettings();
          break;
        case LocationAccessStatus.permanentlyDenied:
          await notifier.openPermissionSettings();
          break;
        case LocationAccessStatus.denied:
          break;
        case LocationAccessStatus.granted:
          break;
      }

      await notifier.initialize();
      return;
    }

    final selectedLocation = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(builder: (_) => const SelectReportLocationPage()),
    );

    if (!mounted || selectedLocation == null) return;
    await notifier.selectLocation(selectedLocation);
  }

  String _extractErrorMessage(Object error) {
    if (error is Exception) {
      final message = error.toString();
      if (message.contains('Missing auth token')) {
        return 'يرجى تسجيل الدخول أولا';
      } else if (message.contains('Missing sub category id')) {
        return 'يرجى اختيار التصنيف الفرعي';
      } else if (message.contains('ApiException')) {
        return 'فشل الاتصال بالخادم. يرجى المحاولة لاحقا';
      } else if (message.contains('SocketException')) {
        return 'لا يوجد اتصال بالإنترنت';
      }
      return message.replaceAll('Exception: ', '');
    }
    return 'حدث خطأ غير متوقع';
  }
}

class _InputBox extends StatelessWidget {
  final double height;
  final String hint;
  final Color borderColor;
  final Color hintColor;
  final Color textColor;
  final TextEditingController controller;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  const _InputBox({
    required this.height,
    required this.hint,
    required this.borderColor,
    required this.hintColor,
    required this.textColor,
    required this.controller,
    required this.maxLines,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
        style: TextStyle(color: textColor),
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          hintTextDirection: TextDirection.rtl,
          hintStyle: TextStyle(
            fontSize: 17,
            color: hintColor,
            fontWeight: FontWeight.w400,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.only(
            top: 9,
            right: 10,
            left: 10,
            bottom: 9,
          ),
        ),
      ),
    );
  }
}

class _UploadActionBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color borderColor;
  final Color textColor;
  final VoidCallback onTap;

  const _UploadActionBox({
    required this.icon,
    required this.label,
    required this.borderColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 104,
        height: 80,
        decoration: BoxDecoration(
          border: Border.all(
            color: borderColor,
            width: 1,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(icon, color: textColor, size: 40),
            const SizedBox(height: 4),
            Text(
              label,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontSize: 17,
                color: textColor,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
