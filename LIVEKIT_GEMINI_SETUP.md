# LiveKit & Gemini AI Integration Guide

This guide explains how to set up and use the LiveKit voice/chat agent with Gemini AI integration in Painpal.

## Features

✅ **Floating Chat Button** - Chat icon in bottom right corner  
✅ **Gemini AI Assistant** - AI-powered responses for migraine support  
✅ **LiveKit Integration** - Real-time chat and voice capabilities (ready to configure)  
✅ **Persistent Chat History** - Track conversation history during session  
✅ **Beautiful UI** - Dark theme with green accent colors  

## Setup Instructions

### 1. Get Gemini API Key

1. Go to [Google AI Studio](https://aistudio.google.com/app/apikey)
2. Click "Get API Key"
3. Create a new API key for your project
4. Copy the key

### 2. Set Gemini API Key

You have two options to provide the Gemini API key:

#### Option A: Environment Variable (Recommended)
```bash
flutter run --dart-define=GEMINI_API_KEY=your_api_key_here
```

#### Option B: Direct Configuration
Edit `lib/data/livekit_config.dart`:
```dart
static const String geminiApiKey = 'your_api_key_here';
```

### 3. LiveKit Setup (Optional - For Voice/Video)

If you want to enable voice and video features:

1. **Self-hosted LiveKit:**
   - Follow [LiveKit deployment guide](https://docs.livekit.io/deploy/)
   - Get your server URL (e.g., `ws://your-server:7880`)

2. **LiveKit Cloud:**
   - Sign up at [livekit.io](https://livekit.io)
   - Get your server URL and API credentials

3. **Configure Environment Variables:**
```bash
flutter run \
  --dart-define=LIVEKIT_URL=ws://your-server:7880 \
  --dart-define=LIVEKIT_API_KEY=your_api_key \
  --dart-define=LIVEKIT_API_SECRET=your_api_secret \
  --dart-define=GEMINI_API_KEY=your_gemini_key
```

### 4. Token Generation (for LiveKit)

For production use with LiveKit, you need to implement token generation on your backend:

**Example Backend Implementation (Node.js/Express):**

```javascript
const { AccessToken } = require('livekit-server-sdk');

app.post('/api/livekit-token', (req, res) => {
  const { room, participantName } = req.body;
  
  const token = new AccessToken(
    process.env.LIVEKIT_API_KEY,
    process.env.LIVEKIT_API_SECRET
  );
  
  token.addGrant({
    room: room,
    roomJoin: true,
    canPublish: true,
    canPublishData: true,
    canSubscribe: true,
  });
  
  res.json({ token: token.toJwt() });
});
```

## Usage

### Basic Chat Usage

1. **Open Chat**: Click the green chat bubble icon in the bottom right
2. **Send Message**: Type your message and press send or hit Enter
3. **Get Response**: Wait for Painpal AI to respond

### Using Different Screens

- **Overview**: Introduction and quick start guide
- **Log Attack**: Record migraine details
- **MRI Upload**: Upload medical images
- **History**: View past migraines
- **Settings**: Configure preferences

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

### LiveKitService (Advanced)

```dart
final service = LiveKitService();

// Connect to room
await service.connectToRoom(
  roomName: 'support-session',
  participantName: 'Patient',
);

// Send chat message
await service.sendChatMessage("Hello, I need help");

// Toggle audio/video
await service.toggleMicrophone(true);
await service.toggleCamera(false);

// Disconnect
await service.disconnectFromRoom();
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
  apiKey: LiveKitConfig.geminiApiKey,
  // ...
);
```

### Customize System Prompt

Edit the `systemPrompt` parameter in the same file to change AI behavior.

### Modify Chat UI

Edit `lib/widgets/chat_widget.dart` to customize:
- Colors and styling
- Chat bubble appearance
- Input field design
- Message animations

## Troubleshooting

### "Gemini API Key is not configured"
- Make sure you've set the `GEMINI_API_KEY` environment variable
- Run: `flutter run --dart-define=GEMINI_API_KEY=your_key`

### Chat not responding
1. Check internet connection
2. Verify API key is valid
3. Check Flutter console for error messages
4. Ensure Gemini API is enabled in Google Cloud Console

### LiveKit Connection Issues
1. Verify server URL is correct
2. Check API key and secret
3. Ensure backend token generation is implemented
4. Check firewall/network settings

## Dependencies

- `livekit_client: ^0.7.0` - LiveKit integration
- `google_generative_ai: ^0.4.0` - Gemini AI API
- `flutter` - Flutter SDK
- `provider: ^6.1.0` - State management (optional)

## Next Steps

1. ✅ Basic chat with Gemini AI is working
2. 🔄 Implement backend token generation for LiveKit
3. 🔄 Add voice recording and streaming
4. 🔄 Add chat history persistence to database
5. 🔄 Implement live agent handoff

## Security Notes

⚠️ **Important**: Never commit API keys to version control. Always use:
- Environment variables
- Secure configuration files (not in repo)
- Backend token generation
- Flutter secure storage for sensitive data

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review Flutter and LiveKit documentation
3. Check API quotas and usage limits
4. Verify all dependencies are properly installed

