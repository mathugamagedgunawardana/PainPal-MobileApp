/// Backend configuration for API requests
class BackendConfig {
  /// Request timeout duration
  static const Duration requestTimeout = Duration(seconds: 30);

  /// MRI upload + model inference (Blob + ResNet18) can take longer on mobile networks.
  static const Duration mriRequestTimeout = Duration(seconds: 90);

  /// Maximum retry attempts for failed requests
  static const int maxRetries = 3;

  /// Retry delay between attempts
  static const Duration retryDelay = Duration(seconds: 2);

  /// API endpoints
  static const String summaryEndpoint = '/api/summary';
  static const String mriPredictEndpoint = '/api/mri/predict';
  /// Browser: Vercel Blob client handler; then POST [mriPredictEndpoint] with blobPathname JSON.
  static const String mriUploadEndpoint = '/api/mri/upload';
  /// Mobile: multipart → Vercel Blob (server); then POST [mriPredictEndpoint] with blobPathname JSON.
  static const String mriUploadFileEndpoint = '/api/mri/upload-file';

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

  /// Patient: prescribed schedule for local reminder notifications.
  static const String patientMedicationScheduleEndpoint = '/api/patient/medication-schedule';

  /// Aggregated analytics (MongoDB via Next.js); requires PATIENT JWT.
  static const String patientAnalyticsEndpoint = '/api/patient/analytics';

  /// Stored AI narrative summary; requires PATIENT JWT.
  static const String patientAiSummaryEndpoint = '/api/patient/ai-summary';

  /// Full patient-scoped DB export for Gemini (JSON text); requires PATIENT JWT.
  static const String patientAiContextEndpoint = '/api/patient/ai-context';

  /// Patient-scoped migraine list for History; requires PATIENT JWT.
  static const String patientMigraineEventsEndpoint = '/api/patient/migraine-events';

  /// Patient-scoped MRI upload history; requires PATIENT JWT.
  static const String patientMriScansEndpoint = '/api/patient/mri-scans';

  /// Patient: list ACTIVE linked doctors (for scheduling).
  static const String patientLinkedDoctorsEndpoint = '/api/patient/linked-doctors';

  /// Patient: list / create appointments.
  static const String patientAppointmentsEndpoint = '/api/patient/appointments';

  /// Doctor–patient messaging (requires PATIENT or DOCTOR JWT).
  static const String chatConversationsEndpoint = '/api/chat/conversations';

  static String chatMessagesEndpoint(String conversationId) =>
      '/api/chat/conversations/$conversationId/messages';
}
