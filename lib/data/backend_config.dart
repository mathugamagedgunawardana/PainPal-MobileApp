/// Backend configuration for API requests
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

  /// Fallback when neither Settings "API Base URL" nor `.env` `API_BASE_URL` is set (see [AuthService.resolveApiBaseUrl]).
  static const String mongoDbApiUrl = 'http://localhost:3000';

  /// Auth endpoints
  static const String loginEndpoint = '/api/auth/login';
  static const String registerEndpoint = '/api/auth/register';
  static const String refreshTokenEndpoint = '/api/auth/refresh';

  /// Patient data endpoints
  static const String migraineEventsEndpoint = '/api/migraine-events';
  static const String mriScansEndpoint = '/api/mri-scans';
  static const String medicationLogsEndpoint = '/api/medication-logs';

  /// Aggregated analytics (MongoDB via Next.js); requires PATIENT JWT.
  static const String patientAnalyticsEndpoint = '/api/patient/analytics';

  /// Patient-scoped migraine list for History; requires PATIENT JWT.
  static const String patientMigraineEventsEndpoint = '/api/patient/migraine-events';

  /// Patient-scoped MRI list (optional persistence); requires PATIENT JWT.
  static const String patientMriScansEndpoint = '/api/patient/mri-scans';
}



