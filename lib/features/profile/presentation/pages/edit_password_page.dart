import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/routes/app_routes.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/profile_validators.dart';

class EditPasswordPage extends ConsumerStatefulWidget {
  const EditPasswordPage({super.key});

  @override
  ConsumerState<EditPasswordPage> createState() => _EditPasswordPageState();
}

class _EditPasswordPageState extends ConsumerState<EditPasswordPage> {
  late final TextEditingController _currentPasswordController;
  late final TextEditingController _newPasswordController;
  late final TextEditingController _confirmPasswordController;

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) return;

    final oldPassword = _currentPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    final currentError = ProfileValidators.validateCurrentPassword(oldPassword);
    if (currentError != null) {
      _showError(currentError);
      return;
    }

    final newError = ProfileValidators.validateNewPassword(newPassword);
    if (newError != null) {
      _showError(newError);
      return;
    }

    final confirmError = ProfileValidators.validateConfirmPassword(
      confirmPassword,
      newPassword,
    );
    if (confirmError != null) {
      _showError(confirmError);
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final result = await ref
        .read(authRepositoryProvider)
        .changePassword(
          oldPassword: oldPassword,
          newPassword: newPassword,
          confirmPassword: confirmPassword,
        );

    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() {
          _isSaving = false;
          _errorMessage = failure.message;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
            backgroundColor: context.semantic.error,
          ),
        );
      },
      (_) {
        setState(() => _isSaving = false);
        Navigator.of(context).pushNamed(AppRoutes.passwordChanged);
      },
    );
  }

  void _showError(String message) {
    setState(() => _errorMessage = message);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: context.semantic.error,
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
            title: 'تغيير كلمة المرور',
            onBack: () => Navigator.of(context).pop(),
          ),
          if (_isSaving)
            LinearProgressIndicator(
              backgroundColor: context.semantic.infoContainer,
              valueColor: AlwaysStoppedAnimation<Color>(
                context.colors.primary,
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal,
            ),
            child: Column(
              children: [
                if (_errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: context.semantic.errorContainer,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(
                        color: context.semantic.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: context.semantic.error,
                          size: 18,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            textDirection: TextDirection.rtl,
                            style: context.text.bodySmall?.copyWith(
                              color: context.semantic.error,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                _PasswordField(
                  hintText: 'كلمة المرور الحالية',
                  controller: _currentPasswordController,
                  enabled: !_isSaving,
                ),
                const SizedBox(height: AppSpacing.md),
                _PasswordField(
                  hintText: 'كلمة المرور الجديدة',
                  controller: _newPasswordController,
                  enabled: !_isSaving,
                ),
                const SizedBox(height: AppSpacing.md),
                _PasswordField(
                  hintText: 'تأكيد كلمة المرور الجديدة',
                  controller: _confirmPasswordController,
                  enabled: !_isSaving,
                ),
                const SizedBox(height: AppSpacing.md),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: _isSaving
                        ? null
                        : () {
                            Navigator.of(
                              context,
                            ).pushNamed(AppRoutes.forgotPassword);
                          },
                    child: Text(
                      'هل نسيت كلمة المرور؟',
                      textDirection: TextDirection.rtl,
                      style: context.text.bodyMedium?.copyWith(
                        color: context.semantic.error,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.huge),
                SizedBox(
                  width: 300,
                  height: 52,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: context.primaryGradient,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: TextButton(
                      onPressed: _isSaving ? null : _save,
                      style: TextButton.styleFrom(
                        foregroundColor: context.semantic.textOnPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                      ),
                      child: _isSaving
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  context.semantic.textOnPrimary,
                                ),
                              ),
                            )
                          : Text(
                              'حفظ التعديلات',
                              textDirection: TextDirection.rtl,
                              style: context.text.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
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

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.hintText,
    required this.controller,
    this.enabled = true,
  });

  final String hintText;
  final TextEditingController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: TextField(
        controller: controller,
        enabled: enabled,
        obscureText: true,
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
        style: context.text.bodyLarge?.copyWith(
          color: context.colors.onSurface,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: context.semantic.surfaceInput,
          hintText: hintText,
          hintTextDirection: TextDirection.rtl,
          hintStyle: context.text.bodyLarge?.copyWith(
            color: context.semantic.textMuted,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 10, right: 10),
            child: Icon(
              Icons.lock,
              color: context.colors.onSurface,
              size: 24,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 44),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            borderSide: BorderSide(color: context.semantic.borderSubtle),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            borderSide: BorderSide(
              color: context.colors.primary,
              width: 1.2,
            ),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            borderSide: BorderSide(
              color: context.semantic.borderSubtle.withValues(alpha: 0.5),
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        ),
      ),
    );
  }
}
