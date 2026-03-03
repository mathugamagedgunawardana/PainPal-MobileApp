/// LiveKit and Gemini API Configuration
class LiveKitConfig {
  /// Your LiveKit server URL (e.g., ws://localhost:7880 or wss://your-livekit-server.com)
  static const String liveKitUrl = String.fromEnvironment(
    'LIVEKIT_URL',
    defaultValue: 'ws://localhost:7880',
  );

  /// Your LiveKit API Key
  static const String liveKitApiKey = String.fromEnvironment(
    'LIVEKIT_API_KEY',
    defaultValue: '',
  );

  /// Your LiveKit API Secret
  static const String liveKitApiSecret = String.fromEnvironment(
    'LIVEKIT_API_SECRET',
    defaultValue: '',
  );

  /// Your Gemini API Key for AI responses
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  /// Room name for chat and voice sessions
  static const String defaultRoomName = 'painpal-chat-room';

  /// Participant display name
  static String participantName = 'Guest';

  /// Enable debug logging
  static const bool enableDebugLogging = true;
}

