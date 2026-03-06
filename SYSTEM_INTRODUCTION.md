# LLM Project – System Introduction

## 1) Project Overview

**LLM (Painpal)** is a comprehensive healthcare-focused, multi-platform system that combines:

### Web Platform
- A **role-based clinical web platform** (Admin / Doctor / Patient)
- **Backend APIs** for healthcare records and AI-assisted outputs
- **Machine learning pipelines** for text/tabular and brain image classification
- A **chatbot service** for role-restricted, SQL-based data querying
- A **voice agent starter module** (LiveKit)

### Mobile Application
- A **cross-platform mobile app** (Flutter) for patients
- **Offline-first architecture** with local SQLite storage
- **Voice-enabled AI chat assistant** using Gemini AI
- **Camera integration** for MRI image capture and classification
- **Real-time symptom tracking** and migraine event logging

The main objective is to support migraine-related tracking and clinical workflows by collecting patient data, generating structured summaries, and providing model-based predictions across both web and mobile platforms.

---

## 2) System Goals

1. Enable secure, role-based access to clinical and patient workflows (web)
2. Provide mobile-first patient experience with offline capability (mobile)
3. Capture and manage migraine events, medication usage, and doctor-patient interactions
4. Generate AI-assisted summaries and migraine-type predictions from symptom data
5. Support MRI/brain scan capture and classification on mobile devices
6. Provide voice-enabled conversational AI assistance for patients
7. Provide reproducible ML training and inference pipelines
8. Maintain modular architecture for easy scaling and future integration
9. Enable seamless data synchronization between mobile and web platforms

---

## 3) High-Level Architecture

### A. Web Client Layer (`client/`)
- Built with **Next.js + TypeScript**
- Provides dashboards, pages, and API routes
- Includes responsive UI components for doctor/patient/admin experiences
- Supports role-aware navigation and protected route flows

### B. Mobile Client Layer (`lib/`)
- Built with **Flutter + Dart**
- Cross-platform support (Android, iOS, Web, Desktop)
- Material Design 3 with dark theme and custom branding
- Offline-first architecture with local database
- Voice-enabled chat interface with Gemini AI
- Camera integration for medical image capture

### C. Application/API Layer
- **Next.js API routes** (`client/app/api/*`) for CRUD and domain operations
- **Flask service** (`model/main.py`) for:
  - `GET /health`
  - `POST /api/summary` (symptom summary + optional predicted migraine type)
- **Flask chatbot service** (`model/chatbot.py`) using Gemini + SQLAlchemy with role checks

### D. Data Layer
- **Prisma + MongoDB** schema (`client/prisma/schema.prisma`) for web platform users, profiles, events, logs, links, summaries, insights, appointments, and communications
- **SQLite** local database (`painpal.db`) for mobile app offline storage
- **Shared data models** for cross-platform compatibility
- Optional MySQL/SQLite path used by the chatbot module

### E. AI/ML Layer
- **Text Pipeline** (`model/text/`): XGBoost-based migraine type classification
- **Image Pipeline** (`model/image/`): ResNet18-based brain image classification
- **Gemini AI Integration**: Conversational AI for patient support and chat
- **Voice Agent Service**: Speech-to-text and text-to-speech capabilities
- Artifacts saved for repeatable inference (models, encoders, feature columns, class names, transform configs)

---

## 4) User Roles and Core Responsibilities

### Admin (Web Platform)
- Manage users, doctors, patients, and clinics
- Oversee system-level records and governance workflows
- Access broad CRUD operations across modules

### Doctor (Web Platform)
- View assigned patients and migraine history
- Review summaries and AI insights
- Manage notes, appointments, and treatment-related workflows

### Patient (Web + Mobile)
- **Web:** Full clinical record access and appointment management
- **Mobile:** On-the-go migraine event logging and symptom tracking
- **Mobile:** Voice-enabled AI assistant for support and guidance
- **Mobile:** MRI image capture and upload
- **Mobile:** Offline data collection with automatic sync
- Track personal attack history and medication logs
- Receive generated summaries and model-supported outputs

---

## 5) Core Functional Modules

