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
}

