abstract final class ApiConfig {
  static const String defaultBaseUrl =
      'https://scorebook-resonate-excuse.ngrok-free.dev';

  static String get baseUrl => const String.fromEnvironment(
    'AIN_API_BASE_URL',
    defaultValue: defaultBaseUrl,
  );
}
