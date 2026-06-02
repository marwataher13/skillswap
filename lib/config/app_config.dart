class AppConfig {
  AppConfig._();

  /// Retrieve the backend API base URL from environment variables at build/run time.
  /// Standard fallback defaults to your active ngrok tunnel.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://lurch-unstopped-backed.ngrok-free.dev',
  );
}
