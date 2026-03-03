# 🏥 PainPal - MongoDB Backend Integration

## ✅ What's New

This version of PainPal includes full MongoDB and Prisma integration with the backend API. Users can now:

- ✅ Register and login securely
- ✅ Submit structured migraine attack data
- ✅ Upload and classify brain MRI scans
- ✅ View personalized migraine predictions
- ✅ Access comprehensive patient history
- ✅ Track medication adherence
- ✅ Sync data with healthcare providers

## 🗂️ Project Structure

```
lib/
├── main.dart                          # App entry point
├── data/
│   ├── api_client.dart               # Legacy API client (maintained for compatibility)
│   ├── auth_models.dart              # Authentication models
│   ├── auth_service.dart             # Authentication service
│   ├── backend_config.dart           # Backend configuration
│   ├── environment.dart              # Environment configuration
│   ├── patient_data_service.dart     # Patient data service
│   ├── database.dart                 # Local SQLite database
│   ├── models.dart                   # Data models
│   ├── storage.dart                  # Local storage
│   └── INTEGRATION_GUIDE.dart        # Integration guide (documentation)
├── screens/
│   ├── home_screen.dart
│   ├── migraine_form_screen.dart
│   ├── mri_upload_screen.dart
│   ├── history_screen.dart
│   └── settings_screen.dart
└── widgets/
    └── custom_widgets.dart
```

## 🚀 Quick Start

### 1. Install Dependencies

```bash
flutter pub get
```

This installs:
- `http` - HTTP client for API calls
- `shared_preferences` - Secure token storage
- `provider` - State management
- `uuid` - ID generation
- `intl` - Internationalization
- And other utilities

### 2. Configure Backend

The app connects to your MongoDB backend via HTTP API.

**Default Configuration:**
- Backend URL: `http://localhost:3000` (development)
- Database: MongoDB Atlas (`painpal.vo4hinw.mongodb.net`)

**To change the backend URL:**

Edit `lib/data/backend_config.dart`:
```dart
static const String mongoDbApiUrl = 'http://your-api.com:port';
```

Or use build flags:
```bash
flutter run --dart-define=API_URL=http://your-api.com:3000
```

### 3. Update main.dart

