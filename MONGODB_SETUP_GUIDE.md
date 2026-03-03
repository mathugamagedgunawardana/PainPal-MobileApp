# MongoDB & Prisma Integration Setup Guide

## 🎯 Overview
This guide provides step-by-step instructions to integrate the PainPal Flutter app with the MongoDB backend using Prisma ORM.

## 📋 Prerequisites

- Flutter SDK (v3.11+)
- Dart SDK (v3.11+)
- MongoDB cluster (already set up at: `painpal.vo4hinw.mongodb.net`)
- Backend API server running (Node.js/Express with Prisma)

## 🔧 Installation Steps

### 1. Update Dependencies

Run the following command to install new packages:

```bash
flutter pub get
```

This will install:
- `http` - HTTP client for API calls
- `shared_preferences` - Local storage for authentication tokens
- `provider` - State management (recommended)
- `jwt_decoder` - JWT token decoding
- `uuid` - UUID generation
- `intl` - Internationalization

### 2. Configure Backend URL

The app is configured to use `http://localhost:3000` as the default backend URL in development.

To change the backend URL:

**Option A: Update BackendConfig (hardcoded)**
```dart
// lib/data/backend_config.dart
static const String mongoDbApiUrl = 'http://your-api-url.com';
```

**Option B: Use Environment Variables (recommended)**
```bash
# Build with custom API URL
flutter run --dart-define=API_URL=http://your-api-url.com
```

### 3. Backend Setup (Node.js/Express)

Your backend should have:

1. **Prisma Configuration** - with MongoDB database
2. **Authentication Endpoints**:
   - `POST /api/auth/login` - User login
   - `POST /api/auth/register` - User registration
   - `POST /api/auth/refresh` - Token refresh

3. **Patient Data Endpoints**:
   - `POST /api/summary` - Submit migraine data
   - `POST /api/mri/predict` - Upload MRI scan
   - `GET /api/patients/migraine-events` - Get migraine history
   - `GET /api/patients/mri-scans` - Get MRI history
   - `GET /api/patients/medication-logs` - Get medication logs

4. **CORS Configuration** - Allow requests from Flutter app

Example Express + Prisma backend structure:
```javascript
const express = require('express');
const { PrismaClient } = require('@prisma/client');

const app = express();
const prisma = new PrismaClient();

app.use(express.json());

// Auth endpoints
app.post('/api/auth/login', async (req, res) => {
  // Implementation
});

app.post('/api/auth/register', async (req, res) => {
  // Implementation
});

// Patient endpoints
app.post('/api/summary', async (req, res) => {
  // Create migraine event
});

app.post('/api/mri/predict', async (req, res) => {
  // Upload and predict MRI
});

app.listen(3000);
```

### 4. Initialize AuthService in main.dart

```dart
import 'package:painpal/data/auth_service.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize auth service
  final authService = AuthService();
  await authService.initialize();
  
  runApp(
    MultiProvider(
      providers: [
        Provider<AuthService>.value(value: authService),
      ],
      child: const MyApp(),
    ),
  );
}
```

### 5. Handle Authentication State

In your home screen or navigation:

```dart
@override
Widget build(BuildContext context) {
  final authService = context.read<AuthService>();
  
  if (authService.isAuthenticated) {
    return const HomeScreen();
  } else {
    return const LoginScreen();
  }
}
```

## 🔐 Authentication Flow

### Login
```dart
final authService = context.read<AuthService>();

try {
  final response = await authService.login(
    'user@example.com',
    'password123'
  );
  print('Logged in as: ${response.user.email}');
} on AuthException catch (e) {
  print('Login failed: ${e.message}');
}
```

### Register
```dart
try {
  final response = await authService.register(
    email: 'newuser@example.com',
    password: 'password123',
    role: UserRole.patient,
    name: 'John Doe',
    dateOfBirth: DateTime(1990, 1, 1),
  );
  print('Registered as: ${response.user.email}');
} on AuthException catch (e) {
  print('Registration failed: ${e.message}');
}
```

### Logout
```dart
await authService.logout();
// Redirect to login screen
```

## 📊 Submitting Patient Data

