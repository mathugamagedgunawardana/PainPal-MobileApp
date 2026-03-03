import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Gemini AI and Voice Agent Configuration
class AiConfig {
  /// Your Gemini API Key for AI responses
  static String get geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  /// Enable debug logging
  static const bool enableDebugLogging = true;

  /// Voice agent settings
  static const String voiceLanguage = 'en-US';
  static const String ttsLanguage = 'en-US';
}

