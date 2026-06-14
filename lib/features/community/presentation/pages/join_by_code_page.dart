import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/communities_provider.dart';

class JoinByCodePage extends ConsumerStatefulWidget {
  const JoinByCodePage({super.key});

  @override
  ConsumerState<JoinByCodePage> createState() => _JoinByCodePageState();
}

class _JoinByCodePageState extends ConsumerState<JoinByCodePage> {
  final _codeController = TextEditingController();
  String? _validationError;
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  String? _validate(String value) {
    if (value.isEmpty) return 'كود الدعوة مطلوب';
    if (value.length != 6) return 'الكود يجب أن يكون 6 أحرف بالضبط';
    if (!RegExp(r'^[A-Z0-9]+$').hasMatch(value)) {
      return 'الكود يجب أن يحتوي على أحرف وأرقام فقط';
    }
    return null;
  }

  Future<void> _join() async {
    final raw = _codeController.text.trim().toUpperCase();
    final error = _validate(raw);
    if (error != null) {
      setState(() => _validationError = error);
      return;
    }
    setState(() {
      _validationError = null;
      _isLoading = true;
    });

    final result = await ref
        .read(communitiesProvider.notifier)
        .joinByInviteCode(raw);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result == null) {
      // Error is in provider state
      final err = ref.read(communitiesProvider).error;
      setState(() => _validationError = _humanizeError(err));
      return;
    }

    // Show result
    if (result.isLocationPending) {
      _showLocationPendingSheet(result);
    } else {
      _showSuccessAndPop(result.communityName);
    }
  }

  String _humanizeError(String? raw) {
    if (raw == null) return 'حدث خطأ ما، حاول مرة أخرى';
    final lower = raw.toLowerCase();
    if (lower.contains('404') || lower.contains('invalid')) {
      return 'الكود غير صحيح. تأكد منه وحاول مرة أخرى';
    }
    if (lower.contains('expired')) return 'انتهت صلاحية كود الدعوة';
    if (lower.contains('already') || lower.contains('409')) {
      return 'أنت بالفعل عضو في هذا المجتمع';
    }
    return 'حدث خطأ ما، حاول مرة أخرى';
  }

  void _showSuccessAndPop(String communityName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('انضممت إلى "$communityName" بنجاح! 🎉',
            textDirection: TextDirection.rtl),
        backgroundColor: const Color(0xFF10B981),
        duration: const Duration(seconds: 3),
      ),
    );
    Navigator.of(context).pop(true);
  }

  void _showLocationPendingSheet(dynamic result) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_off_rounded, size: 56, color: Color(0xFFF59E0B)),
            const SizedBox(height: 12),
            Text(
              'انضممت إلى "${result.communityName}"!',
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              result.message.isNotEmpty
                  ? result.message
                  : 'شارك موقعك لتفعيل نداءات الاستغاثة في هذا المجتمع',
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.location_on_rounded),
                label: const Text('مشاركة الموقع الآن',
                    textDirection: TextDirection.rtl),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pop(true);
                  // TODO: navigate to location permission screen
                },
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop(true);
              },
              child: const Text('لاحقاً', style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF060C3A) : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor:
            isDark ? const Color(0xFF121A5C) : AppColors.primarySoft,
        foregroundColor: Colors.white,
        title: const Text(
          'الانضمام بكود دعوة',
          textDirection: TextDirection.rtl,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_ios_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            // Icon header
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF498EF4).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.key_rounded,
                  size: 40,
                  color: Color(0xFF498EF4),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'أدخل كود الدعوة',
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'اطلب الكود من مشرف المجتمع وأدخله أدناه',
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 40),

            // Code input — large, centered, uppercase
            TextField(
              controller: _codeController,
              maxLength: 6,
              textAlign: TextAlign.center,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                _UpperCaseFormatter(),
              ],
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: 8,
                color: Color(0xFF498EF4),
              ),
              decoration: InputDecoration(
                counterText: '',
                hintText: '••••••',
                hintStyle: TextStyle(
                  fontSize: 28,
                  letterSpacing: 8,
                  color: isDark
                      ? Colors.grey.shade700
                      : Colors.grey.shade300,
                ),
                errorText: _validationError,
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF1A287D).withValues(alpha: 0.3)
                    : Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 18, horizontal: 16),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: _validationError != null
                        ? Colors.red
                        : const Color(0xFF498EF4).withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: Color(0xFF498EF4),
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: Colors.red, width: 1.5),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                ),
              ),
              onChanged: (_) {
                if (_validationError != null) {
                  setState(() => _validationError = null);
                }
              },
              onSubmitted: (_) => _join(),
            ),

            const SizedBox(height: 32),

            // Join button
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _join,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF498EF4),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text(
                        'انضمام',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
