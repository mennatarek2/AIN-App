import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/app_layout_primitives.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/image_source_picker_sheet.dart';
import '../../../../core/widgets/profile_photo_image.dart';
import '../../domain/profile_validators.dart';
import '../providers/profile_provider.dart';
import '../widgets/profile_state_banner.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;

  String? _selectedImagePath;
  bool _isSaving = false;
  bool _fieldsInitialized = false;

  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
  }

  void _initializeFieldsFromProfile(UserProfile profile) {
    if (_fieldsInitialized || _isSaving) return;
    _nameController.text = profile.name;
    _phoneController.text = profile.phone;
    _fieldsInitialized = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickProfilePhoto() async {
    try {
      final picked = await pickImageWithSourceChoice(
        context,
        _imagePicker,
        title: 'صورة الملف الشخصي',
      );

      if (picked == null) return;

      if (!ProfileValidators.isAllowedProfilePhoto(picked.path)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('يُسمح فقط بصور jpg أو jpeg أو png'),
              backgroundColor: context.semantic.error,
            ),
          );
        }
        return;
      }

      setState(() => _selectedImagePath = picked.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في تحديد الصورة: $e'),
            backgroundColor: context.semantic.error,
          ),
        );
      }
    }
  }

  Future<void> _save() async {
    if (_isSaving) return;

    final profile = ref.read(profileProvider);
    if (profile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('تعذر تحميل بيانات الملف الشخصي'),
          backgroundColor: context.semantic.error,
        ),
      );
      return;
    }

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    final nameError = ProfileValidators.validateDisplayName(name);
    if (nameError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(nameError),
          backgroundColor: context.semantic.error,
        ),
      );
      return;
    }

    final phoneError = ProfileValidators.validatePhoneNumber(phone);
    if (phoneError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(phoneError),
          backgroundColor: context.semantic.error,
        ),
      );
      return;
    }

    final nameChanged = name != profile.name;
    final phoneChanged = phone != profile.phone;
    final photoChanged =
        _selectedImagePath != null && _selectedImagePath!.trim().isNotEmpty;

    if (!nameChanged && !phoneChanged && !photoChanged) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('لم يتم إجراء أي تغييرات')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      await ref
          .read(profileAsyncProvider.notifier)
          .updateProfileData(
            displayName: nameChanged ? name : null,
            phoneNumber: phoneChanged ? phone : null,
            profilePhotoPath: photoChanged ? _selectedImagePath : null,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تم حفظ التعديلات بنجاح ✓'),
            backgroundColor: context.semantic.success,
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في حفظ التعديلات: $e'),
            backgroundColor: context.semantic.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileAsyncProvider);
    final profile = ref.watch(profileProvider);
    final resolvedPhotoUrl = ref.watch(profilePhotoUrlProvider);
    if (profile != null) {
      _initializeFieldsFromProfile(profile);
    }
    final isLoading = profileAsync.isLoading;
    final errorText = profileAsync.hasError
        ? 'حدث خطأ: ${profileAsync.error}'
        : null;

    final displayPhotoPath = _selectedImagePath ?? resolvedPhotoUrl;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Column(
          children: [
            AppPageHeader(
              title: 'تعديل الملف الشخصي',
              subtitle: 'حدّث بياناتك الشخصية',
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                child: Column(
                  children: [
                    ProfileStateBanner(
                      isLoading: isLoading && !_isSaving,
                      errorText: errorText,
                      onRetry: () =>
                          ref.read(profileAsyncProvider.notifier).refresh(),
                    ),
                    if (_isSaving)
                      LinearProgressIndicator(
                        backgroundColor: context.colors.primary.withValues(
                          alpha: 0.15,
                        ),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          context.colors.primary,
                        ),
                      ),
                    const SizedBox(height: AppSpacing.lg),
                    _EditableProfileAvatar(
                      imagePath: displayPhotoPath,
                      onTap: _isSaving ? null : _pickProfilePhoto,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'اضغط لتغيير الصورة',
                      style: context.text.bodySmall?.copyWith(
                        color: context.semantic.textMuted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Transform.translate(
                      offset: const Offset(0, -AppSpacing.sm),
                      child: AppFormCard(
                        title: 'معلومات قابلة للتعديل',
                        subtitle: 'يمكنك تحديث الاسم ورقم الهاتف',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _ProfileTextField(
                              hint: 'اسم العرض',
                              icon: Icons.person_outline_rounded,
                              controller: _nameController,
                              enabled: !_isSaving && profile != null,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _ProfileTextField(
                              hint: 'رقم الهاتف',
                              icon: Icons.phone_outlined,
                              controller: _phoneController,
                              enabled: !_isSaving && profile != null,
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: AppSpacing.md),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppFormCard(
                      title: 'معلومات الحساب',
                      subtitle: 'للعرض فقط',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _ProfileReadOnlyField(
                            label: 'البريد الإلكتروني',
                            value: profile?.email ?? '',
                            icon: Icons.email_outlined,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _ProfileReadOnlyField(
                            label: 'اسم المستخدم',
                            value: profile?.username.trim().isNotEmpty == true
                                ? '@${profile!.username}'
                                : '',
                            icon: Icons.alternate_email_rounded,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _ProfileReadOnlyField(
                            label: 'رقم الهوية الشخصية',
                            value: profile?.ssn ?? '',
                            icon: Icons.badge_outlined,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenHorizontal,
                      ),
                      child: SizedBox(
                        height: 52,
                        width: double.infinity,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppRadius.xl),
                            gradient: (_isSaving || profile == null)
                                ? null
                                : context.primaryGradient,
                            color: (_isSaving || profile == null)
                                ? context.semantic.borderStrong
                                : null,
                            boxShadow: (_isSaving || profile == null)
                                ? null
                                : [
                                    BoxShadow(
                                      color: context.colors.primary.withValues(
                                        alpha: 0.35,
                                      ),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(AppRadius.xl),
                              onTap: (_isSaving || profile == null)
                                  ? null
                                  : _save,
                              child: Center(
                                child: _isSaving
                                    ? SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: context.semantic.textOnPrimary,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : Text(
                                        'حفظ التعديلات',
                                        style: context.text.titleMedium
                                            ?.copyWith(
                                              color: context
                                                  .semantic
                                                  .textOnPrimary,
                                              fontWeight: FontWeight.w700,
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
          ],
        ),
      ),
    );
  }
}

class _EditableProfileAvatar extends StatelessWidget {
  const _EditableProfileAvatar({this.imagePath, this.onTap});

  final String? imagePath;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 132,
            height: 132,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: context.colors.primary.withValues(alpha: 0.35),
                width: 3,
              ),
              boxShadow: context.cardShadows,
            ),
            clipBehavior: Clip.antiAlias,
            child: ProfilePhotoImage(
              imagePath: imagePath,
              fit: BoxFit.cover,
              width: 132,
              height: 132,
            ),
          ),
          Positioned(
            bottom: 0,
            child: Container(
              width: 132,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(66),
                  bottomRight: Radius.circular(66),
                ),
              ),
              child: Icon(
                Icons.camera_alt_outlined,
                color: context.semantic.textOnPrimary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileTextField extends StatelessWidget {
  const _ProfileTextField({
    required this.hint,
    required this.icon,
    required this.controller,
    this.enabled = true,
    this.keyboardType,
  });

  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final bool enabled;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      textAlign: TextAlign.right,
      textDirection: TextDirection.rtl,
      keyboardType: keyboardType,
      style: context.text.bodyLarge,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: context.colors.primary, size: 22),
        filled: true,
        fillColor: context.semantic.surfaceInput,
      ),
    );
  }
}

class _ProfileReadOnlyField extends StatelessWidget {
  const _ProfileReadOnlyField({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: context.text.labelMedium?.copyWith(
            color: context.semantic.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 2,
          ),
          decoration: BoxDecoration(
            color: context.semantic.surfaceInput.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: context.semantic.borderSubtle),
          ),
          child: Row(
            children: [
              Icon(icon, color: context.semantic.textMuted, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  value.trim().isEmpty ? '—' : value,
                  style: context.text.bodyLarge?.copyWith(
                    color: context.semantic.textMuted,
                  ),
                ),
              ),
              Icon(
                Icons.lock_outline_rounded,
                size: 16,
                color: context.semantic.textMuted,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
