import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Service for handling voice input and output
class VoiceAgentService {
  late stt.SpeechToText _speechToText;
  late FlutterTts _flutterTts;
  bool _isListening = false;
  bool _isSpeaking = false;
  String _lastWords = '';

  /// Callback for when speech is recognized
  Function(String)? onSpeechResult;

  /// Callback for when listening starts
  Function()? onListeningStart;

  /// Callback for when listening ends
  Function()? onListeningEnd;

  VoiceAgentService() {
    _initializeSpeechToText();
    _initializeTextToSpeech();
  }

  void _initializeSpeechToText() {
    _speechToText = stt.SpeechToText();
  }

  void _initializeTextToSpeech() {
    _flutterTts = FlutterTts();
    _flutterTts.setLanguage('en-US');
    _flutterTts.setSpeechRate(0.85);
    _flutterTts.setVolume(1.0);
    _flutterTts.setPitch(1.0);
  }

  /// Initialize speech to text
  Future<bool> initializeSpeechToText() async {
    try {
      final available = await _speechToText.initialize(
        onError: (error) {
          _isListening = false;
          onListeningEnd?.call();
        },
        onStatus: (status) {
          if (status == 'notListening') {
            _isListening = false;
            onListeningEnd?.call();
          }
        },
      );
      return available;
    } catch (e) {
      return false;
    }
  }

  /// Start listening for speech
  Future<void> startListening() async {
    if (!_speechToText.isAvailable) {
      final initialized = await initializeSpeechToText();
      if (!initialized) {
        throw Exception('Speech to text not available');
      }
    }

    if (!_isListening) {
      _isListening = true;
      onListeningStart?.call();

      await _speechToText.listen(
        onResult: (result) {
          _lastWords = result.recognizedWords;
          if (result.finalResult) {
            _isListening = false;
            onListeningEnd?.call();
            onSpeechResult?.call(_lastWords);
          }
        },
        localeId: 'en_US',
      );
    }
  }

  /// Stop listening for speech
  Future<void> stopListening() async {
    if (_isListening) {
      await _speechToText.stop();
      _isListening = false;
      onListeningEnd?.call();
    }
  }

  /// Speak text using text-to-speech
  Future<void> speak(String text) async {
    if (_isSpeaking) {
      await _flutterTts.stop();
    }

    _isSpeaking = true;
    try {
      await _flutterTts.speak(text);
    } catch (e) {
      throw Exception('Failed to speak: $e');
    } finally {
      _isSpeaking = false;
    }
  }

  /// Stop speaking
  Future<void> stopSpeaking() async {
    if (_isSpeaking) {
      await _flutterTts.stop();
      _isSpeaking = false;
    }
  }

  /// Get last recognized words
  String getLastWords() => _lastWords;

  /// Check if currently listening
  bool get isListening => _isListening;

  /// Check if currently speaking
  bool get isSpeaking => _isSpeaking;

  /// Dispose resources
  void dispose() async {
    await stopListening();
    await stopSpeaking();
    await _flutterTts.stop();
  }
}

