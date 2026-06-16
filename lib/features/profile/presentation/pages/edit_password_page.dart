import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/routes/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
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

    final confirmError =
        ProfileValidators.validateConfirmPassword(confirmPassword, newPassword);
    if (confirmError != null) {
      _showError(confirmError);
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final result = await ref.read(authRepositoryProvider).changePassword(
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
            backgroundColor: Colors.red,
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
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageBackground = isDark
        ? const Color(0xFF060C3A)
        : AppColors.backgroundLight;
    final forgotTextColor = isDark
        ? const Color(0xFFD23B3B)
        : const Color(0xFFEF4444);

    return Scaffold(
      backgroundColor: pageBackground,
      body: Column(
        children: [
          _TopHeader(onBack: () => Navigator.of(context).pop()),
          if (_isSaving)
            const LinearProgressIndicator(
              backgroundColor: Color(0xFFBAD6F4),
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0099FF)),
            ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                if (_errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1F1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFFCACA)),
                    ),
                    child: Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        const Icon(Icons.error_outline,
                            color: Color(0xFFC62828), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            textDirection: TextDirection.rtl,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF7F1D1D),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                _PasswordField(
                  hintText: 'كلمة المرور الحالية',
                  controller: _currentPasswordController,
                  enabled: !_isSaving,
                ),
                const SizedBox(height: 18),
                _PasswordField(
                  hintText: 'كلمة المرور الجديدة',
                  controller: _newPasswordController,
                  enabled: !_isSaving,
                ),
                const SizedBox(height: 18),
                _PasswordField(
                  hintText: 'تأكيد كلمة المرور الجديدة',
                  controller: _confirmPasswordController,
                  enabled: !_isSaving,
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: _isSaving
                        ? null
                        : () {
                            Navigator.of(context)
                                .pushNamed(AppRoutes.forgotPassword);
                          },
                    child: Text(
                      'هل نسيت كلمة المرور؟',
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontSize: 40 * 0.525,
                        fontWeight: FontWeight.w400,
                        color: forgotTextColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 56),
                Container(
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
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopHeader extends StatelessWidget {
  const _TopHeader({required this.onBack});

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
              alignment: Alignment(0, 0.32),
              child: Text(
                'تغيير كلمة المرور',
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fieldBackground = isDark ? const Color(0xFF060C3A) : Colors.white;
    final fieldBorderColor = isDark
        ? const Color(0xFFF3F6F9)
        : const Color(0xFF060C3A);
    final hintColor = isDark
        ? const Color(0xFFF3F6F9)
        : const Color(0xB3909090);
    final textColor = isDark
        ? const Color(0xFFF3F6F9)
        : AppColors.textPrimaryLight;

    return SizedBox(
      height: 48,
      child: TextField(
        controller: controller,
        enabled: enabled,
        obscureText: true,
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
        style: TextStyle(
          fontSize: 36 * 0.525,
          fontWeight: FontWeight.w400,
          color: textColor,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: fieldBackground,
          hintText: hintText,
          hintTextDirection: TextDirection.rtl,
          hintStyle: TextStyle(
            fontSize: 40 * 0.525,
            fontWeight: FontWeight.w400,
            color: hintColor,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 10, right: 10),
            child: Icon(Icons.lock, color: textColor, size: 24),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 44),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: fieldBorderColor, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: fieldBorderColor, width: 1.2),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: fieldBorderColor.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
        ),
      ),
    );
  }
}