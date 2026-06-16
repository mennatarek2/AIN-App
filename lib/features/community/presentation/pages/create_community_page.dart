import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/community_remote_data_source.dart';
import '../providers/communities_provider.dart';
import 'confirm_community_added_page.dart';

class CreateCommunityPage extends ConsumerStatefulWidget {
  const CreateCommunityPage({super.key});

  @override
  ConsumerState<CreateCommunityPage> createState() => _CreateCommunityPageState();
}

class _CreateCommunityPageState extends ConsumerState<CreateCommunityPage> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  CommunityType _selectedType = CommunityType.neighborhood;
  int _radiusMeters = CommunityType.neighborhood.defaultRadiusMeters!;
  bool _isSubmitting = false;
  String? _nameError;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onTypeChanged(CommunityType type) {
    setState(() {
      _selectedType = type;
      if (type.hasRadius) {
        _radiusMeters = type.defaultRadiusMeters!;
      }
    });
  }

  String? _validateName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'اسم المجتمع مطلوب';
    if (trimmed.length < 3) return 'الاسم يجب أن يكون 3 أحرف على الأقل';
    if (trimmed.length > 100) return 'الاسم يجب ألا يتجاوز 100 حرف';
    return null;
  }

  Future<void> _onCommunityCreated(CreateCommunityResponseDto community) async {
    if (community.inviteCode != null) {
      await showDialog<void>(
        context: context,
        builder: (_) => _InviteCodeDialog(
          code: community.inviteCode!,
          communityName: community.name,
        ),
      );
    }

    if (community.userDetails.userLocation == null) {
      ref.read(communitiesProvider.notifier).showLocationPendingBanner(
            communityId: community.id,
          );
    }
  }

  Future<void> _submitCreate() async {
    final nameError = _validateName(_nameController.text);
    if (nameError != null) {
      setState(() => _nameError = nameError);
      return;
    }

    setState(() {
      _nameError = null;
      _isSubmitting = true;
    });

    final description = _descriptionController.text.trim();
    final result = await ref.read(communitiesProvider.notifier).createCommunity(
          name: _nameController.text.trim(),
          description: description.isEmpty ? null : description,
          communityType: _selectedType.value,
          coverageRadiusMeters:
              _selectedType.hasRadius ? _radiusMeters : null,
        );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result == null) {
      final err = ref.read(communitiesProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _humanizeError(err),
            textDirection: TextDirection.rtl,
          ),
        ),
      );
      return;
    }

    await _onCommunityCreated(result);

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ConfirmCommunityAddedPage(),
      ),
    );
  }

  String _humanizeError(String? raw) {
    if (raw == null) return 'تعذر إنشاء المجتمع، حاول مرة أخرى';
    final lower = raw.toLowerCase();
    if (lower.contains('location')) {
      return 'تم إنشاء المجتمع — شارك موقعك لتفعيل جميع الميزات';
    }
    if (lower.contains('401') || lower.contains('unauthorized')) {
      return 'يرجى تسجيل الدخول مرة أخرى';
    }
    return 'تعذر إنشاء المجتمع، حاول مرة أخرى';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageBackground =
        isDark ? const Color(0xFF060C3A) : AppColors.backgroundLight;
    final textPrimary =
        isDark ? const Color(0xFFF3F6F9) : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Scaffold(
      backgroundColor: pageBackground,
      body: Column(
        children: [
          _Header(
            title: 'إنشاء مجتمع جديد',
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SectionLabel('اسم المجتمع', textPrimary),
                  const SizedBox(height: 8),
                  _TextField(
                    controller: _nameController,
                    hintText: 'مثال: حي الزمالك',
                    errorText: _nameError,
                    onChanged: (_) {
                      if (_nameError != null) {
                        setState(() => _nameError = null);
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  _SectionLabel('الوصف (اختياري)', textPrimary),
                  const SizedBox(height: 8),
                  _TextField(
                    controller: _descriptionController,
                    hintText: 'وصف قصير عن المجتمع',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  _SectionLabel('نوع المجتمع', textPrimary),
                  const SizedBox(height: 10),
                  ...CommunityType.values.map(
                    (type) => _TypeOptionCard(
                      type: type,
                      isSelected: _selectedType == type,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      onTap: () => _onTypeChanged(type),
                    ),
                  ),
                  if (_selectedType.hasRadius) ...[
                    const SizedBox(height: 24),
                    _SectionLabel('نطاق التغطية', textPrimary),
                    const SizedBox(height: 4),
                    Text(
                      'المسافة التي يمكن للأعضاء القريبين اكتشاف المجتمع ضمنها',
                      textDirection: TextDirection.rtl,
                      style: TextStyle(fontSize: 12, color: textSecondary),
                    ),
                    const SizedBox(height: 12),
                    _RadiusSelector(
                      value: _radiusMeters,
                      min: _selectedType == CommunityType.building ? 50 : 200,
                      max: _selectedType == CommunityType.building ? 500 : 2000,
                      onChanged: (v) => setState(() => _radiusMeters = v),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        const Icon(
                          Icons.key_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'بعد الإنشاء ستظهر لك كود دعوة لمشاركته مع الأعضاء',
                            textDirection: TextDirection.rtl,
                            style: TextStyle(
                              fontSize: 12,
                              color: textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
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
                        onPressed: _isSubmitting ? null : _submitCreate,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'إنشاء المجتمع',
                                textDirection: TextDirection.rtl,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? const Color(0xFFF3F6F9)
                                      : AppColors.backgroundLight,
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
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? const Color(0xFFF3F6F9) : AppColors.textPrimaryLight;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
      color: isDark ? const Color(0xFF121A5C) : AppColors.primarySoft,
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Expanded(
            child: Text(
              title,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ),
          GestureDetector(
            onTap: onBack,
            child: Icon(
              Icons.arrow_forward_ios,
              color: textColor,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label, this.color);

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        label,
        textDirection: TextDirection.rtl,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  const _TextField({
    required this.controller,
    required this.hintText,
    this.errorText,
    this.maxLines = 1,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final String? errorText;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fieldBackground = isDark ? const Color(0xFF0D1445) : Colors.white;
    final fieldBorderColor = isDark
        ? const Color(0xFFF3F6F9).withValues(alpha: 0.3)
        : const Color(0x4D060C3A);
    final hintColor = isDark
        ? const Color(0xE6F3F6F9)
        : const Color(0xB3060C3A);
    final textColor =
        isDark ? const Color(0xFFF3F6F9) : AppColors.textPrimaryLight;

    return TextField(
      controller: controller,
      onChanged: onChanged,
      maxLines: maxLines,
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.right,
      decoration: InputDecoration(
        hintText: hintText,
        hintTextDirection: TextDirection.rtl,
        errorText: errorText,
        hintStyle: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: hintColor,
        ),
        filled: true,
        fillColor: fieldBackground,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: fieldBorderColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.3),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.3),
        ),
      ),
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: textColor,
      ),
    );
  }
}

class _TypeOptionCard extends StatelessWidget {
  const _TypeOptionCard({
    required this.type,
    required this.isSelected,
    required this.textPrimary,
    required this.textSecondary,
    required this.onTap,
  });

  final CommunityType type;
  final bool isSelected;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback onTap;

  IconData get _icon => switch (type) {
        CommunityType.neighborhood => Icons.location_city_rounded,
        CommunityType.building => Icons.apartment_rounded,
        CommunityType.privateGroup => Icons.lock_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isSelected
        ? AppColors.primary.withValues(alpha: 0.12)
        : (isDark ? const Color(0xFF0D1445) : Colors.white);
    final border = isSelected
        ? AppColors.primary
        : (isDark
            ? const Color(0xFFF3F6F9).withValues(alpha: 0.2)
            : const Color(0xFFE5E7EB));

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border, width: isSelected ? 1.5 : 1),
            ),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                Icon(
                  _icon,
                  color: isSelected ? AppColors.primary : textSecondary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        type.labelAr,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        type.descriptionAr,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(fontSize: 12, color: textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: isSelected ? AppColors.primary : textSecondary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RadiusSelector extends StatelessWidget {
  const _RadiusSelector({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF0D1445) : Colors.white;
    final textColor =
        isDark ? const Color(0xFFF3F6F9) : AppColors.textPrimaryLight;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? const Color(0xFFF3F6F9).withValues(alpha: 0.2)
              : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        children: [
          Text(
            '$value متر',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          Slider(
            value: value.toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: ((max - min) ~/ 50).clamp(1, 40),
            label: '$value م',
            activeColor: AppColors.primary,
            onChanged: (v) => onChanged(v.round()),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$min م', style: TextStyle(fontSize: 11, color: textColor)),
              Text('$max م', style: TextStyle(fontSize: 11, color: textColor)),
            ],
          ),
        ],
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
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: code));
              if (!context.mounted) return;
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
          TextButton.icon(
            onPressed: () => Share.share(
              'Join my community on AIN! Use code: $code',
            ),
            icon: const Icon(Icons.share, size: 16),
            label: const Text('مشاركة الكود'),
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
