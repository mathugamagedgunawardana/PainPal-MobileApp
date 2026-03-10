/// Environment configuration for the app.
/// The Flutter app connects to the backend API (not directly to MongoDB).
/// The backend uses MongoDB Atlas; set DATABASE_URL in the backend .env.
class Environment {
  static const String development = 'development';
  static const String staging = 'staging';
  static const String production = 'production';

  /// Current environment - change this or use build flags
  static const String currentEnvironment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: development,
  );

  /// Default backend API base URL (backend connects to MongoDB Atlas).
  /// Users can override this in Settings → Base URL.
  static String getApiBaseUrl() {
    switch (currentEnvironment) {
      case production:
        return 'https://api.painpal.health';
      case staging:
        return 'https://staging-api.painpal.health';
      case development:
      default:
        return 'http://localhost:3000';
    }
  }

  /// Enable debug logging
  static bool get enableDebugLogging => currentEnvironment != production;

  /// Enable mock data for testing
  static bool get useMockData => currentEnvironment == development;
}