### Web Platform Modules

1. **Authentication & Authorization**
   - Role-based access control (RBAC)
   - Token/session-protected API access
   - Documented path for Clerk integration

2. **Clinical Data Management**
   - Doctor profiles, patient profiles, clinic management
   - Patient-doctor links and status handling
   - Migraine events and medication logs

3. **AI Summary Generation**
   - Converts structured symptom input into readable clinical-style summaries
   - Can return predicted migraine type if model artifacts are available

4. **Migraine Text Classification**
   - End-to-end tabular pipeline:
     - load → preprocess → split → train → evaluate → save → predict
   - Uses XGBoost and stored encoders/artifacts

5. **Brain Image Classification**
   - End-to-end image pipeline with ResNet18:
     - dataset discovery → transforms → split → train → evaluate → save
   - Supports multi-class image outputs based on folder classes

6. **Chatbot Query Module**
   - Uses generative AI to convert natural language to SQL
   - Enforces role-based table authorization before query execution

7. **Responsive Dashboard UI**
   - Mobile, tablet, and desktop breakpoints
   - Touch-friendly patient interactions and adaptive layouts

### Mobile Application Modules

1. **Offline-First Data Storage**
   - Local SQLite database for migraine events
   - MRI scan storage with local file system
   - Draft attack persistence for interrupted sessions
   - Automatic data sync when connectivity restored

2. **Symptom Tracking & Logging**
   - Comprehensive migraine attack form
   - 20+ symptom parameters (binary and categorical)
   - Attack duration, frequency, and intensity tracking
   - Location, character, and DPF (diagnostic pattern features)

3. **MRI Upload & Classification**
   - Camera and gallery integration via `image_picker`
   - Local image storage and management
   - Brain scan submission to classification API
   - Real-time prediction results display

4. **Voice-Enabled AI Chat**
   - Gemini AI integration for conversational support
   - Speech-to-text input via `VoiceAgentService`
   - Text-to-speech output for AI responses
   - Context-aware healthcare assistant
   - Empathetic migraine-focused guidance

5. **History & Analytics**
   - Local attack history with filtering
   - Past MRI scans and predictions
   - Export capabilities for clinical sharing

6. **Settings & Configuration**
   - Backend API URL configuration
   - Patient ID management
   - Data export and privacy controls
   - Draft management

