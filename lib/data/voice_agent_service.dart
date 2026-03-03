import 'package:flutter_tts/flutter_tts.dart';

/// Service for handling voice output (text-to-speech)
/// For voice input, users can type or use device's built-in voice input
class VoiceAgentService {
  late FlutterTts _flutterTts;
  bool _isSpeaking = false;

  /// Callback for when speech is recognized (for future voice input)
  Function(String)? onSpeechResult;

  VoiceAgentService() {
    _initializeTextToSpeech();
  }

  void _initializeTextToSpeech() {
    _flutterTts = FlutterTts();
    _flutterTts.setLanguage('en-US');
    _flutterTts.setSpeechRate(0.85);
    _flutterTts.setVolume(1.0);
    _flutterTts.setPitch(1.0);
  }

  /// Speak text using text-to-speech
  Future<void> speak(String text) async {
    if (_isSpeaking) {
      await _flutterTts.stop();
    }

    _isSpeaking = true;
    try {
      await _flutterTts.speak(text);
      _isSpeaking = false;
    } catch (e) {
      _isSpeaking = false;
      throw Exception('Failed to speak: $e');
    }
  }

  /// Stop speaking
  Future<void> stopSpeaking() async {
    if (_isSpeaking) {
      await _flutterTts.stop();
      _isSpeaking = false;
    }
  }

  /// Check if currently speaking
  bool get isSpeaking => _isSpeaking;

  /// Dispose resources
  Future<void> dispose() async {
    await stopSpeaking();
    await _flutterTts.stop();
  }

  /// Stub methods for voice input (can be implemented later with a different package)
  Future<void> startListening() async {
    // Voice input can be added later with a more compatible package
    throw UnimplementedError('Voice input to be implemented');
  }

  Future<void> stopListening() async {
    // Voice input can be added later
  }

  bool get isListening => false;
}

