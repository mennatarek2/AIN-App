import 'package:flutter/material.dart';

import '../../../../config/routes/app_routes.dart';
import '../../../../core/theme/app_colors.dart';

class EditPasswordPage extends StatefulWidget {
  const EditPasswordPage({super.key});

  @override
  State<EditPasswordPage> createState() => _EditPasswordPageState();
}

class _EditPasswordPageState extends State<EditPasswordPage> {
  late final TextEditingController _currentPasswordController;
  late final TextEditingController _newPasswordController;
  late final TextEditingController _confirmPasswordController;

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
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _PasswordField(
                  hintText: 'كلمة المرور الحالية',
                  controller: _currentPasswordController,
                ),
                const SizedBox(height: 18),
                _PasswordField(
                  hintText: 'كلمة المرور الجديدة',
                  controller: _newPasswordController,
                ),
                const SizedBox(height: 18),
                _PasswordField(
                  hintText: 'تأكيد كلمة المرور الجديدة',
                  controller: _confirmPasswordController,
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushNamed(AppRoutes.forgotPassword);
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
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم حفظ التعديلات')),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFF3F6F9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
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
  const _PasswordField({required this.hintText, required this.controller});

  final String hintText;
  final TextEditingController controller;

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
          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
        ),
      ),
    );
  }
}