7. **Navigation & UX**
   - Bottom navigation with 5 main screens
   - Floating chat button accessible from anywhere
   - Material Design 3 with dark theme
   - Custom green accent branding (#B6F36B)

---

## 6) Key Data Entities

### Web Platform (Prisma Schema)
- `User` (role, credentials, OAuth fields)
- `DoctorProfile`
- `PatientProfile`
- `Clinic`
- `PatientDoctorLink`
- `MigraineEvent`
- `MedicationLog`
- `MedicationGroup`
- `DoctorPatientSummary`
- `AIDiagnosticInsight`
- `Appointment`
- `ClinicalNote`
- `Communication`

Enums include `Role`, `LinkStatus`, `MedicationType`, `SummaryType`, `RiskAlertLevel`, and others to standardize logic.

### Mobile Application (SQLite Schema)
- `migraine_attacks` table with columns:
  - `id`, `patient_id`, `attack_id`, `age`
  - `Duration`, `Frequency`, `Location`, `Character`, `Intensity`
  - Binary symptoms: `Nausea`, `Vomit`, `Phonophobia`, `Photophobia`, `Visual`, `Sensory`, `Dysphasia`, `Dysarthria`, `Vertigo`, `Tinnitus`, `Hypoacusis`, `Diplopia`, `Defect`, `Ataxia`, `Conscience`, `Paresthesia`
  - `DPF`, `Type`, `created_at`, `synced`
- `mri_scans` table for brain image records
- Shared JSON models for API compatibility

---

## 7) APIs and Contracts

### Flask Summary API
- **Endpoint:** `POST /api/summary`
- **Input:** Migraine symptom JSON (e.g., Duration, Frequency, Location, Character, Intensity, binary symptoms, DPF, optional Age)
- **Output:**
  - `summary`
  - `symptoms_received`
  - optional `predicted_migraine_type`
- **Consumers:** Web platform, Mobile app

### Flask MRI Classification API
- **Endpoint:** `POST /api/classify-mri`
- **Input:** Image file (multipart/form-data)
- **Output:**
  - `prediction` (e.g., "tumor" / "non-tumor")
  - `confidence`
  - optional classification details
- **Consumer:** Mobile app

### Health Check
- `GET /health` returns service status
- Used by both web and mobile for connectivity checks

### Next.js Domain APIs
- Multiple REST-style routes under `client/app/api/` for doctors, patients, migraine events, medication logs, summaries, insights, users, and related resources
- **Authentication:** Bearer token via `Authorization` header
- **Consumer:** Primarily web platform, with mobile sync endpoints

### Mobile-Specific Services
- `ApiClient`: Legacy HTTP client for backward compatibility
- `PatientDataService`: Modern authenticated service for migraine events and MRI scans
- `AuthService`: Authentication state management
- `BackendConfig`: Centralized API endpoint configuration

---

## 8) Technology Stack

### Web Platform
- **Frontend:** Next.js, TypeScript, Tailwind CSS/CSS modules
- **Backend APIs:** Next.js route handlers + Flask
- **ORM/DB:** Prisma with MongoDB (plus SQLAlchemy path for chatbot)
- **ML/Data:** Python, XGBoost, PyTorch (ResNet18), pandas, joblib
- **AI Integration:** Google Gemini (chatbot and text-generation contexts)
- **Agent Module:** LiveKit starter project included under `testproject/`

### Mobile Application
- **Framework:** Flutter 3.11+ with Dart SDK 3.11+
- **State Management:** Provider pattern
- **Local Storage:** SQLite via `sqflite`, SharedPreferences
- **HTTP Client:** `http` package with `dio` for advanced networking
- **Image Handling:** `image_picker`, `path_provider`
- **AI/Voice:** 
  - `google_generative_ai` (Gemini integration)
  - `flutter_tts` (text-to-speech)
  - Native speech recognition via MethodChannel
- **Environment Config:** `flutter_dotenv`
- **Utilities:** `uuid`, `intl`, `path`
- **Platform Support:** Android, iOS (with Web/Desktop capability)

### Cross-Platform Integration
- **Shared Data Models:** JSON-serializable models for API compatibility
- **Consistent Symptom Schema:** Unified across web and mobile
- **Backend Abstraction:** Configurable API endpoints for flexibility

---

## 9) Mobile Application Screens

### 1. Overview Screen
- Welcome message and app introduction
- Quick stats and recent activity summary
- Feature highlights and getting started guide
- Direct navigation to key functions

### 2. Log Attack Screen (Migraine Form)
- Comprehensive symptom input form
- Duration, frequency, intensity sliders/inputs
- Location dropdown (Unilateral/Bilateral)
- Character dropdown (Throbbing/Pressing/Stabbing)
- Binary symptom toggles (20+ symptoms)
- DPF pattern selection
- Draft auto-save functionality
- Submission with AI summary generation

### 3. MRI Upload Screen
- Camera capture or gallery selection
- Image preview with zoom capability
- Local storage management
- Submission to brain classification API
- Prediction results display
- History of uploaded scans

### 4. History Screen
- Chronological list of migraine attacks
- Filter and search capabilities
- Attack details view with all symptoms
- MRI scan history with predictions
- Export functionality for clinical sharing

### 5. Settings Screen
- Backend API URL configuration
- Patient ID management
- Theme and display preferences
- Data management (clear drafts, export data)
- Privacy and security settings
- About and version information

### Floating Chat Button
- Accessible from all screens
- Opens AI chat dialog overlay
- Voice input button (microphone icon)
- Text input with message history
- Auto-speaks AI responses via TTS
- Gemini AI with healthcare context

---

## 10) Mobile Application Features

### Offline-First Architecture
- All migraine data stored locally in SQLite
- No internet required for symptom logging
- Background sync when connectivity available
- Conflict resolution for synced data
- Draft persistence across app sessions

### Voice-Enabled AI Assistant
- **Gemini AI Integration:**
  - Model: gemini-2.0-flash
  - Temperature: 0.7 for balanced responses
  - Max tokens: 1024
  - Healthcare-focused system prompt
- **Speech-to-Text:**
  - Platform-specific native speech recognition
  - Real-time transcription feedback
  - Error handling and retry logic
- **Text-to-Speech:**
  - `flutter_tts` for AI response reading
  - Configurable speech rate (0.85x)
  - Natural voice output
  - Automatic speaking on AI response

### Camera & Image Processing
- Native camera access with permissions
- Gallery/photo library integration
- Image compression and optimization (quality: 92%)
- Local file system storage
- Multipart form upload to backend
- Progress indication and error handling

### Data Persistence
- **SQLite Database:**
  - Migraine attacks with full symptom detail
  - MRI scans with metadata
  - Sync status tracking
- **SharedPreferences:**
  - Settings storage (API URL, patient ID)
  - Draft attack auto-save
  - User preferences
- **File System:**
  - MRI images stored in app documents directory
  - Secure local storage

### Security & Privacy
- RECORD_AUDIO permission for voice input
- CAMERA permission for image capture
- READ_MEDIA_IMAGES/READ_EXTERNAL_STORAGE for gallery
- INTERNET permission for API communication
- Local encryption capability (ready to implement)
- Secure API token storage

### Cross-Platform Support
- **Android:**
  - API Level 21+ (Android 5.0+)
  - Kotlin integration ready
  - Material Design native components
- **iOS:**
  - iOS 12.0+
  - Swift integration ready
  - Cupertino design patterns
  - Export options and build guides included
- **Web/Desktop:**
  - Framework support available
  - Additional testing required

---

## 11) Non-Functional Characteristics

### Web Platform
- **Security:** Role-based authorization and protected endpoints
- **Usability:** Responsive layouts and patient-friendly interaction patterns
- **Scalability:** Modular architecture supports incremental expansion
- **Maintainability:** Separated concerns across UI, API, DB schema, and ML pipelines
- **Interoperability:** Shared symptom schema across UI/API/model layers
- **Reliability:** Health endpoint and structured error handling paths

### Mobile Application
- **Performance:** Offline-first for instant responsiveness
- **Reliability:** Local data persistence prevents data loss
- **Usability:** Touch-optimized UI with large tap targets
- **Accessibility:** Material Design 3 accessibility standards
- **Battery Efficiency:** Optimized network calls and background processing
- **Storage Efficiency:** Compressed images and optimized database queries
- **Privacy:** Local-first data storage with user control
- **Maintainability:** Clean architecture with service layer separation

---

## 12) Development Setup

### Web Platform
```bash
cd client
npm install
npx prisma generate
npm run dev
```

### Mobile Application
```bash
# Install dependencies
flutter pub get

# Create .env file
cp .env.example .env
# Edit .env and add GEMINI_API_KEY

# Run on device/emulator
flutter run

# Build for production
flutter build apk        # Android
flutter build ios        # iOS (macOS only)
```

### Backend Services
```bash
cd model
pip install -r requirements.txt
python main.py           # Summary API
python chatbot.py        # Chatbot service
```

---

## 13) Mobile App Configuration

### Required Permissions

**Android (AndroidManifest.xml):**
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.INTERNET" />
```

**iOS (Info.plist):**
```xml
<key>NSCameraUsageDescription</key>
<string>Access camera to capture MRI scans</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Access photos to select MRI images</string>
<key>NSMicrophoneUsageDescription</key>
<string>Access microphone for voice chat</string>
```

### Environment Variables (.env)
```
GEMINI_API_KEY=your_gemini_api_key_here
LIVEKIT_URL=ws://your-livekit-server:7880  # Optional
LIVEKIT_API_KEY=your_livekit_key           # Optional
LIVEKIT_API_SECRET=your_livekit_secret     # Optional
```

### Backend Configuration (Settings Screen)
- Default API URL: `http://localhost:5000`
- Production: `https://your-api-domain.com`
- Patient ID: Optional identifier for backend association

---

## 14) Current Status

### Implemented
- ✅ Multi-role data models and API foundations (web)
- ✅ Summary API and prediction integration path
- ✅ XGBoost and ResNet training/inference pipelines
- ✅ Responsive dashboard groundwork (web)
- ✅ Cross-platform mobile app with Flutter
- ✅ Offline-first SQLite storage (mobile)
- ✅ Voice-enabled AI chat with Gemini (mobile)
- ✅ Camera integration and MRI upload (mobile)
- ✅ Comprehensive symptom tracking (mobile)
- ✅ Material Design 3 dark theme (mobile)
- ✅ Android and iOS support

### In Progress / To Harden
- 🔄 Full production authentication integration across all flows
- 🔄 End-to-end offline sync behaviors between mobile and web
- 🔄 Expanded production-grade testing, observability, and scale benchmarking
- 🔄 iOS production build signing and deployment
- 🔄 Mobile-to-web data synchronization service
- 🔄 Enhanced analytics and patient insights dashboard
- 🔄 Push notifications for medication reminders
- 🔄 Multi-language support for mobile app

---

## 15) Integration Flow: Mobile ↔ Web

### Patient Journey
1. **Mobile:** Patient logs migraine attack offline
2. **Mobile:** Local SQLite storage for immediate access
3. **Mobile:** Background sync when online
4. **Backend:** Flask API receives and processes data
5. **Backend:** AI generates summary and prediction
6. **Web:** Doctor reviews in clinical dashboard
7. **Web:** Doctor adds notes and treatment plan
8. **Mobile:** Patient receives updates on next sync

### Data Synchronization
- **Conflict Resolution:** Last-write-wins with timestamp
- **Batch Uploads:** Multiple events synced together
- **Status Tracking:** `synced` flag in mobile database
- **Retry Logic:** Exponential backoff on network errors

---

## 16) Safety Disclaimer

This system is intended for **education, research, and self-tracking support**. Any predicted migraine type or AI-generated output is **not a medical diagnosis** and must not replace professional clinical judgment. Users should consult qualified healthcare providers for diagnosis and treatment decisions.

### Specific Disclaimers

**Mobile Application:**
- Voice AI assistant provides general support only
- MRI classification is for educational purposes
- Symptom tracking does not replace medical examination
- Always seek emergency care for severe symptoms

**Web Platform:**
- AI-generated summaries support clinical workflow but require doctor review
- Predictive models are research tools, not diagnostic devices
- Clinical decisions must be made by qualified professionals

---

## 17) Documentation References

### Mobile Application
- `README.md` - Mobile app overview and quick start
- `VOICE_AGENT_IMPLEMENTATION.md` - Voice AI feature details
- `LIVEKIT_GEMINI_SETUP.md` - Gemini AI and voice setup guide
- `VOICE_AGENT_SETUP.md` - Complete voice agent configuration
- `IOS_BUILD_GUIDE.md` - iOS deployment instructions
- `iOS_SETUP_GUIDE.md` - iOS development setup
- `IOS_COMPLETE_SOLUTION.md` - iOS troubleshooting
- `lib/data/IMPLEMENTATION_EXAMPLES.dart` - Code examples
- `lib/data/INTEGRATION_GUIDE.dart` - Service integration guide

### Web Platform
- `QUICK_START.md` - Web platform quick start
- `MONGODB_SETUP_GUIDE.md` - Database configuration
- `MONGODB_INTEGRATION_README.md` - MongoDB integration details
- `UI_IMPROVEMENTS.md` - UI/UX enhancements

### Project-Wide
- `IMPLEMENTATION_COMPLETE.md` - Feature completion status
- `client/prisma/schema.prisma` - Database schema reference

---

## 18) Contact & Support

For development questions or contributions:
- Review inline code documentation
- Check relevant `.md` files in project root
- Ensure environment variables are properly configured
- Test on both Android and iOS for mobile changes
- Follow Material Design 3 guidelines for UI modifications

---

**Version:** 1.0.0  
**Last Updated:** March 4, 2026  
**Platforms:** Web (Next.js), Mobile (Flutter - Android/iOS)  
**License:** [Specify License]

