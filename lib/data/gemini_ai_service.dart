import 'package:google_generative_ai/google_generative_ai.dart';
import 'livekit_config.dart';

/// Service for handling Gemini AI responses
class GeminiAiService {
  late GenerativeModel _model;
  late ChatSession _chatSession;
  bool _isInitialized = false;

  GeminiAiService() {
    _initializeModel();
  }

  void _initializeModel() {
    if (LiveKitConfig.geminiApiKey.isEmpty) {
      throw Exception('Gemini API Key is not configured');
    }

    _model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: LiveKitConfig.geminiApiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topP: 0.95,
        maxOutputTokens: 1024,
      ),
    );

    _chatSession = _model.startChat();
    _isInitialized = true;
  }

  /// Send a message to Gemini AI and get a response
  Future<String> sendMessage(String userMessage) async {
    if (!_isInitialized) {
      _initializeModel();
    }

    try {
      // Add system context to the message
      final systemContext =
          '''You are Painpal AI, a helpful healthcare assistant specializing in migraine support and pain management. 
You provide compassionate, evidence-based information about migraine symptoms, triggers, prevention, pain management techniques, and emotional support.
Always be empathetic, concise, and encourage professional consultation. If asked about something outside your domain, politely redirect to migraine and pain management.

User: $userMessage''';

      final response = await _chatSession.sendMessage(
        Content.text(systemContext),
      );

      final responseText = response.text;
      if (responseText == null || responseText.isEmpty) {
        return 'Sorry, I could not process your message. Please try again.';
      }

      return responseText;
    } catch (e) {
      return 'Error: ${e.toString()}. Please try again later.';
    }
  }

  /// Get chat history
  List<Content> getChatHistory() {
    return _chatSession.history.toList();
  }

  /// Clear chat history
  void clearChatHistory() {
    _chatSession = _model.startChat();
  }

  /// Dispose resources
  void dispose() {
    // Cleanup if needed
  }
}

