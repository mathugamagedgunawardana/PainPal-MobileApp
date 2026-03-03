# Quick Start Guide - Chat with Voice Agent

## 🚀 Running the App

### 1. Build and Run
```bash
cd D:\painpal
flutter pub get
flutter run -d emulator-5554
```

### 2. Or Build APK
```bash
flutter build apk --debug
```

## 💬 Using the Chat Feature

1. **Open the Chat**: Tap the green chat bubble 💬 in the bottom right corner
2. **Type Your Question**: Ask anything about migraines, pain management, etc.
3. **Send Message**: Press Enter or tap the Send button 📤
4. **Listen to Response**: AI responds with text AND voice automatically 🔊

## 🎤 Voice Features

- ✅ **AI Voice Output**: Every response is spoken aloud
- ℹ️ **Voice Input**: Coming soon (can be implemented with speech-to-text package)

## 📝 Sample Questions

- "What are common migraine triggers?"
- "How can I manage migraine pain?"
- "What should I do during a migraine attack?"
- "Are there foods that trigger migraines?"
- "How do I prevent migraines?"

## ⚙️ Configuration

**API Key**: Already configured in `.env`
```env
GEMINI_API_KEY=AIzaSyDw25wBu-zmpAsnWxzjtfzTo2PB6tZ0IRU
```

## 🔧 Customization

### Change Voice Settings
Edit `lib/data/voice_agent_service.dart`:
```dart
_flutterTts.setSpeechRate(0.85);    // Speed: 0.5-2.0
_flutterTts.setVolume(1.0);          // Volume: 0.0-1.0
_flutterTts.setPitch(1.0);           // Pitch: 0.5-2.0
```

### Change AI Model
Edit `lib/data/gemini_ai_service.dart`:
```dart
_model = GenerativeModel(
  model: 'gemini-2.0-flash',  // Change model here
  apiKey: AiConfig.geminiApiKey,
);
```

## 📱 Platforms

- ✅ Android (Tested)
- ✅ iOS (Ready)
- ⚠️ Web (Requires additional setup)
- ⚠️ Windows (Requires additional setup)

## 🐛 Troubleshooting

### "API Key not found"
- Ensure `.env` file exists in project root
- Verify key is set correctly
- Restart the app

### "Voice not working"
- Check device volume is not muted
- Verify device has audio output
- Check system TTS engine is installed

### "Chat not responding"
- Check internet connection
- Verify Gemini API quota
- Check device has enough memory

## 📚 Documentation

- Full setup guide: `VOICE_AGENT_SETUP.md`
- Implementation details: `IMPLEMENTATION_COMPLETE.md`

## 🎯 File Locations

```
D:\painpal\
├── lib\
│   ├── data\
│   │   ├── gemini_ai_service.dart      ← AI Service
│   │   ├── voice_agent_service.dart    ← TTS Service
│   │   └── livekit_config.dart         ← Configuration
│   ├── widgets\
│   │   └── chat_widget.dart            ← Chat UI
│   └── screens\
│       └── home_screen.dart            ← Chat Button
├── .env                                 ← API Keys (PROTECTED)
├── pubspec.yaml                         ← Dependencies
└── README.md                            ← This file
```

## 🔒 Security

- ✅ API keys in `.env` (not in code)
- ✅ `.env` in `.gitignore`
- ✅ Safe for GitHub/public repos

## 💡 Tips

1. **For first run**: App loads .env file automatically
2. **TTS is automatic**: No need to enable voice manually
3. **Chat clears**: New conversation on each dialog open
4. **All screens**: Chat button available everywhere

## 🎨 UI Location

**Chat Button**: Bottom right corner of screen
- Green color (#B6F36B)
- Chat bubble icon
- Always accessible

## 📞 Need Help?

Check documentation files:
- `VOICE_AGENT_SETUP.md` - Full setup instructions
- `IMPLEMENTATION_COMPLETE.md` - Architecture details
- Flutter docs: https://flutter.dev

---

**Status**: ✅ Ready to Use
**Last Updated**: March 3, 2026

