import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/cached_app_image.dart';
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
  late final TextEditingController _usernameController;

  /// Local file path chosen from camera/gallery (for instant preview)
  String? _selectedImagePath;

  /// Whether we are currently uploading/saving
  bool _isSaving = false;

  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider);
    _nameController = TextEditingController(text: profile?.name ?? '');
    _phoneController = TextEditingController(text: profile?.phone ?? '');
    _usernameController = TextEditingController(text: profile?.username ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Image Picker
  // ---------------------------------------------------------------------------

  /// Show bottom sheet letting user pick camera, gallery, or remove photo
  void _showImagePickerBottomSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = ref.read(profileProvider);
    final hasCurrentPhoto =
        _selectedImagePath != null ||
        (profile?.profilePhotoUrl != null &&
            profile!.profilePhotoUrl!.isNotEmpty);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? const Color(0xFF121A5C) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  'تغيير صورة الملف الشخصي',
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFFF3F6F9)
                        : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 20),
                _BottomSheetOption(
                  icon: Icons.camera_alt_outlined,
                  label: 'التقاط صورة',
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _pickImage(ImageSource.camera);
                  },
                ),
                _BottomSheetOption(
                  icon: Icons.photo_library_outlined,
                  label: 'اختيار من المعرض',
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _pickImage(ImageSource.gallery);
                  },
                ),
                if (hasCurrentPhoto)
                  _BottomSheetOption(
                    icon: Icons.delete_outline,
                    label: 'إزالة الصورة الحالية',
                    color: Colors.red,
                    onTap: () {
                      Navigator.of(ctx).pop();
                      setState(() => _selectedImagePath = null);
                    },
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Pick image from [source] (camera or gallery)
  Future<void> _pickImage(ImageSource source) async {
    try {
      print('[EditProfile] Picking image from: $source');
      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (picked == null) {
        print('[EditProfile] No image selected');
        return;
      }

      print('[EditProfile] Image selected: ${picked.path}');
      setState(() => _selectedImagePath = picked.path);
    } catch (e) {
      print('[EditProfile] Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في تحديد الصورة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Save
  // ---------------------------------------------------------------------------

  Future<void> _save() async {
    if (_isSaving) return;

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final username = _usernameController.text.trim();

    print('[EditProfile] Saving profile...');
    print('[EditProfile] Name: $name');
    print('[EditProfile] Phone: $phone');
    print('[EditProfile] Username: $username');
    print('[EditProfile] Photo path: $_selectedImagePath');

    setState(() => _isSaving = true);

    try {
      await ref.read(profileAsyncProvider.notifier).updateProfileData(
        displayName: name.isNotEmpty ? name : null,
        phoneNumber: phone.isNotEmpty ? phone : null,
        userName: username.isNotEmpty ? username : null,
        profilePhotoPath: _selectedImagePath,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ التعديلات بنجاح ✓'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('[EditProfile] Save failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في حفظ التعديلات: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageBackground = isDark
        ? const Color(0xFF060C3A)
        : AppColors.backgroundLight;
    final primaryTextColor = isDark
        ? const Color(0xFFF3F6F9)
        : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark
        ? const Color(0xFFF3F6F9)
        : const Color(0x80060C3A);

    final profileAsync = ref.watch(profileAsyncProvider);
    final profile = ref.watch(profileProvider);
    final isLoading = profileAsync.isLoading;
    final errorText = profileAsync.hasError
        ? 'حدث خطأ: ${profileAsync.error}'
        : null;

    // Determine which photo to display:
    // 1) Local selected image (instant preview) takes priority
    // 2) Then server photo URL
    // 3) Then default avatar
    final String? displayPhotoPath =
        _selectedImagePath ?? profile?.profilePhotoUrl;

    return Scaffold(
      backgroundColor: pageBackground,
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _EditProfileHeader(onBack: () => Navigator.of(context).pop()),
              ProfileStateBanner(
                isLoading: isLoading && !_isSaving,
                errorText: errorText,
                onRetry: () =>
                    ref.read(profileAsyncProvider.notifier).refresh(),
              ),

              // Upload progress indicator
              if (_isSaving)
                const LinearProgressIndicator(
                  backgroundColor: Color(0xFFBAD6F4),
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0099FF)),
                ),

              const SizedBox(height: 30),

              // Tappable profile avatar with edit badge
              _EditableProfileAvatar(
                imagePath: displayPhotoPath,
                onTap: _isSaving ? null : _showImagePickerBottomSheet,
              ),
              const SizedBox(height: 16),
              Text(
                profile?.name ?? 'بلا اسم',
                style: TextStyle(
                  fontSize: 40 * 0.525,
                  fontWeight: FontWeight.w600,
                  color: primaryTextColor,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                textDirection: TextDirection.rtl,
                children: [
                  Icon(
                    Icons.circle,
                    size: 12,
                    color: profile?.levelDotColor ?? Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    profile?.level ?? 'مستخدم جديد',
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w400,
                      color: secondaryTextColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _LabeledField(
                      label: 'الاسم',
                      controller: _nameController,
                      enabled: !_isSaving,
                    ),
                    const SizedBox(height: 14),
                    _LabeledField(
                      label: 'رقم الهاتف المحمول',
                      controller: _phoneController,
                      enabled: !_isSaving,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 14),
                    _LabeledField(
                      label: 'اسم المستخدم',
                      controller: _usernameController,
                      enabled: !_isSaving,
                    ),
                    const SizedBox(height: 28),
                    // Save button — disabled while uploading
                    AnimatedOpacity(
                      opacity: _isSaving ? 0.6 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        width: 300,
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
                          onPressed: _isSaving ? null : _save,
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFFF3F6F9),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'حفظ التعديلات',
                                  textDirection: TextDirection.rtl,
                                  style: TextStyle(
                                    fontSize: 21,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==============================================================================
// WIDGETS
// ==============================================================================

class _EditProfileHeader extends StatelessWidget {
  const _EditProfileHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? const Color(0xFFF3F6F9)
        : AppColors.textPrimaryLight;

    return Container(
      width: double.infinity,
      height: 100,
      color: isDark ? const Color(0xFF121A5C) : AppColors.primarySoft,
      child: Stack(
        children: [
          Positioned(
            left: 16,
            top: 52,
            child: GestureDetector(
              onTap: onBack,
              child: Icon(Icons.arrow_forward_ios, color: textColor, size: 24),
            ),
          ),
          Positioned.fill(
            child: Align(
              alignment: const Alignment(0, 0.32),
              child: Text(
                'تعديل الملف الشخصي',
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontSize: 40 * 0.525,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tappable profile avatar with pencil-edit badge overlay.
///
/// [imagePath] can be:
///   - A local file path (for instant preview after gallery/camera pick)
///   - An http/https URL (from server)
///   - null (shows default avatar)
class _EditableProfileAvatar extends StatelessWidget {
  const _EditableProfileAvatar({this.imagePath, this.onTap});

  final String? imagePath;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasImage = imagePath != null && imagePath!.trim().isNotEmpty;

    print('[_EditableProfileAvatar] imagePath: $imagePath, hasImage: $hasImage');

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Avatar circle
          Container(
            width: 148,
            height: 148,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark
                    ? const Color(0xFFF3F6F9)
                    : const Color(0x80415789),
                width: 1,
              ),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFBAD6F4), Color(0xFFB8D0EE)],
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x40000000),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: _buildImage(hasImage),
          ),

          // Semi-transparent edit overlay (shown at bottom of circle)
          Positioned(
            bottom: 0,
            child: Container(
              width: 148,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(74),
                  bottomRight: Radius.circular(74),
                ),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt, color: Colors.white, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(bool hasImage) {
    if (!hasImage) {
      return Image.asset(
        'assets/images/user_chatbot.png',
        fit: BoxFit.cover,
      );
    }

    final path = imagePath!.trim();

    // Local file path (from camera/gallery picker)
    final isLocalFile = path.startsWith('/') ||
        path.startsWith('file://') ||
        RegExp(r'^[a-zA-Z]:[\\/]').hasMatch(path) ||
        path.startsWith('/data/') ||
        path.startsWith('/storage/') ||
        path.startsWith('/sdcard/');

    if (isLocalFile) {
      final file = File(path.startsWith('file://')
          ? Uri.parse(path).toFilePath()
          : path);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover);
      }
      // File doesn't exist, fall through to default
      return Image.asset('assets/images/user_chatbot.png', fit: BoxFit.cover);
    }

    // Network URL
    return CachedAppImage(imagePath: path, fit: BoxFit.cover);
  }
}

class _BottomSheetOption extends StatelessWidget {
  const _BottomSheetOption({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultColor = isDark
        ? const Color(0xFFF3F6F9)
        : AppColors.textPrimaryLight;
    final effectiveColor = color ?? defaultColor;

    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: effectiveColor, size: 26),
      title: Text(
        label,
        textDirection: TextDirection.rtl,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: effectiveColor,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.controller,
    this.enabled = true,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final bool enabled;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark
        ? const Color(0xFFF3F6F9)
        : const Color(0xFF596186);
    final fieldBorderColor = isDark
        ? const Color(0xFFF3F6F9)
        : const Color(0xF2060C3A);
    final fieldBackground = isDark ? const Color(0xFF060C3A) : Colors.white;
    final inputTextColor = isDark
        ? const Color(0xFFF3F6F9)
        : AppColors.textPrimaryLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 4, bottom: 6),
          child: Text(
            label,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 40 * 0.525,
              fontWeight: FontWeight.w400,
              color: labelColor,
            ),
          ),
        ),
        Container(
          height: 50,
          decoration: BoxDecoration(
            color: enabled ? fieldBackground : fieldBackground.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: fieldBorderColor, width: 1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            enabled: enabled,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            keyboardType: keyboardType,
            style: TextStyle(
              fontSize: 17,
              color: inputTextColor,
              fontWeight: FontWeight.w400,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
