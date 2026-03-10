/// Backend configuration for API requests.
/// The app talks to the backend API (Next.js); the backend connects to MongoDB Atlas via DATABASE_URL.
class BackendConfig {
  /// Request timeout duration
  static const Duration requestTimeout = Duration(seconds: 30);

  /// Maximum retry attempts for failed requests
  static const int maxRetries = 3;

  /// Retry delay between attempts
  static const Duration retryDelay = Duration(seconds: 2);

  /// API endpoints
  static const String summaryEndpoint = '/api/summary';
  static const String mriPredictEndpoint = '/api/mri/predict';

  /// Default backend API URL when none is set in Settings.
  /// Use Environment.getApiBaseUrl() for env-aware default.
  static const String mongoDbApiUrl = 'http://localhost:3000';

  /// Auth endpoints
  static const String loginEndpoint = '/api/auth/login';
  static const String registerEndpoint = '/api/auth/register';
  static const String refreshTokenEndpoint = '/api/auth/refresh';

  /// Patient data endpoints
  static const String migraineEventsEndpoint = '/api/migraine-events';
  static const String mriScansEndpoint = '/api/mri-scans';
  static const String medicationLogsEndpoint = '/api/medication-logs';
}



