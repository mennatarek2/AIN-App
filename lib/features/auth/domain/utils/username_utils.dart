abstract final class UsernameUtils {
  static final RegExp _emailPattern = RegExp(
    r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
  );

  static String? fromEmail(String email) {
    final normalizedEmail = email.trim();
    if (normalizedEmail.isEmpty || !_emailPattern.hasMatch(normalizedEmail)) {
      return null;
    }

    final atIndex = normalizedEmail.indexOf('@');
    if (atIndex <= 0) {
      return null;
    }

    final userName = normalizedEmail.substring(0, atIndex).trim();
    if (userName.isEmpty) {
      return null;
    }

    return userName;
  }
}
