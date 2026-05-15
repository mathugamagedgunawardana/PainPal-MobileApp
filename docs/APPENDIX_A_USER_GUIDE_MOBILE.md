# Appendix A — User Guide: Mobile App (Painpal / Flutter)

This document covers the **Painpal** Flutter mobile app in the `painpal` repository: requirements, installation, running on devices/emulators, linking to the Next.js API, environment variables, permissions, login, and suggested screenshots.

The mobile app talks to the **same backend origin** as the web dashboard: the Next.js app under `LLM/client` (REST routes such as `/api/summary`, `/api/mri/predict`, `/api/auth/login`, and patient-scoped routes under `/api/patient/...`).

---

## 1. System requirements

| Component | Notes |
|-----------|--------|
| **Flutter SDK** | Compatible with **Dart ^3.11.0** (see `pubspec.yaml` `environment.sdk`). Install Flutter per [https://docs.flutter.dev/get-started/install](https://docs.flutter.dev/get-started/install). |
| **IDE** | VS Code or Android Studio with Flutter/Dart plugins. |
| **Android** | Android SDK / emulator or physical device with USB debugging. |
| **iOS** (optional) | Xcode on macOS for simulator or device builds. |
| **Network** | Device or emulator must reach your Next.js API (see **API base URL** below). |

---

## 2. Installation steps

```bash
cd painpal
flutter pub get
```

For iOS (macOS only):

```bash
cd ios
pod install   # if your project uses CocoaPods integration
cd ..
```

---

## 3. How to run the mobile app

**List devices:**

```bash
flutter devices
```

**Run on a selected device:**

```bash
flutter run
```

Or specify a device ID:

```bash
flutter run -d <device_id>
```

**Release build (example, Android):**

```bash
flutter build apk
```

---

## 4. Backend setup (what you need running)

1. Start the **Next.js** server from `LLM/client` (`npm run dev`), typically at **http://127.0.0.1:3000**.
2. Ensure **MongoDB** and `client/.env` are configured on the server (see `LLM/docs/APPENDIX_A_USER_GUIDE_WEB.md`).
3. **Optional:** Start the **Python FastAPI** service (`LLM/model/main.py`) if you rely on server-side model endpoints that Next.js proxies to `MODEL_API_URL`.

The app resolves the API origin in this order (see `lib/data/auth_service.dart`):

1. **Settings → API Base URL** (stored locally), else  
2. **`API_BASE_URL`** in the mobile `.env`, else  
3. Fallback **`http://localhost:3000`** (`BackendConfig.mongoDbApiUrl`).

**Android emulator note:** `localhost` / `127.0.0.1` on the emulator refers to the emulator itself. The app maps those hosts to **`10.0.2.2`** automatically so they reach your development machine (see `lib/util/api_origin.dart`). You can also set the base URL explicitly to `http://10.0.2.2:3000` in Settings.

**Physical phone:** use your computer’s LAN IP (e.g. `http://192.168.1.x:3000`) and ensure the firewall allows inbound connections on the Next.js port.

---

## 5. Environment variables (mobile)

Copy the example file in the **painpal** project root:

```bash
cp .env.example .env
```

| Variable | Purpose |
|----------|---------|
| `GEMINI_API_KEY` | Google Gemini API key for the in-app AI assistant ([Google AI Studio](https://aistudio.google.com/app/apikey)). |
| `API_BASE_URL` | Default Next.js origin when the user has not set **API Base URL** in Settings, e.g. `http://127.0.0.1:3000` for local dev. **No trailing slash.** |

The app loads `.env` at startup via `flutter_dotenv` (see project `README.md`).

> `DATABASE_URL` appears in some tooling/docs as a **server-side** concern only; the mobile app does **not** connect to MongoDB directly.

---

## 6. Database configuration (mobile perspective)

Patients do not configure MongoDB in the app. All persistent cloud data goes through **Next.js + Prisma**. Local data uses:

- **`shared_preferences`** — API base URL, patient id, drafts  
- **`sqflite`** — offline history for migraines and MRI rows after successful sync where implemented  

Ensure the **backend** database is configured so login and `/api/patient/*` calls succeed.

---

## 7. API setup (mobile-relevant endpoints)

Base URL = your Next.js origin (no trailing slash). Common paths (see `lib/data/backend_config.dart`):

| Area | Method / path |
|------|----------------|
| Login | `POST /api/auth/login` |
| Register / refresh | `POST /api/auth/register`, `POST /api/auth/refresh` |
| Migraine submit + prediction | `POST /api/summary` |
| MRI upload + prediction | `POST /api/mri/predict` |
| Patient migraine list | `GET /api/patient/migraine-events` |
| Patient MRI list | `GET /api/patient/mri-scans` |
| Analytics | `GET /api/patient/analytics` |
| AI summary | `GET /api/patient/ai-summary` |
| AI context (full export for Gemini) | `GET /api/patient/ai-context` |
| Medication schedule | `GET /api/patient/medication-schedule` |
| Chat | `GET/POST` under `/api/chat/conversations` |

Use **`client/API_AUTH.md`** in the LLM repo for role matrix and curl examples.

---

## 8. Login instructions (mobile)

Use the same **development** accounts as the web API (unless you only use seeded DB users — then use those emails/passwords).

Open the app’s **sign-in** flow (where implemented), then:

### 8.1 Admin

| Field | Value |
|-------|--------|
| Email | `admin@painpal.com` |
| Password | `Admin@123` |

### 8.2 Doctor

| Field | Value |
|-------|--------|
| Email | `doctor@painpal.com` |
| Password | `Doctor@123` |

### 8.3 Patient

| Field | Value |
|-------|--------|
| Email | `patient@painpal.com` |
| Password | `Patient@123` |

**Settings:** set **API Base URL** to your running Next.js URL if the default does not work on your device/emulator.

---

## 9. Basic workflows (mobile)

### 9.1 Creating a migraine log

1. Open **Log attack** (or the migraine form screen from the bottom navigation).  
2. Fill required fields (duration, frequency, location, character, intensity, symptoms, etc.).  
3. Optionally save a **draft** and resume later.  
4. Submit: the app calls **`POST /api/summary`**, shows prediction/summary cards, then saves to **local SQLite** history.

### 9.2 Viewing AI predictions / analytics

- After logging attacks, open **Analytics** to see trends, trigger breakdowns, medication effectiveness, and short **AI insight** cards (driven by local history and/or `GET /api/patient/analytics` when authenticated).  
- Configure **`GEMINI_API_KEY`** for the floating **AI chat** (text/voice) features.

### 9.3 Doctor reviewing patient reports (mobile)

If your build includes doctor messaging or dashboards, sign in as **doctor** and use the screens wired to **`/api/chat/conversations`** and related doctor APIs. Primary “report review” for full charts may still be easier on the **web dashboard** (`/doctor/patients/...`).

### 9.4 MRI upload

1. Open **MRI upload**.  
2. Capture or pick an image.  
3. Submit to **`POST /api/mri/predict`**.  
4. Review label and confidence; record is kept in **History** when saved locally.

---

## 10. Permissions

Depending on platform and features:

- Camera  
- Photo library / gallery  
- Microphone  
- Speech recognition  

Grant these in system settings if prompted when using MRI capture, voice input, or TTS.

---

## 11. Basic workflow screenshots (placeholders)

Add files under `painpal/docs/screenshots/mobile/` and link them in exported docs.

| # | Suggested capture | File name (example) |
|---|-------------------|---------------------|
| 1 | Overview / welcome | `mobile-01-overview.png` |
| 2 | Log attack form (filled) | `mobile-02-migraine-log.png` |
| 3 | Result cards after submit (AI / type prediction) | `mobile-03-prediction-results.png` |
| 4 | Analytics charts | `mobile-04-analytics.png` |
| 5 | MRI upload + result | `mobile-05-mri-result.png` |
| 6 | Settings: API Base URL + Patient ID | `mobile-06-settings.png` |

Example:

```markdown
![Migraine log](screenshots/mobile/mobile-02-migraine-log.png)
```

---

## 12. Troubleshooting

| Issue | What to try |
|-------|-------------|
| “API base URL missing” | Open **Settings** and set the Next.js origin. |
| MRI upload fails | Confirm Next.js is reachable, JWT is valid if required, and image format is accepted. |
| Empty analytics | Log several attacks first; check date range filters. |
| Voice / TTS fails | Check OS permissions for mic and speech. |

---

## 13. Disclaimer

Painpal is intended for **education and self-tracking**, not as a medical device. Predictions and AI text are not diagnoses. Seek qualified care for emergencies and clinical decisions.