### Submit Migraine Event
```dart
import 'package:painpal/data/patient_data_service.dart';

final patientService = context.read<PatientDataService>();

final attack = MigraineAttack(
  durationHours: 4,
  frequencyPerMonth: 2,
  location: 'Unilateral',
  character: 'Throbbing',
  intensity: 7,
  nausea: 1,
  vomit: 0,
  phonophobia: 1,
  photophobia: 1,
  visual: 0,
  sensory: 0,
  dysphasia: 0,
  dysarthria: 0,
  vertigo: 0,
  tinnitus: 0,
  hypoacusis: 0,
  diplopia: 0,
  defect: 0,
  ataxia: 0,
  conscience: 0,
  paresthesia: 0,
  dpf: 'Pattern1',
);

try {
  final response = await patientService.submitMigraineEvent(attack);
  print('Summary: ${response.summary}');
  print('Type: ${response.predictedType}');
} catch (e) {
  print('Submission failed: $e');
}
```

### Upload MRI Scan
```dart
try {
  final mriResponse = await patientService.submitMriScan(
    image: File('/path/to/mri/image.jpg'),
  );
  print('Prediction: ${mriResponse.prediction}');
  print('Confidence: ${mriResponse.confidence}');
} catch (e) {
  print('Upload failed: $e');
}
```

### Retrieve History
```dart
// Get migraine history
final migraineHistory = await patientService.getMigraineHistory(limit: 10);
for (var event in migraineHistory) {
  print('Event: ${event.startDatetime} - Severity: ${event.severity}');
}

// Get MRI history
final mriHistory = await patientService.getMriHistory(limit: 10);
for (var scan in mriHistory) {
  print('Scan: ${scan.prediction} (${scan.confidence}%)');
}

// Get medication logs
final medLogs = await patientService.getMedicationLogs(limit: 20);
for (var log in medLogs) {
  print('Med: ${log.medicationName} - ${log.dosage}');
}
```

## 💾 Local Storage

The app uses `SharedPreferences` to store:
- Authentication token
- User information
- Patient profile
- Doctor profile (if applicable)

This allows the app to work offline and resume sessions.

To clear all stored data:
```dart
final authService = context.read<AuthService>();
await authService.logout(); // Clears all local storage
```

## 🚀 Deployment

### Development
```bash
flutter run --dart-define=ENVIRONMENT=development
```

### Staging
```bash
flutter run --dart-define=ENVIRONMENT=staging \
  --dart-define=API_URL=https://staging-api.painpal.health
```

### Production
```bash
flutter run --dart-define=ENVIRONMENT=production \
  --dart-define=API_URL=https://api.painpal.health
```

## 🔒 Security Best Practices

1. **Never hardcode credentials**
   - Use environment variables for sensitive data
   - Store tokens in secure platform-specific storage if needed

2. **HTTPS in Production**
   - Always use HTTPS URLs in production
   - Configure proper SSL certificates

3. **Token Management**
   - Tokens are automatically refreshed by AuthService
   - Implement token expiration checks

4. **Input Validation**
   - Validate all user inputs before sending to API
   - Check file size and format for MRI uploads

5. **Error Handling**
   - Log errors for debugging
   - Never expose sensitive data in error messages

## 🐛 Troubleshooting

### Connection Issues
```
Error: Failed to connect to API
Solution: Check backend URL in BackendConfig
          Ensure backend is running and accessible
          Check CORS configuration
```

### Authentication Errors
```
Error: "User not authenticated"
Solution: Ensure authService.initialize() is called
          Check token is stored and retrieved correctly
          Try logging in again
```

### Token Expired
```
Error: "Unauthorized" (401)
Solution: AuthService automatically handles token refresh
          If still failing, user needs to log in again
```

### Network Timeouts
```
Error: "Request timed out"
Solution: Check internet connection
          Increase timeout in BackendConfig.requestTimeout
          Check server is responding
```

## 📚 Additional Resources

- [Prisma Documentation](https://www.prisma.io/docs/)
- [MongoDB Documentation](https://docs.mongodb.com/)
- [Flutter HTTP Package](https://pub.dev/packages/http)
- [Provider Package](https://pub.dev/packages/provider)

## 🤝 Support

For issues or questions:
1. Check the integration guide in `lib/data/INTEGRATION_GUIDE.dart`
2. Review the service implementations in `lib/data/`
3. Check backend logs for API errors
4. Verify database connection string is correct

---

**Database URL (reference)**
```
mongodb+srv://ranith:wuzTNpaR14NMMGRZ@painpal.vo4hinw.mongodb.net/painpal?retryWrites=true&w=majority&appName=PainPal
```

**Note**: This should be set as an environment variable in production, not hardcoded.

