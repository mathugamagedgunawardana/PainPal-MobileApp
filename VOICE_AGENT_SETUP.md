# Gemini AI Voice Agent Integration Guide

This guide explains how to set up and use the Gemini AI assistant with voice capabilities in Painpal.

## Features

✅ **Floating Chat Button** - Chat icon in bottom right corner  
✅ **Gemini AI Assistant** - AI-powered responses for migraine support  
✅ **Voice Input** - Speak to your AI assistant using the microphone  
✅ **Voice Output** - AI responds with text-to-speech  
✅ **Persistent Chat History** - Track conversation history during session  
✅ **Beautiful UI** - Dark theme with green accent colors  

## Setup Instructions

### 1. Get Gemini API Key

1. Go to [Google AI Studio](https://aistudio.google.com/app/apikey)
2. Click "Get API Key"
3. Create a new API key for your project
4. Copy the key

### 2. Configure Gemini API Key

Edit your `.env` file and add your API key:

```env
GEMINI_API_KEY=AIzaSyDw25wBu-zmpAsnWxzjtfzTo2PB6tZ0IRU
```

### 3. Install Dependencies

The required dependencies are already in `pubspec.yaml`:

```yaml
# Google Generative AI (Gemini)
google_generative_ai: ^0.4.0

# Voice Agent - Speech to Text and Text to Speech
speech_to_text: ^6.6.2
flutter_tts: ^8.2.0

# Environment variables
flutter_dotenv: ^5.1.0
```

Run `flutter pub get` to install them:

```bash
flutter pub get
```

## Platform-Specific Setup

### Android Setup

Add the following permissions to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.INTERNET" />
```

### iOS Setup

Add the following to `ios/Runner/Info.plist`:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>This app requires microphone access to use the voice assistant</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>This app requires speech recognition access to use the voice assistant</string>
```

## Usage

### Basic Chat Usage

1. **Open Chat**: Click the green chat bubble icon in the bottom right
2. **Type Message**: Type your message and press send or hit Enter
3. **Voice Input**: Click the microphone icon to speak your question
4. **Voice Output**: Wait for Painpal AI to respond and speak the answer

### Chat Features

- **Text Input**: Type questions about migraines and pain management
- **Voice Input**: Click mic icon (will turn red when listening)
- **Voice Output**: Automatic text-to-speech responses
- **Chat History**: All messages during the session are saved
- **Clear Chat**: Restart conversation by closing and reopening the dialog

## API Reference

### GeminiAiService

```dart
final service = GeminiAiService();

// Send a message and get response
final response = await service.sendMessage("What are migraine triggers?");

// Get chat history
final history = service.getChatHistory();

// Clear conversation
service.clearChatHistory();

// Cleanup
service.dispose();
```

### VoiceAgentService

```dart
final service = VoiceAgentService();

// Initialize speech recognition
final initialized = await service.initializeSpeechToText();

// Start listening for voice input
await service.startListening();

// Stop listening
await service.stopListening();

// Speak text
await service.speak("Hello, how can I help?");

// Stop speaking
await service.stopSpeaking();

// Get transcribed text
String text = service.getLastWords();

// Check status
bool isListening = service.isListening;
bool isSpeaking = service.isSpeaking;

// Cleanup
service.dispose();
```

### Setting up Callbacks

```dart
final voiceService = VoiceAgentService();

// Callback when speech is recognized
voiceService.onSpeechResult = (recognizedWords) {
  print('User said: $recognizedWords');
};

// Callback when listening starts
voiceService.onListeningStart = () {
  print('Listening started');
};

// Callback when listening ends
voiceService.onListeningEnd = () {
  print('Listening ended');
};
```

## System Prompt

The AI assistant is configured with this system prompt:

```
You are Painpal AI, a helpful healthcare assistant specializing in migraine support 
and pain management. You provide compassionate, evidence-based information about:
- Migraine symptoms, triggers, and prevention
- Pain management techniques
- Medical information (always recommend consulting healthcare professionals)
- Emotional support for people with chronic pain

Always be empathetic, concise, and encourage professional consultation.
```

## Customization

### Change AI Model

Edit `lib/data/gemini_ai_service.dart`:

```dart
_model = GenerativeModel(
  model: 'gemini-1.5-pro', // Change model here
  apiKey: AiConfig.geminiApiKey,
  // ...
);
```

### Change Speech Language

Edit `lib/data/livekit_config.dart`:

```dart
static const String voiceLanguage = 'es-ES'; // Spanish
static const String ttsLanguage = 'es-ES';
```

Supported languages: `en-US`, `es-ES`, `fr-FR`, `de-DE`, `it-IT`, `ja-JP`, `zh-CN`, etc.

### Customize Chat UI

Edit `lib/widgets/chat_widget.dart` to change:
- Colors and styling
- Chat bubble appearance
- Input field design
- Message animations

### Adjust Voice Settings

Edit `lib/data/voice_agent_service.dart`:

```dart
void _initializeTextToSpeech() {
  _flutterTts = FlutterTts();
  _flutterTts.setLanguage('en-US');
  _flutterTts.setSpeechRate(0.85); // Speed (0.5-2.0)
  _flutterTts.setVolume(1.0);      // Volume (0.0-1.0)
  _flutterTts.setPitch(1.0);       // Pitch (0.5-2.0)
}
```

## Troubleshooting

### "Gemini API Key is not configured"

- Ensure `.env` file exists in the project root
- Verify `GEMINI_API_KEY` is set correctly
- Make sure `pubspec.yaml` includes `.env` in assets:
  ```yaml
  assets:
    - .env
  ```

### Microphone not working

1. Check permissions are granted on device
2. Verify `speech_to_text` is initialized:
   ```dart
   final initialized = await voiceService.initializeSpeechToText();
   ```
3. Check if device language is supported
4. Try restarting the app

### Text-to-speech not working

1. Verify device has audio output
2. Check system volume is not muted
3. Ensure `flutter_tts` is properly initialized
4. Check device TTS engine is installed

### Chat not responding

1. Check internet connection
2. Verify API key is valid
3. Check Gemini API quota in Google Cloud Console
4. Check Flutter console for error messages

## Dependencies

- `google_generative_ai: ^0.4.0` - Gemini AI API
- `speech_to_text: ^6.6.2` - Voice recognition
- `flutter_tts: ^8.2.0` - Text-to-speech
- `flutter_dotenv: ^5.1.0` - Environment variables
- `flutter` - Flutter SDK

## File Structure

```
lib/
├── data/
│   ├── gemini_ai_service.dart      # AI service
│   ├── voice_agent_service.dart    # Voice service
│   └── livekit_config.dart         # Configuration (AiConfig)
├── widgets/
│   └── chat_widget.dart            # Chat UI components
└── screens/
    ├── home_screen.dart            # Main screen with chat button
    └── ...
```

## Security Notes

⚠️ **Important**: Never commit API keys to version control. Always use:
- `.env` file (added to `.gitignore`)
- Never share your API key in code commits
- Use environment variables for sensitive data
- Regenerate keys if compromised

## Next Steps

1. ✅ Basic chat with Gemini AI
2. ✅ Voice input via speech-to-text
3. ✅ Voice output via text-to-speech
4. 🔄 Add chat history persistence to database
5. 🔄 Add voice recording and playback
6. 🔄 Add live agent handoff
7. 🔄 Add analytics and logging

## Support

For issues or questions:

1. Check the troubleshooting section above
2. Review [Google Generative AI documentation](https://ai.google.dev/)
3. Check [Speech to Text plugin](https://pub.dev/packages/speech_to_text)
4. Check [Flutter TTS plugin](https://pub.dev/packages/flutter_tts)
5. Verify all dependencies are properly installed

## Additional Resources

- [Google AI Studio](https://aistudio.google.com/)
- [Gemini API Documentation](https://ai.google.dev/docs)
- [Flutter Speech Recognition](https://pub.dev/packages/speech_to_text)
- [Flutter Text-to-Speech](https://pub.dev/packages/flutter_tts)

