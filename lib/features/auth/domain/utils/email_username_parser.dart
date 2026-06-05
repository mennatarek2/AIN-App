class EmailUserNameParser {
  static final RegExp _emailPattern = RegExp(
    r"^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+$",
  );

  static String? fromEmail(String? email) {
    if (email == null) return null;

    final trimmed = email.trim();
    if (trimmed.isEmpty) return null;

    final atIndex = trimmed.indexOf('@');
    if (atIndex <= 0 || atIndex != trimmed.lastIndexOf('@')) {
      return null;
    }

    if (atIndex >= trimmed.length - 1) {
      return null;
    }

    if (!_emailPattern.hasMatch(trimmed)) {
      return null;
    }

    final userName = trimmed.substring(0, atIndex).trim();
    if (userName.isEmpty) return null;

    return userName;
  }
}
