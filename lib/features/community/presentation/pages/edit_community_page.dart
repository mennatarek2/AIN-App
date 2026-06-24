import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/enums/community_enums.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../models/community_detail.dart';
import '../providers/communities_provider.dart';

class EditCommunityPage extends ConsumerStatefulWidget {
  const EditCommunityPage({
    super.key,
    required this.communityId,
    required this.initialDetail,
  });

  final String communityId;
  final CommunityDetail initialDetail;

  @override
  ConsumerState<EditCommunityPage> createState() => _EditCommunityPageState();
}

class _EditCommunityPageState extends ConsumerState<EditCommunityPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late CommunityType _selectedType;
  late int _radiusMeters;
  bool _isSubmitting = false;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    final detail = widget.initialDetail;
    _nameController = TextEditingController(text: detail.name);
    _descriptionController = TextEditingController(text: detail.description ?? '');
    _selectedType = detail.communityType;
    _radiusMeters = detail.coverageRadiusMeters ??
        detail.communityType.defaultRadiusMeters ??
        500;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String? _validateName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'اسم المجتمع مطلوب';
    if (trimmed.length < 2) return 'الاسم يجب أن يكون حرفين على الأقل';
    if (trimmed.length > 100) return 'الاسم يجب ألا يتجاوز 100 حرف';
    return null;
  }

  Future<void> _submit() async {
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
    final error = await ref.read(communitiesProvider.notifier).updateCommunity(
          communityId: widget.communityId,
          name: _nameController.text.trim(),
          description: description.isEmpty ? null : description,
          type: _selectedType,
          coverageRadiusMeters:
              _selectedType.hasRadius ? _radiusMeters : null,
        );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error, textDirection: TextDirection.rtl)),
      );
      return;
    }

    ref.invalidate(communityDetailProvider(widget.communityId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم تحديث المجتمع', textDirection: TextDirection.rtl),
      ),
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.surface,
      body: Column(
        children: [
          AppPageHeader(
            title: 'تعديل المجتمع',
            subtitle: widget.initialDetail.name,
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal,
                AppSpacing.md,
                AppSpacing.screenHorizontal,
                AppSpacing.xxl,
              ),
              children: [
                AppSurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _nameController,
                        textDirection: TextDirection.rtl,
                        decoration: InputDecoration(
                          labelText: 'اسم المجتمع',
                          errorText: _nameError,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: _descriptionController,
                        textDirection: TextDirection.rtl,
                        maxLines: 3,
                        maxLength: 500,
                        decoration: const InputDecoration(
                          labelText: 'الوصف (اختياري)',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'نوع المجتمع',
                        textDirection: TextDirection.rtl,
                        style: context.text.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ...CommunityType.values.map(
                        (type) => RadioListTile<CommunityType>(
                          value: type,
                          groupValue: _selectedType,
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              _selectedType = value;
                              if (value.hasRadius) {
                                _radiusMeters =
                                    value.defaultRadiusMeters ?? _radiusMeters;
                              }
                            });
                          },
                          title: Text(
                            type.labelAr,
                            textDirection: TextDirection.rtl,
                          ),
                          subtitle: Text(
                            type.descriptionAr,
                            textDirection: TextDirection.rtl,
                          ),
                        ),
                      ),
                      if (_selectedType.hasRadius) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'نطاق التغطية: $_radiusMeters م',
                          textDirection: TextDirection.rtl,
                        ),
                        Slider(
                          value: _radiusMeters.toDouble(),
                          min: _selectedType == CommunityType.building
                              ? 50
                              : 200,
                          max: _selectedType == CommunityType.building
                              ? 500
                              : 2000,
                          divisions: 19,
                          onChanged: (v) =>
                              setState(() => _radiusMeters = v.round()),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'حفظ التغييرات',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
