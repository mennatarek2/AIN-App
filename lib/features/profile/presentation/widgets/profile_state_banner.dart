import 'package:flutter/material.dart';

class ProfileStateBanner extends StatelessWidget {
  const ProfileStateBanner({
    super.key,
    required this.isLoading,
    this.errorText,
    this.onRetry,
  });

  final bool isLoading;
  final String? errorText;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (errorText != null && errorText!.trim().isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: Container(
          key: const ValueKey('profile_state_error_banner'),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF1F1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFFFCACA)),
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              const Icon(
                Icons.error_outline,
                color: Color(0xFFC62828),
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  errorText!,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF7F1D1D),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (onRetry != null)
                TextButton(
                  onPressed: onRetry,
                  child: const Text('إعادة المحاولة'),
                ),
            ],
          ),
        ),
      );
    }

    if (isLoading) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: Container(
          key: const ValueKey('profile_state_loading_banner'),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: const [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'جاري تحديث بيانات الملف الشخصي...',
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF1E3A8A),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
