# Mobile Setup

## Prerequisites

| Tool | Version |
|------|---------|
| Flutter | 3.11+ |
| Dart | 3.11+ |
| PainPal-Web API | Running locally or deployed |

Install Flutter: https://docs.flutter.dev/get-started/install

## 1. Clone and configure

```bash
git clone https://github.com/YOUR_ORG/PainPal-MobileApp.git
cd PainPal-MobileApp
cp .env.example .env
```

Edit `.env`:

```env
GEMINI_API_KEY=your_key_from_aistudio
API_BASE_URL=http://127.0.0.1:3000
```

## 2. Start the backend

From [PainPal-Web](https://github.com/YOUR_ORG/PainPal-Web):

```bash
docker compose up -d mongo
cd client && npm install && npx prisma db seed && npm run dev
```

Optional model service:

```bash
cd model && python main.py
```

## 3. Run the app

```bash
flutter pub get
flutter run
```

## Platform-Specific API URLs

| Target | `API_BASE_URL` |
|--------|----------------|
| iOS Simulator | `http://127.0.0.1:3000` |
| Android Emulator | `http://10.0.2.2:3000` |
| Physical device | `http://<your-lan-ip>:3000` |

The app also reads API URL from **Settings** (SharedPreferences), which overrides `.env` at runtime.

## Permissions

| Permission | Feature |
|------------|---------|
| Camera | MRI photo capture |
| Photos | Gallery MRI selection |
| Microphone | Voice chat input |
| Notifications | Medication reminders |

## Demo Accounts (development API only)

When PainPal-Web runs in development mode:

- Patient: `patient@painpal.com` / `Patient@123`
- Doctor: `doctor@painpal.com` / `Doctor@123`

## Build Release

```bash
flutter build apk --release
flutter build ios --release   # macOS + Xcode required
```

## Troubleshooting

| Problem | Fix |
|---------|-----|
| App crashes on start | Ensure `.env` exists (bundled as asset) |
| Network error on login | Check API URL and backend is running |
| Voice chat silent | Grant microphone permission |
| Empty analytics | Log attacks or sync from server |

More: [PainPal-Web FAQ](https://github.com/YOUR_ORG/PainPal-Web/blob/main/docs/faq.md)
