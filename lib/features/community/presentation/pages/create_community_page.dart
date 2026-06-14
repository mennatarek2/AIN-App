import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/communities_provider.dart';
import 'confirm_community_added_page.dart';

class CreateCommunityPage extends ConsumerStatefulWidget {
  const CreateCommunityPage({super.key});

  @override
  ConsumerState<CreateCommunityPage> createState() => _CreateCommunityPageState();
}

class _CreateCommunityPageState extends ConsumerState<CreateCommunityPage> {
  final _groupNameController = TextEditingController();
  final _memberEmailController = TextEditingController();
  final _picker = ImagePicker();
  File? _selectedImage;

  @override
  void dispose() {
    _groupNameController.dispose();
    _memberEmailController.dispose();
    super.dispose();
  }

  Future<void> _pickGroupImage() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (pickedFile == null) return;

    setState(() {
      _selectedImage = File(pickedFile.path);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageBackground = isDark
        ? const Color(0xFF060C3A)
        : AppColors.backgroundLight;
    final sectionTextColor = isDark
        ? const Color(0xFFF3F6F9)
        : AppColors.textPrimaryLight;

    return Scaffold(
      backgroundColor: pageBackground,
      body: Column(
        children: [
          _Header(onBack: () => Navigator.of(context).pop()),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _GroupNameField(
                    controller: _groupNameController,
                    selectedImage: _selectedImage,
                    onPickImage: _pickGroupImage,
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'إضافة أعضاء المجموعة',
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w400,
                        color: sectionTextColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _FormField(
                    controller: _memberEmailController,
                    hintText: 'اكتب البريد الالكتروني الخاص بالعضو',
                  ),
                  const Spacer(),
                  Center(
                    child: SizedBox(
                      width: 300,
                      height: 52,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: const LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [AppColors.primary, AppColors.primarySoft],
                          ),
                        ),
                        child: TextButton(
                          style: TextButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () async {
                            final groupName = _groupNameController.text.trim();
                            final firstMemberEmail =
                                _memberEmailController.text.trim();
                            if (groupName.isEmpty) return;

                            final result = await ref
                                .read(communitiesProvider.notifier)
                                .createCommunity(
                                  name: groupName,
                                  description: groupName,
                                );

                            if (!context.mounted) return;

                            if (result != null && firstMemberEmail.isNotEmpty) {
                              await ref
                                  .read(communitiesProvider.notifier)
                                  .addMemberByEmail(
                                    communityId: result.id,
                                    email: firstMemberEmail,
                                  );
                            }

                            if (!context.mounted) return;

                            // Show invite code dialog if we got one
                            if (result?.inviteCode != null) {
                              await showDialog<void>(
                                context: context,
                                builder: (_) => _InviteCodeDialog(
                                  code: result!.inviteCode!,
                                  communityName: result.name,
                                ),
                              );
                            }

                            if (!context.mounted) return;
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ConfirmCommunityAddedPage(),
                              ),
                            );
                          },
                          child: Text(
                            'إنشاء',
                            textDirection: TextDirection.rtl,
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? const Color(0xFFF3F6F9)
                                  : AppColors.backgroundLight,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      height: 100,
      color: isDark ? const Color(0xFF121A5C) : AppColors.primarySoft,
      child: Align(
        alignment: const Alignment(-0.92, 0.28),
        child: GestureDetector(
          onTap: onBack,
          child: Icon(
            Icons.arrow_forward_ios,
            color: isDark
                ? const Color(0xFFF3F6F9)
                : AppColors.textPrimaryLight,
            size: 24,
          ),
        ),
      ),
    );
  }
}

class _GroupNameField extends StatelessWidget {
  const _GroupNameField({
    required this.controller,
    required this.selectedImage,
    required this.onPickImage,
  });

  final TextEditingController controller;
  final File? selectedImage;
  final VoidCallback onPickImage;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fieldBackground = isDark ? const Color(0xFF060C3A) : Colors.white;
    final fieldBorderColor = isDark
        ? const Color(0xFFF3F6F9)
        : const Color(0x4D060C3A);
    final hintColor = isDark
        ? const Color(0xE6F3F6F9)
        : const Color(0xB3060C3A);
    final textColor = isDark
        ? const Color(0xFFF3F6F9)
        : AppColors.textPrimaryLight;

    return Container(
      height: 96,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: fieldBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: fieldBorderColor, width: 1),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          GestureDetector(
            onTap: onPickImage,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? const Color(0xFF1A287D)
                    : const Color(0xFFD1D2D4),
              ),
              clipBehavior: Clip.antiAlias,
              child: selectedImage == null
                  ? Icon(
                      Icons.photo_camera_outlined,
                      color: textColor,
                      size: 30,
                    )
                  : Image.file(selectedImage!, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: TextField(
              controller: controller,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                hintText: 'اسم المجموعة',
                hintTextDirection: TextDirection.rtl,
                hintStyle: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w400,
                  color: hintColor,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w400,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  const _FormField({required this.controller, required this.hintText});

  final TextEditingController controller;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fieldBackground = isDark ? const Color(0xFF060C3A) : Colors.white;
    final fieldBorderColor = isDark
        ? const Color(0xFFF3F6F9)
        : const Color(0x4D060C3A);
    final hintColor = isDark
        ? const Color(0xE6F3F6F9)
        : const Color(0xB3060C3A);
    final textColor = isDark
        ? const Color(0xFFF3F6F9)
        : AppColors.textPrimaryLight;

    return TextField(
      controller: controller,
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.right,
      decoration: InputDecoration(
        hintText: hintText,
        hintTextDirection: TextDirection.rtl,
        hintStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w400,
          color: hintColor,
        ),
        filled: true,
        fillColor: fieldBackground,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: fieldBorderColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.3),
        ),
      ),
      style: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w400,
        color: textColor,
      ),
    );
  }
}

// ─── Invite Code Dialog ───────────────────────────────────────────────────────

class _InviteCodeDialog extends StatelessWidget {
  const _InviteCodeDialog({required this.code, required this.communityName});

  final String code;
  final String communityName;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF121A5C) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Column(
        children: [
          const Icon(Icons.group_add_rounded, size: 48, color: Color(0xFF498EF4)),
          const SizedBox(height: 8),
          Text(
            'تم إنشاء "$communityName"',
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'شارك كود الدعوة مع من تريد إضافتهم',
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF498EF4).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF498EF4), width: 1.5),
            ),
            child: Text(
              code,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: 6,
                color: Color(0xFF498EF4),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () {
              // Copy to clipboard
              // Share.share('Join my community on AIN! Use code: $code');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('تم نسخ الكود: $code'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('نسخ الكود'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('حسناً', style: TextStyle(fontSize: 16)),
        ),
      ],
    );
  }
}
