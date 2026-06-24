import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/app_layout_primitives.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../providers/communities_provider.dart';
import 'add_member_success_page.dart';

class AddMemberPage extends ConsumerStatefulWidget {
  const AddMemberPage({super.key, required this.communityId});

  final String communityId;

  @override
  ConsumerState<AddMemberPage> createState() => _AddMemberPageState();
}

class _AddMemberPageState extends ConsumerState<AddMemberPage> {
  final _emailController = TextEditingController();
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String? _validateEmail(String value) {
    if (value.isEmpty) return 'البريد الإلكتروني مطلوب';
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value)) {
      return 'أدخل بريداً إلكترونياً صالحاً';
    }
    return null;
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final validationError = _validateEmail(email);
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }

    setState(() {
      _error = null;
      _isSubmitting = true;
    });

    final error = await ref.read(communitiesProvider.notifier).addMemberByEmail(
          communityId: widget.communityId,
          email: email,
        );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (error != null) {
      setState(() => _error = error);
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AddMemberSuccessPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.surface,
      body: Column(
        children: [
          AppPageHeader(
            title: 'إضافة عضو جديد',
            subtitle: 'أدخل البريد الإلكتروني للعضو',
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: AppFormCard(
                  title: 'دعوة عضو',
                  subtitle: 'سيتلقى العضو دعوة للانضمام إلى المجتمع',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                        decoration: InputDecoration(
                          hintText: 'البريد الإلكتروني للعضو الجديد',
                          hintTextDirection: TextDirection.rtl,
                          prefixIcon: Icon(
                            Icons.email_outlined,
                            color: context.colors.primary,
                          ),
                          filled: true,
                          fillColor: context.semantic.surfaceInput,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm + 2,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadius.md),
                            borderSide: BorderSide(
                              color: context.semantic.borderSubtle,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadius.md),
                            borderSide: BorderSide(
                              color: context.colors.primary,
                              width: 1.5,
                            ),
                          ),
                          errorText: _error,
                        ),
                        style: context.text.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      SizedBox(
                        height: 52,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(AppRadius.md),
                            gradient: context.primaryGradient,
                          ),
                          child: TextButton(
                            style: TextButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.md),
                              ),
                            ),
                            onPressed: _isSubmitting ? null : _submit,
                            child: _isSubmitting
                                ? SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: context.semantic.textOnPrimary,
                                    ),
                                  )
                                : Text(
                                    'إضافة',
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
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
