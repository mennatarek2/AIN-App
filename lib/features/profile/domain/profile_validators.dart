/// Validation helpers for profile update form fields.
abstract final class ProfileValidators {
  static const egyptianMobilePattern = r'^(?:\+20|0)?1[0125]\d{8}$';

  static String? validateDisplayName(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'الاسم مطلوب';
    if (trimmed.length < 3) return 'يجب أن يكون الاسم 3 أحرف على الأقل';
    return null;
  }

  static String? validatePhoneNumber(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'رقم الهاتف مطلوب';
    if (!RegExp(egyptianMobilePattern).hasMatch(trimmed)) {
      return 'يرجى إدخال رقم هاتف مصري صحيح';
    }
    return null;
  }

  static bool isAllowedProfilePhoto(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png');
  }

  static String? validateCurrentPassword(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'كلمة المرور الحالية مطلوبة';
    return null;
  }

  static String? validateNewPassword(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'كلمة المرور الجديدة مطلوبة';
    if (trimmed.length < 6) {
      return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
    }
    return null;
  }

  static String? validateConfirmPassword(String? value, String newPassword) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'تأكيد كلمة المرور مطلوب';
    if (trimmed != newPassword.trim()) {
      return 'كلمة المرور غير متطابقة';
    }
    return null;
  }
}
