# PainPal - Migraine Management & Tracking App

> A comprehensive Flutter mobile application for migraine tracking, analysis, and management with AI-powered insights.

**Version**: 1.0.0  
**Platform**: iOS, Android  
**Framework**: Flutter 3.11+  

---

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Screenshots](#screenshots)
- [Getting Started](#getting-started)
- [App Architecture](#app-architecture)
- [User Guide](#user-guide)
- [Technical Details](#technical-details)
- [API Integration](#api-integration)
- [Disclaimer](#disclaimer)

---

## 🎯 Overview

PainPal is a modern, user-friendly mobile application designed to help individuals manage and track their migraines effectively. The app combines comprehensive symptom logging, data analytics, AI-powered predictions, and MRI analysis to provide users with actionable insights into their migraine patterns.

### Key Highlights

- 📊 **Comprehensive Tracking**: Log detailed migraine attacks with 20+ symptoms
- 🤖 **AI Predictions**: Get migraine type predictions using machine learning
- 📈 **Analytics Dashboard**: View patterns, trends, and statistics
- 🧠 **MRI Analysis**: Upload and analyze brain MRI scans
- 💬 **AI Chat Assistant**: Chat with Gemini AI for migraine-related queries
- 🗣️ **Voice Agent**: Voice-enabled interaction (Text-to-Speech)
- 🌓 **Dark/Light Mode**: Eye-friendly themes for any lighting condition
- 💾 **Offline Support**: Works without internet, syncs when connected
- 🔒 **Privacy First**: All data stored locally on your device

---

## ✨ Features

### 1. **Migraine Tracking & Logging**
- **Quick Logging**: Record attacks with comprehensive symptom checklist
- **Attack Pattern Analysis**: Track duration, frequency, location, and character
- **Pain Intensity Scale**: 10-point scale for accurate pain measurement
- **Associated Symptoms**: 
  - Nausea, vomiting
  - Light sensitivity (photophobia)
  - Sound sensitivity (phonophobia)
  - Visual disturbances
  - Sensory issues
- **Neurological Symptoms**:
  - Speech difficulties (dysphasia, dysarthria)
  - Dizziness and vertigo
  - Hearing issues (tinnitus, hypoacusis)
  - Vision problems (diplopia, visual field defects)
  - Coordination loss (ataxia)
  - Consciousness changes
  - Abnormal sensations (paresthesia)
- **Draft Support**: Save incomplete entries and resume later
- **Inline Form**: Form appears on-demand in tracking screen

### 2. **Analytics & Insights**
- **Statistics Dashboard**:
  - Total attacks count
  - Average duration and intensity
  - Attack frequency per month
- **Visual Charts**:
  - Attack frequency over time
  - Intensity distribution
  - Trigger analysis
  - Symptom patterns
  - Migraine type distribution
- **Timeline View**: Recent attacks with detailed information
- **Date Range Filtering**: 
  - Last week, month, 3 months, 6 months, year
  - Custom date range selection
  - All-time view
- **Pattern Recognition**: Identify trends in your migraine history

### 3. **MRI Upload & Analysis**
- **Image Upload**: Take photo or select from gallery
- **Brain MRI Classification**: Tumor vs non-tumor prediction
- **Result Display**: Clear prediction results with confidence levels
- **History Tracking**: Review past MRI analyses

### 4. **AI Chat Assistant**
- **Gemini AI Integration**: Powered by Google's Gemini AI
- **Natural Conversations**: Ask questions about migraines
- **Medical Information**: Get insights about symptoms and treatments
- **Context-Aware**: Understands follow-up questions
- **Voice Output**: Text-to-speech for responses

### 5. **Voice Agent**
- **Text-to-Speech**: Hear responses read aloud
- **Accessibility**: Perfect for hands-free interaction
- **Multiple Languages**: Support for various languages

### 6. **History Management**
- **Complete Attack History**: View all logged attacks
- **Detailed Records**: See every symptom and detail
- **Search & Filter**: Find specific attacks easily
- **Export Ready**: Data structured for export

### 7. **Themes & Customization**
- **Dark Mode**: Eye-friendly for low-light environments
  - Deep navy backgrounds (#0F1218)
  - Lime green accents (#B6F36B)
  - Perfect for OLED screens
- **Light Mode**: Professional high-contrast design
  - Light backgrounds (#F5F7FA)
  - Dark green accents (#8BC34A)
  - Excellent readability in daylight
- **Instant Switching**: Change themes with one tap
- **Persistent Preference**: Theme saves automatically

### 8. **Settings & Configuration**
- **API Configuration**: Set backend server URL
- **Patient ID**: Optional unique identifier
- **Theme Selection**: Choose light or dark mode
- **App Information**: Version and about details

---

## 📱 Screenshots

### Main Screens

**Overview**
- Welcome screen with app features
- Quick start guide for new users

**Tracking**
- Empty state with "Log Your First Attack" button
- Inline form for logging attacks
- Analytics dashboard with charts and statistics

**MRI Upload**
- Camera and gallery options
- Upload interface with preview
- Analysis results display

**History**
- List of all logged attacks
- Detailed view for each entry
- Date and symptom information

**Settings**
- Theme toggle (Light/Dark)
- API configuration
- App information and disclaimer

---

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK**: 3.11.0 or higher
- **Dart SDK**: Included with Flutter
- **IDE**: Android Studio, VS Code, or IntelliJ IDEA
- **Device/Emulator**: iOS 12+ or Android 5.0+

### Installation

1. **Clone the repository** (or extract the project)
   ```bash
   cd painpal
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Create environment file**
   ```bash
   cp .env.example .env
   ```
   
   Edit `.env` and add your API keys:
   ```
   GEMINI_API_KEY=your_gemini_api_key_here
   ```

4. **Run the app**
   ```bash
   # For Android
   flutter run
   
   # For iOS
   flutter run --ios
   
   # For specific device
   flutter devices  # List available devices
   flutter run -d <device_id>
   ```

### First Time Setup

1. **Open the app**
2. **Navigate to Settings** (last tab)
3. **Configure API** (optional):
   - Enter your backend server URL
   - Add patient ID if needed
4. **Choose Theme**: Select Light or Dark mode
5. **Start Tracking**: Go to Tracking tab and log your first attack

---

## 🏗️ App Architecture

### Navigation Structure

```
Home Screen (Bottom Navigation)
├── Overview (Index 0)
│   ├── Welcome message
│   ├── Feature cards
│   └── Quick start guide
│
├── MRI Upload (Index 1)
│   ├── Camera capture
│   ├── Gallery selection
│   ├── Image upload
│   └── Analysis results
│
├── Tracking (Index 2) ⭐ Main Feature
│   ├── Empty State
│   │   └── "Log Your First Attack" button
│   │       └── Shows inline form
│   │
│   ├── Logging Form (when button clicked)
│   │   ├── Attack pattern (duration, frequency, location)
│   │   ├── Pain description (character, intensity)
│   │   ├── Associated symptoms (20+ checkboxes)
│   │   ├── Neurological symptoms
│   │   ├── Optional details (age, attack ID)
│   │   ├── Submit to backend
│   │   └── Save as draft
│   │
│   └── Analytics Dashboard (when data exists)
│       ├── Date range selector
│       ├── Quick stats overview
│       ├── Attack frequency chart
│       ├── Intensity analysis
│       ├── Trigger analysis
│       ├── Symptom patterns
│       ├── Type distribution
│       └── Recent timeline
│
├── History (Index 3)
│   ├── Attack list
│   ├── Detailed views
│   └── Search/filter
│
└── Settings (Index 4)
    ├── Appearance (Theme toggle)
    ├── API Configuration
    ├── Disclaimer
    └── About

Floating Action Button
└── AI Chat Assistant
    ├── Chat interface
    ├── Gemini AI responses
    └── Voice output
```

### Screen Flow

```
User Opens App
    ↓
Overview Screen (Welcome)
    ↓
Tracking Tab (Main Feature)
    ↓
No Data? → Click "Log First Attack" → Form Appears
    ↓
Fill Form → Submit → Analytics Appear
    ↓
Has Data? → View Charts & Statistics
    ↓
MRI Tab (Optional) → Upload Scan → Get Results
    ↓
History Tab → View Past Attacks
    ↓
Settings Tab → Configure & Customize
```

---

## 👥 User Guide

### How to Log a Migraine Attack

1. **Open Tracking Tab** (3rd icon in bottom navigation)
2. **Click "Log Your First Attack"** button
3. **Fill out the form**:
   - **When**: Duration (hours) and frequency (per month)
   - **Where**: Unilateral or bilateral location
   - **How**: Throbbing or pressure character
   - **Intensity**: Slide to rate pain level (1-10)
   - **Symptoms**: Check all that apply
   - **Neurological**: Mark serious symptoms
   - **Optional**: Add age and attack ID
4. **Submit Options**:
   - **Submit to backend**: Get AI prediction
   - **Save as draft**: Save for later
5. **View Results**: See prediction and summary

### How to View Analytics

1. After logging at least one attack
2. Open **Tracking Tab**
3. See dashboard with:
   - Quick statistics
   - Frequency chart
   - Intensity breakdown
   - Common triggers
   - Symptom patterns
4. **Filter by date**: Select time range
5. **Refresh**: Pull down or tap refresh icon

### How to Upload MRI

1. Open **MRI Upload Tab** (2nd icon)
2. Choose option:
   - **Take Photo**: Use camera
   - **Choose from Gallery**: Select existing image
3. Confirm image selection
4. Wait for analysis
5. View prediction result

### How to Use AI Chat

1. Tap the **chat bubble** (floating button)
2. Type your question about migraines
3. Press send
4. Read AI response
5. Ask follow-up questions
6. Close dialog when done

### How to Change Theme

1. Open **Settings Tab** (last icon)
2. Find **Appearance** section at top
3. Tap **Light** or **Dark** button
4. Theme changes instantly
5. Preference saves automatically

---

## 🔧 Technical Details

### Tech Stack

- **Framework**: Flutter 3.11+
- **Language**: Dart
- **State Management**: Provider
- **Storage**: 
  - SQLite (local database)
  - SharedPreferences (settings)
- **APIs**:
  - Google Gemini AI
  - Custom backend REST API
- **Image Processing**: Flutter image picker
- **Voice**: Flutter TTS (Text-to-Speech)

### Key Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # HTTP & Networking
  http: ^1.2.2
  dio: ^5.4.0
  web_socket_channel: ^3.0.1
  
  # State Management
  provider: ^6.1.0
  
  # Storage
  sqflite: ^2.4.0
  shared_preferences: ^2.3.2
  path_provider: ^2.1.4
  
  # Media
  image_picker: ^1.1.2
  
  # AI Integration
  google_generative_ai: ^0.4.0
  
  # Voice
  flutter_tts: ^3.8.1
  
  # Utils
  uuid: ^4.0.0
  intl: ^0.19.0
  flutter_dotenv: ^5.1.0
```

### Project Structure

```
lib/
├── main.dart                    # App entry point
├── data/
│   ├── api_client.dart         # Backend API client
│   ├── database.dart           # SQLite database
│   ├── models.dart             # Data models
│   ├── storage.dart            # Settings storage
│   ├── theme_provider.dart     # Theme state management
│   ├── app_theme.dart          # Theme definitions
│   ├── gemini_ai_service.dart  # AI chat service
│   └── patient_data_service.dart
├── screens/
│   ├── home_screen.dart        # Main navigation
│   ├── overview_screen.dart    # Welcome/overview
│   ├── tracking_screen.dart    # Tracking & logging (merged)
│   ├── mri_upload_screen.dart  # MRI upload
│   ├── history_screen.dart     # Attack history
│   └── settings_screen.dart    # Settings & config
└── widgets/
    ├── custom_widgets.dart     # Reusable UI components
    └── chat_widget.dart        # AI chat dialog
```

### Data Models

**MigraineAttack**
```dart
{
  id: int (auto),
  durationHours: int,
  frequencyPerMonth: int,
  location: String ('Unilateral' | 'Bilateral'),
  character: String ('Throbbing' | 'Pressure'),
  intensity: int (1-10),
  nausea: int (0 | 1),
  vomit: int (0 | 1),
  phonophobia: int (0 | 1),
  photophobia: int (0 | 1),
  visual: int (0 | 1),
  sensory: int (0 | 1),
  dysphasia: int (0 | 1),
  dysarthria: int (0 | 1),
  vertigo: int (0 | 1),
  tinnitus: int (0 | 1),
  hypoacusis: int (0 | 1),
  diplopia: int (0 | 1),
  defect: int (0 | 1),
  ataxia: int (0 | 1),
  conscience: int (0 | 1),
  paresthesia: int (0 | 1),
  dpf: String ('Pattern1' | 'Pattern2' | 'Pattern3'),
  type: String (predicted migraine type),
  patientId: String (optional),
  attackId: String (optional),
  age: int (optional),
  timestamp: DateTime,
  summary: String (AI-generated)
}
```

### Database Schema

**Table: migraine_attacks**
- All fields from MigraineAttack model
- Primary key: id (INTEGER AUTOINCREMENT)
- Indexed by: timestamp, type
- Stored locally in SQLite

**Table: mri_results**
- id, imagePath, prediction, confidence, timestamp

### Theme System

**Architecture**:
- Provider pattern for state management
- SharedPreferences for persistence
- Material 3 design system

**Color Tokens**:

| Element | Dark Mode | Light Mode |
|---------|-----------|------------|
| Primary | #B6F36B | #8BC34A |
| Background | #0F1218 | #F5F7FA |
| Surface | #171B22 | #FFFFFF |
| Cards | #1E2329 | #F8F9FA |
| Text Primary | #FFFFFF | #1A1D1F |
| Text Secondary | #B0B8C1 | #6F767E |

---

## 🌐 API Integration & MongoDB Atlas

The Flutter app **does not connect to MongoDB directly**. It talks to your **backend API** (e.g. the Next.js app in `../LLM/client`). The backend uses **Prisma** and connects to **MongoDB Atlas** via `DATABASE_URL`.

### Connecting to MongoDB Atlas

1. **Backend (e.g. `LLM/client`)**  
   - Copy `LLM/client/.env.example` to `.env`.  
   - Set `DATABASE_URL` to your MongoDB Atlas connection string (Atlas → Cluster → Connect → “Connect your application”).  
   - Run the backend (e.g. `npm run dev`). The backend uses this URL to read/write data.

2. **Flutter app**  
   - Open **Settings** → **API Configuration**.  
   - Set **API Base URL** to your backend base URL (e.g. `http://localhost:3000` for local dev, or your deployed backend URL).  
   - Leave blank to use the default for the current environment (see `lib/data/environment.dart`).

3. **Local development**  
   - Backend: `http://localhost:3000` (or your dev server URL).  
   - On Android emulator use `http://10.0.2.2:3000` instead of `localhost`.

### Backend Requirements

Your backend should provide these endpoints:

**1. Submit Migraine Attack**
```
POST /api/summary
Content-Type: application/json

Request Body:
{
  "Duration": int,
  "Frequency": int,
  "Location": string,
  "Character": string,
  "Intensity": int,
  // ... all symptom fields
  "DPF": string,
  "Age": int (optional)
}

Response:
{
  "summary": "Clinical summary text",
  "predicted_migraine_type": "Type classification",
  "symptoms_received": {...}
}
```

**2. MRI Classification**
```
POST /api/classify-mri
Content-Type: multipart/form-data

Form Data:
- image: file

Response:
{
  "prediction": "tumor" | "no_tumor",
  "confidence": float
}
```

### API Configuration

1. Go to **Settings** tab
2. Enter **API Base URL**: `https://your-backend.com`
3. Optionally add **Patient ID**
4. Save settings

### Offline Functionality

- All attacks saved locally first
- Can use app without backend
- Predictions require API connection
- Data syncs when online

---

## ⚠️ Disclaimer

**IMPORTANT: Please Read Carefully**

### Educational Purpose Only
This app is designed for **educational and self-tracking purposes only**. It is NOT a medical device and should NOT be used for medical diagnosis or treatment decisions.

### Not a Medical Diagnosis
- The predictions and classifications provided by this app are **NOT medical diagnoses**
- AI predictions are based on patterns and should not replace professional medical evaluation
- MRI analysis is for educational demonstration only

### Consult Healthcare Professionals
- **Always consult qualified healthcare professionals** for proper diagnosis, treatment recommendations, and medical advice
- If you experience severe symptoms, seek immediate medical attention
- Do not modify your treatment plan based solely on app predictions

### No Emergency Use
- This app should **NOT be used for emergency medical situations**
- In case of emergency, contact emergency services (911, 112, etc.) immediately
- Severe neurological symptoms require immediate medical attention

### Data Privacy
- All data is stored locally on your device
- Backend integration is optional
- Review your backend provider's privacy policy
- Keep your device secure with PIN/biometric lock

### Accuracy Limitations
- Symptom tracking depends on accurate user input
- AI predictions have inherent error margins
- Individual experiences may vary significantly
- App cannot replace clinical examination

**By using this app, you acknowledge that you have read and understood this disclaimer.**

---

## 🛠️ Development

### Build for Release

**Android APK**:
```bash
flutter build apk --release
```

**Android App Bundle**:
```bash
flutter build appbundle --release
```

**iOS**:
```bash
flutter build ios --release
```

### Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage
```

### Code Quality

```bash
# Analyze code
flutter analyze

# Format code
flutter format lib/
```

---

## 📝 Version History

### Version 1.0.0 (March 2026)
- ✅ Initial release
- ✅ Migraine tracking with 20+ symptoms
- ✅ Analytics dashboard with charts
- ✅ MRI upload and classification
- ✅ AI chat assistant (Gemini)
- ✅ Voice agent (TTS)
- ✅ Dark/Light theme support
- ✅ Merged tracking & logging screens
- ✅ Offline support with SQLite
- ✅ Draft saving and loading
- ✅ Material 3 design

---

## 🤝 Support

### Common Issues

**Q: App won't connect to backend?**
A: Check Settings → API Configuration. Ensure URL is correct and server is running.

**Q: Theme not changing?**
A: Tap the theme button once, wait 1-2 seconds for transition.

**Q: Form not appearing?**
A: Make sure you click "Log Your First Attack" button in Tracking tab.

**Q: MRI upload failing?**
A: Check camera/storage permissions in device settings.

**Q: Chat not responding?**
A: Verify GEMINI_API_KEY is set in .env file.

### Reporting Issues

For bugs or feature requests:
1. Check existing documentation
2. Verify you're on latest version
3. Note device model and OS version
4. Describe steps to reproduce

---

## 📄 License

This project is provided for educational purposes. Check with your institution or organization for specific licensing terms.

---

## 🙏 Acknowledgments

- **Flutter Team**: For the amazing framework
- **Google Gemini**: For AI chat capabilities
- **Material Design**: For design guidelines
- **Open Source Community**: For various packages and tools

---

## 📞 Quick Reference

### Navigation
- **5 Tabs**: Overview, MRI, Tracking, History, Settings
- **Chat Button**: Floating button (bottom right)
- **Main Feature**: Tracking tab (middle)

### Key Features
- **Log Attack**: Tracking → Click button → Fill form
- **View Analytics**: Tracking → Select date range
- **Upload MRI**: MRI tab → Camera/Gallery
- **Chat AI**: Tap chat bubble → Type question
- **Change Theme**: Settings → Appearance

### Keyboard Shortcuts (Desktop)
- None (mobile-first design)

---

**Made with ❤️ for migraine management**

**Current Version**: 1.0.0  
**Last Updated**: March 7, 2026  
**Status**: Production Ready ✅

