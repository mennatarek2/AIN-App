/// Normalizes bearer tokens returned by the API.
abstract final class AuthTokenUtils {
  /// URL-decodes tokens when the backend returns encoded values (e.g. `%2B` → `+`).
  static String? normalize(String? token) {
    if (token == null) return null;

    final trimmed = token.trim();
    if (trimmed.isEmpty) return null;

    if (!trimmed.contains('%')) return trimmed;

    try {
      return Uri.decodeComponent(trimmed);
    } catch (_) {
      return trimmed;
    }
  }
}
