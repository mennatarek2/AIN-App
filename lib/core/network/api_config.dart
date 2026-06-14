abstract final class ApiConfig {
  static const String defaultBaseUrl =
      'https://fc02-197-54-254-97.ngrok-free.app';

  static String get baseUrl => const String.fromEnvironment(
    'AIN_API_BASE_URL',
    defaultValue: defaultBaseUrl,
  );
}
