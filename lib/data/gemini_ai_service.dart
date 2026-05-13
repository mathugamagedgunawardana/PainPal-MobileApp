import 'package:google_generative_ai/google_generative_ai.dart';
import 'livekit_config.dart';

/// Service for handling Gemini AI responses with optional patient-specific context.
class GeminiAiService {
  late GenerativeModel _model;
  late ChatSession _chatSession;
  bool _isInitialized = false;

  GeminiAiService({String? patientContext}) {
    _initializeModel(patientContext: patientContext);
  }

  static String _systemPrompt({String? patientContext}) {
    final buf = StringBuffer();
    buf.writeln(
      'You are Painpal AI, a supportive assistant focused on migraine education, '
      'self-management, triggers, lifestyle factors, and general pain-coping strategies. '
      'Be empathetic, concise, and never replace a clinician. '
      'If asked for a diagnosis or treatment plan, encourage consulting a qualified healthcare professional.',
    );

    if (patientContext != null && patientContext.trim().isNotEmpty) {
      buf.writeln();
      buf.writeln(
        'The following block was loaded from this patient\'s app database and clinic APIs '
        '(recent attacks, MRI summaries on device, and optional analytics). '
        'When the user asks about their own data, rely on this block and the conversation. '
        'Do not invent clinical facts that are not supported by the block or the chat. '
        'If something is missing, say you do not see it in their records.',
      );
      buf.writeln();
      buf.writeln('--- Patient record summary ---');
      buf.writeln(patientContext.trim());
      buf.writeln('--- End summary ---');
    }

    return buf.toString();
  }

  void _initializeModel({String? patientContext}) {
    if (AiConfig.geminiApiKey.isEmpty) {
      throw Exception('Gemini API Key is not configured');
    }

    _model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: AiConfig.geminiApiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topP: 0.95,
        maxOutputTokens: 1024,
      ),
      systemInstruction: Content.system(_systemPrompt(patientContext: patientContext)),
    );

    _chatSession = _model.startChat();
    _isInitialized = true;
  }

  /// Send a user message (system + patient context are already configured on the model).
  Future<String> sendMessage(String userMessage) async {
    if (!_isInitialized) {
      _initializeModel(patientContext: null);
    }

    try {
      final response = await _chatSession.sendMessage(
        Content.text(userMessage),
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

  List<Content> getChatHistory() {
    return _chatSession.history.toList();
  }

  void clearChatHistory() {
    _chatSession = _model.startChat();
  }

  void dispose() {}
}