The app now uses AuthService for authentication. Update your `main.dart`:

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
      child: const PainpalApp(),
    ),
  );
}
```

### 4. Add Login/Register Screens

Create authentication screens that use `AuthService`:

```dart
class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  Future<void> handleLogin() async {
    final authService = context.read<AuthService>();
    try {
      await authService.login(
        emailController.text,
        passwordController.text,
      );
      // Navigate to home
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            ElevatedButton(
              onPressed: handleLogin,
              child: const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}
```

## 📊 Using the Services

### AuthService - Authentication

```dart
final authService = context.read<AuthService>();

// Check if user is logged in
if (authService.isAuthenticated) {
  print('User: ${authService.currentUser?.email}');
}

// Get user role
if (authService.currentUser?.role == UserRole.patient) {
  print('Patient profile: ${authService.patientProfile?.name}');
}

// Logout
await authService.logout();
```

### PatientDataService - Submit Data

```dart
final patientService = context.read<PatientDataService>();

// Submit migraine event
final attack = MigraineAttack(
  durationHours: 4,
  frequencyPerMonth: 2,
  location: 'Unilateral',
  character: 'Throbbing',
  intensity: 7,
  nausea: 1,
  vomit: 0,
  // ... other fields
  dpf: 'Pattern1',
);

try {
  final response = await patientService.submitMigraineEvent(attack);
  print('Predicted type: ${response.predictedType}');
} catch (e) {
  print('Error: $e');
}
```

### Upload MRI Scans

```dart
final file = File('/path/to/mri.jpg');
final response = await patientService.submitMriScan(image: file);

print('Prediction: ${response.prediction}');
print('Confidence: ${response.confidence}');
```

### Retrieve History

```dart
// Migraine history
final history = await patientService.getMigraineHistory(limit: 10);
for (var event in history) {
  print('${event.startDatetime}: Severity ${event.severity}');
}

// MRI scans
final scans = await patientService.getMriHistory(limit: 10);
for (var scan in scans) {
  print('${scan.prediction}: ${scan.confidence}%');
}

// Medications
final meds = await patientService.getMedicationLogs(limit: 20);
for (var log in meds) {
  print('${log.medicationName}: ${log.dosage}');
}
```

## 🔐 Database Schema

The backend uses MongoDB with Prisma ORM. Key models:

### User (Authentication)
```
- id (ObjectId)
- email (unique)
- passwordHash
- role (ADMIN, PATIENT, DOCTOR)
- googleId (optional)
- createdAt
```

### PatientProfile
```
- id (ObjectId)
- userId (foreign key)
- name
- dateOfBirth
- gender
- phone
- email
- address
- condition
- createdAt
```

### MigraineEvent
```
- id (ObjectId)
- patientId (foreign key)
- startDatetime
- severity (1-10)
- duration
- symptomsLog
- perceivedTriggers
- effectiveness
- createdAt
```

### MriScan
```
- id (ObjectId)
- patientId (foreign key)
- imagePath
- prediction (Tumor/No Tumor)
- confidence (0-1)
- createdAt
```

See `prisma_schema_reference.dart` for the complete schema.

## 🌍 API Endpoints

### Authentication
- `POST /api/auth/login` - Login with email/password
- `POST /api/auth/register` - Register new user
- `POST /api/auth/refresh` - Refresh JWT token

### Patient Data
- `POST /api/summary` - Submit migraine event
- `POST /api/mri/predict` - Upload and classify MRI
- `GET /api/patients/migraine-events` - Get migraine history
- `GET /api/patients/mri-scans` - Get MRI history
- `GET /api/patients/medication-logs` - Get medication history

### Doctor Features (Coming Soon)
- Patient summaries
- Appointments
- Clinical notes
- Conversations with patients

## 🛠️ Configuration Options

### Backend URL
```dart
// lib/data/backend_config.dart
static const String mongoDbApiUrl = 'http://localhost:3000';
```

### Request Timeout
```dart
static const Duration requestTimeout = Duration(seconds: 30);
```

### Max Upload Size
```dart
static const int maxUploadFileSize = 50 * 1024 * 1024; // 50 MB
```

### Features
```dart
static const bool enableOfflineMode = true;
static const bool enableLocalCaching = true;
static const bool enableAutoSync = true;
```

## 🚀 Deployment

### Development
```bash
flutter run --dart-define=ENVIRONMENT=development
```

### Production
```bash
flutter run --dart-define=ENVIRONMENT=production \
  --dart-define=API_URL=https://api.painpal.health
```

## 📚 Documentation

- **Integration Guide**: `lib/data/INTEGRATION_GUIDE.dart`
- **Setup Instructions**: `MONGODB_SETUP_GUIDE.md`
- **Prisma Schema**: `prisma_schema_reference.dart`

## 🔒 Security Notes

✅ **Tokens are securely stored** in SharedPreferences
✅ **Automatic token refresh** when expired
✅ **HTTPS required** in production
✅ **Environment variables** for sensitive config
✅ **Never hardcode** credentials

## 🐛 Troubleshooting

### Cannot connect to backend
- Check backend URL in `BackendConfig`
- Verify backend server is running
- Check network connectivity
- Ensure CORS is configured on backend

### Authentication fails
- Verify email/password are correct
- Check user exists in database
- Ensure backend is processing requests

### Data not syncing
- Check internet connection
- Verify auth token is valid
- Check backend API responses

### Image upload fails
- Check file is JPG/PNG format
- Verify file size < 50 MB
- Ensure backend `/api/mri/predict` endpoint exists

## 📞 Support

For issues:
1. Check `MONGODB_SETUP_GUIDE.md`
2. Review service implementations in `lib/data/`
3. Check backend logs
4. Verify database connection

## 🎨 UI/UX Notes

The app uses a custom color scheme optimized for migraine patients:
- Primary: `#B6F36B` (Lime Green)
- Background: `#0F1218` (Dark)
- Input: `#171B22` (Dark Gray)

Supports both light and dark modes.

## 📦 Project Status

✅ Authentication (login/register)
✅ Patient profiles
✅ Migraine data submission
✅ MRI scan uploads
✅ Data history retrieval
⏳ Doctor dashboard (coming soon)
⏳ Doctor-patient conversations (coming soon)
⏳ Advanced analytics (coming soon)

---

**Last Updated**: March 2026
**Version**: 1.0.0 with MongoDB Integration

