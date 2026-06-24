import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/enums/community_enums.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/app_layout_primitives.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../data/community_remote_data_source.dart';
import '../providers/communities_provider.dart';
import 'confirm_community_added_page.dart';

class CreateCommunityPage extends ConsumerStatefulWidget {
  const CreateCommunityPage({super.key});

  @override
  ConsumerState<CreateCommunityPage> createState() =>
      _CreateCommunityPageState();
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
      ref
          .read(communitiesProvider.notifier)
          .showLocationPendingBanner(communityId: community.id);
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
    final result = await ref
        .read(communitiesProvider.notifier)
        .createCommunity(
          name: _nameController.text.trim(),
          description: description.isEmpty ? null : description,
          communityType: _selectedType.value,
          coverageRadiusMeters: _selectedType.hasRadius ? _radiusMeters : null,
        );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result == null) {
      final err = ref.read(communitiesProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_humanizeError(err), textDirection: TextDirection.rtl),
        ),
      );
      return;
    }

    await _onCommunityCreated(result);

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ConfirmCommunityAddedPage()),
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
    return Scaffold(
      backgroundColor: context.colors.surface,
      body: Column(
        children: [
          AppPageHeader(
            title: 'إنشاء مجتمع جديد',
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppFormCard(
                    title: 'معلومات أساسية',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _FieldLabel('اسم المجتمع'),
                        const SizedBox(height: AppSpacing.xs),
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
                        const SizedBox(height: AppSpacing.md),
                        _FieldLabel('الوصف (اختياري)'),
                        const SizedBox(height: AppSpacing.xs),
                        _TextField(
                          controller: _descriptionController,
                          hintText: 'وصف قصير عن المجتمع',
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppFormCard(
                    title: 'نوع المجتمع',
                    child: Column(
                      children: CommunityType.values
                          .map(
                            (type) => _TypeOptionCard(
                              type: type,
                              isSelected: _selectedType == type,
                              onTap: () => _onTypeChanged(type),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  if (_selectedType.hasRadius) ...[
                    const SizedBox(height: AppSpacing.md),
                    AppFormCard(
                      title: 'نطاق التغطية',
                      subtitle:
                          'المسافة التي يمكن للأعضاء القريبين اكتشاف المجتمع ضمنها',
                      child: _RadiusSelector(
                        value: _radiusMeters,
                        min: _selectedType == CommunityType.building ? 50 : 200,
                        max: _selectedType == CommunityType.building ? 500 : 2000,
                        onChanged: (v) => setState(() => _radiusMeters = v),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenHorizontal,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: context.colors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: context.colors.primary.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        textDirection: TextDirection.rtl,
                        children: [
                          Icon(
                            Icons.key_rounded,
                            color: context.colors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'بعد الإنشاء ستظهر لك كود دعوة لمشاركته مع الأعضاء',
                              textDirection: TextDirection.rtl,
                              style: context.text.bodySmall?.copyWith(
                                color: context.semantic.textMuted,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenHorizontal,
                    ),
                    child: SizedBox(
                      height: 52,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          gradient: context.primaryGradient,
                        ),
                        child: TextButton(
                          style: TextButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                          ),
                          onPressed: _isSubmitting ? null : _submitCreate,
                          child: _isSubmitting
                              ? SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: context.semantic.textOnPrimary,
                                  ),
                                )
                              : Text(
                                  'إنشاء المجتمع',
                                  textDirection: TextDirection.rtl,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: context.semantic.textOnPrimary,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        label,
        textDirection: TextDirection.rtl,
        style: context.text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
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
        filled: true,
        fillColor: context.semantic.surfaceInput,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: context.semantic.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: context.colors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: context.semantic.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: context.semantic.error, width: 1.5),
        ),
      ),
      style: context.text.bodyMedium,
    );
  }
}

class _TypeOptionCard extends StatelessWidget {
  const _TypeOptionCard({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  final CommunityType type;
  final bool isSelected;
  final VoidCallback onTap;

  IconData get _icon => switch (type) {
    CommunityType.neighborhood => Icons.location_city_rounded,
    CommunityType.building => Icons.apartment_rounded,
    CommunityType.privateGroup => Icons.lock_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Material(
        color: isSelected
            ? context.colors.primary.withValues(alpha: 0.1)
            : context.semantic.surfaceInput,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: isSelected
                    ? context.colors.primary
                    : context.semantic.borderSubtle,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: (isSelected
                            ? context.colors.primary
                            : context.semantic.textMuted)
                        .withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _icon,
                    color: isSelected
                        ? context.colors.primary
                        : context.semantic.textMuted,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        type.labelAr,
                        textDirection: TextDirection.rtl,
                        style: context.text.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        type.descriptionAr,
                        textDirection: TextDirection.rtl,
                        style: context.text.bodySmall?.copyWith(
                          color: context.semantic.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isSelected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: isSelected
                      ? context.colors.primary
                      : context.semantic.textMuted,
                  size: 22,
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
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: context.semantic.surfaceInput,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: context.semantic.borderSubtle),
      ),
      child: Column(
        children: [
          Text(
            '$value متر',
            style: context.text.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: context.colors.primary,
            ),
          ),
          Slider(
            value: value.toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: ((max - min) ~/ 50).clamp(1, 40),
            label: '$value م',
            activeColor: context.colors.primary,
            onChanged: (v) => onChanged(v.round()),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$min م',
                style: context.text.labelSmall,
              ),
              Text(
                '$max م',
                style: context.text.labelSmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InviteCodeDialog extends StatelessWidget {
  const _InviteCodeDialog({required this.code, required this.communityName});

  final String code;
  final String communityName;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: context.semantic.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      title: Column(
        children: [
          Icon(
            Icons.group_add_rounded,
            size: 48,
            color: context.colors.primary,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'تم إنشاء "$communityName"',
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: context.text.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'شارك كود الدعوة مع من تريد إضافتهم',
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: context.text.bodySmall?.copyWith(
              color: context.semantic.textMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.sm + 2,
            ),
            decoration: BoxDecoration(
              color: context.colors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: context.colors.primary, width: 1.5),
            ),
            child: Text(
              code,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: 6,
                color: context.colors.primary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
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
            onPressed: () =>
                Share.share('Join my community on AIN! Use code: $code'),
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
