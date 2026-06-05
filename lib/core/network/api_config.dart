abstract final class ApiConfig {
  static const String defaultBaseUrl =
      'https://52cd-156-210-150-59.ngrok-free.app';

  static String get baseUrl => const String.fromEnvironment(
    'AIN_API_BASE_URL',
    defaultValue: defaultBaseUrl,
  );
}

// https://snowiness-enforcer-shape.ngrok-free.dev
