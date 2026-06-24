import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../home/presentation/pages/your_location_page.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/app_layout_primitives.dart';
import '../../../../core/widgets/app_otp_input.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../providers/communities_provider.dart';

class JoinByCodePage extends ConsumerStatefulWidget {
  const JoinByCodePage({super.key});

  @override
  ConsumerState<JoinByCodePage> createState() => _JoinByCodePageState();
}

class _JoinByCodePageState extends ConsumerState<JoinByCodePage> {
  final _codeController = TextEditingController();
  final _focusNode = FocusNode();
  String? _validationError;
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    _focusNode.dispose();
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
      // Use the status code to apply spec-mandated messages.
      final joinState = ref.read(communitiesProvider);
      final code = joinState.joinErrorCode;
      final apiMessage = joinState.error ?? '';
      setState(
        () => _validationError = _errorForCode(code, apiMessage),
      );
      return;
    }

    if (result.isLocationPending) {
      _showLocationPendingSheet(result);
    } else {
      _showSuccessAndPop(result.communityName);
    }
  }

  /// Maps HTTP status code → user-facing Arabic error message.
  /// 404 → spec says "Invalid or expired invite code".
  /// 409 → use the API-supplied message (already humanized by provider).
  String _errorForCode(int? code, String apiMessage) {
    switch (code) {
      case 404:
        return 'الكود غير صالح أو منتهي الصلاحية';
      case 409:
        // 409 payload already mapped by communityApiUserMessage.
        return apiMessage.isNotEmpty
            ? apiMessage
            : 'أنت بالفعل عضو في هذا المجتمع';
      default:
        return apiMessage.isNotEmpty
            ? apiMessage
            : 'حدث خطأ ما، حاول مرة أخرى';
    }
  }

  void _showSuccessAndPop(String communityName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'انضممت إلى "$communityName" بنجاح! 🎉',
          textDirection: TextDirection.rtl,
        ),
        backgroundColor: context.semantic.success,
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
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_off_rounded,
              size: 56,
              color: context.semantic.warning,
            ),
            const SizedBox(height: 12),
            Text(
              'انضممت إلى "${result.communityName}"!',
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: context.text.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              result.message.isNotEmpty
                  ? result.message
                  : 'شارك موقعك لتفعيل نداءات الاستغاثة في هذا المجتمع',
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: context.text.bodySmall?.copyWith(
                color: context.semantic.textMuted,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.location_on_rounded),
                label: const Text(
                  'مشاركة الموقع الآن',
                  textDirection: TextDirection.rtl,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.semantic.warning,
                  foregroundColor: context.semantic.textOnPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pop(true);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const YourLocationPage()),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop(true);
              },
              child: Text(
                'لاحقاً',
                style: TextStyle(color: context.semantic.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final code = _codeController.text.toUpperCase();

    return Scaffold(
      backgroundColor: context.colors.surface,
      body: Column(
        children: [
          AppPageHeader(
            title: 'الانضمام بكود دعوة',
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: AppFormCard(
                  title: 'أدخل كود الدعوة',
                  subtitle: 'اطلب الكود من مشرف المجتمع وأدخله أدناه',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.lg,
                        ),
                        decoration: BoxDecoration(
                          color: context.semantic.surfaceInput,
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                          border: Border.all(
                            color: _validationError != null
                                ? context.semantic.error
                                : context.colors.primary.withValues(alpha: 0.35),
                            width: _validationError != null ? 2 : 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.key_rounded,
                              size: 32,
                              color: context.colors.primary.withValues(alpha: 0.7),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            AppInviteCodeInput(
                              code: code,
                              controller: _codeController,
                              focusNode: _focusNode,
                              hasError: _validationError != null,
                              onChanged: (_) => setState(() {
                                _validationError = null;
                              }),
                            ),
                          ],
                        ),
                      ),
                      if (_validationError != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          _validationError!,
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            color: context.semantic.error,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xl),
                      SizedBox(
                        height: 52,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            gradient: context.primaryGradient,
                          ),
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _join,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: context.semantic.textOnPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppRadius.md),
                              ),
                            ),
                            child: _isLoading
                                ? SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: context.semantic.textOnPrimary,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Text(
                                    'انضمام',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const AppTrustIndicators(),
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
