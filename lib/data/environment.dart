/// Environment configuration for the app
/// This file manages different environments (development, staging, production)
class Environment {
  static const String development = 'development';
  static const String staging = 'staging';
  static const String production = 'production';

  /// Current environment - change this or use build flags
  static const String currentEnvironment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: development,
  );

  /// Get API base URL based on environment
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

  /// MongoDB connection URL - should be set via environment variables
  static const String mongoDbUrl = String.fromEnvironment(
    'DATABASE_URL',
    defaultValue: 'mongodb+srv://ranith:wuzTNpaR14NMMGRZ@painpal.vo4hinw.mongodb.net/painpal?retryWrites=true&w=majority&appName=PainPal',
  );

  /// Enable debug logging
  static bool get enableDebugLogging => currentEnvironment != production;

  /// Enable mock data for testing
  static bool get useMockData => currentEnvironment == development;
}

