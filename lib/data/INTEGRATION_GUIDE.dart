/// Integration guide for MongoDB/Prisma backend integration
///
/// This file contains instructions and best practices for using the
/// MongoDB-based backend with the Flutter app.

/*

# MONGODB & PRISMA INTEGRATION GUIDE

## 📋 Overview
The app now integrates with a MongoDB backend via Prisma ORM. All authentication,
user profiles, migraine data, and MRI scans are persisted in MongoDB.

## 🔐 Authentication Flow

1. User registers/logs in via AuthService
2. Backend validates credentials and returns JWT token
3. Token is stored locally in SharedPreferences
4. Token is sent with all API requests via Authorization header
5. On token expiration, use refreshToken() to get a new one

Example:
```dart
final authService = AuthService();
await authService.initialize();

try {
  final response = await authService.login('user@example.com', 'password');
  print('Logged in as: ${response.user.email}');
} catch (e) {
  print('Login failed: $e');
}
```

## 📊 Patient Data Flow

1. User logs in and patient profile is loaded
2. Submit migraine events via PatientDataService.submitMigraineEvent()
3. Submit MRI scans via PatientDataService.submitMriScan()
4. Retrieve history via getMigraineHistory(), getMriHistory()

Example:
```dart
final patientService = PatientDataService(authService: authService);

// Submit migraine event
final attack = MigraineAttack(...);
final response = await patientService.submitMigraineEvent(attack);

// Get history
final history = await patientService.getMigraineHistory(limit: 10);
```

## 🏗️ Service Architecture

### AuthService
- Handles login/registration
- Manages JWT tokens
- Stores credentials locally
- Provides authentication headers for API calls

### PatientDataService
- Submits migraine events to `/api/summary`
- Uploads MRI images to `/api/mri/predict`
- Retrieves patient data from MongoDB
- Requires authenticated user

### Models
- User, PatientProfile, DoctorProfile (auth)
- MigraineEvent, MriScanData, MedicationLogData (patient data)
- LoginResponse, RegisterRequest (auth contracts)

## 🔌 API Endpoints

### Authentication
- POST /api/auth/login
- POST /api/auth/register
- POST /api/auth/refresh

### Patient Data
- POST /api/summary (submit migraine)
- POST /api/mri/predict (upload MRI)
- GET /api/patients/migraine-events
- GET /api/patients/mri-scans
- GET /api/patients/medication-logs

### Configuration
All endpoints are defined in BackendConfig class.
Base URL can be customized via environment variable: API_URL

## 🛠️ Setup Instructions

1. Install dependencies:
   flutter pub get

2. Update BackendConfig.mongoDbApiUrl if not using default

3. Initialize AuthService in main():
   ```dart
   final authService = AuthService();
   await authService.initialize();
   ```

4. Pass authService to screens that need it (via Provider or Constructor)

5. Handle authentication state:
   - Check authService.isAuthenticated
   - Show login screen if not authenticated
   - Redirect to home if authenticated

## 📱 Using with Provider (Recommended)

```dart
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final authService = AuthService();
  await authService.initialize();

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthService>.value(value: authService),
        ProxyProvider<AuthService, PatientDataService>(
          update: (context, authService, _) =>
              PatientDataService(authService: authService),
        ),
      ],
      child: const MyApp(),
    ),
  );
}
```

Then in widgets:
```dart
final authService = context.read<AuthService>();
final patientService = context.read<PatientDataService>();
```

## 🔄 Error Handling

All services throw exceptions that should be caught:

```dart
try {
  await authService.login(email, password);
} on AuthException catch (e) {
  print('Auth error: ${e.message}');
  // Show error to user
} catch (e) {
  print('Unexpected error: $e');
}
```

## 🚀 Deployment

For production:
1. Set ENVIRONMENT=production in build flags
2. Use HTTPS URLs
3. Set DATABASE_URL environment variable securely
4. Implement proper error handling and logging
5. Add request retry logic for network failures

## 📦 Database Schema (Prisma)

See the prisma/schema.prisma file for the complete database schema.
Key tables:
- User (authentication)
- PatientProfile (patient info)
- DoctorProfile (doctor info)
- MigraineEvent (migraine records)
- MriScan (MRI scans)
- MedicationLog (medication tracking)
- Appointment, ClinicalNote, Conversation (doctor features)

## 🔒 Security Considerations

1. Never hardcode credentials
2. Store tokens securely (using platform-specific secure storage if needed)
3. Clear tokens on logout
4. Validate inputs before sending to API
5. Use HTTPS in production
6. Implement token refresh before expiration

## 📝 Logging & Debugging

Enable debug logging for development:
```dart
// In environment.dart, currentEnvironment is set to 'development'
// This enables detailed logging in AuthService and PatientDataService
```

## 🐛 Common Issues & Solutions

### Issue: "User not authenticated" error
- Solution: Ensure AuthService.initialize() is called before using PatientDataService

### Issue: Token expired
- Solution: AuthService will automatically refresh token when needed

### Issue: CORS errors
- Solution: Backend should have CORS headers configured correctly

### Issue: Image upload fails
- Solution: Check file size (max 50MB) and format (jpg/jpeg/png)

---

For more details, see the individual service files:
- lib/data/auth_service.dart
- lib/data/patient_data_service.dart
- lib/data/backend_config.dart

*/

