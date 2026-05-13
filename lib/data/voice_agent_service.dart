import 'package:flutter/services.dart';

import '../services/painpal_tts_service.dart';

/// Voice input (platform channel) + Text-to-speech via [PainpalTtsService].
///
/// TTS is never created here: [PainpalTtsService] owns [FlutterTts], init order,
/// voice selection, and serialized [speak].
class VoiceAgentService {
  static const platform = MethodChannel('com.painpal.voice/channel');

  bool _isListening = false;
  bool _isSpeaking = false;
  String _lastWords = '';

  /// Callback for when speech is recognized
  Function(String)? onSpeechResult;

  /// Callback for when listening starts
  Function()? onListeningStart;

  /// Callback for when listening ends
  Function()? onListeningEnd;

  /// Callback for errors
  Function(String)? onError;

  VoiceAgentService() {
    _setupMethodChannel();
  }

  void _setupMethodChannel() {
    platform.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onSpeechResult':
          _lastWords = call.arguments as String;
          _isListening = false;
          onListeningEnd?.call();
          onSpeechResult?.call(_lastWords);
          break;
        case 'onListeningStart':
          _isListening = true;
          onListeningStart?.call();
          break;
        case 'onListeningEnd':
          _isListening = false;
          onListeningEnd?.call();
          break;
        case 'onError':
          final error = call.arguments as String;
          onError?.call(error);
          break;
      }
    });
  }

  /// Initialize speech to text
  Future<bool> initializeSpeechToText() async {
    try {
      final result = await platform.invokeMethod<bool>('initializeSpeech');
      return result ?? false;
    } catch (e) {
      onError?.call('Failed to initialize speech: $e');
      return false;
    }
  }

  /// Start listening for speech
  Future<void> startListening() async {
    try {
      final initialized = await initializeSpeechToText();
      if (!initialized) {
        throw Exception('Speech recognition not available');
      }

      _isListening = true;
      onListeningStart?.call();

      await platform.invokeMethod('startListening', {
        'language': 'en_US',
      });
    } catch (e) {
      _isListening = false;
      onListeningEnd?.call();
      onError?.call(e.toString());
    }
  }

  /// Stop listening for speech
  Future<void> stopListening() async {
    try {
      if (_isListening) {
        await platform.invokeMethod('stopListening');
        _isListening = false;
        onListeningEnd?.call();
      }
    } catch (e) {
      onError?.call(e.toString());
    }
  }

  /// Speak text using shared TTS (never call before [PainpalTtsService] init completes).
  Future<void> speak(String text) async {
    if (_isSpeaking) {
      await PainpalTtsService.instance.stop();
    }
    _isSpeaking = true;
    try {
      await PainpalTtsService.instance.speak(text);
    } catch (e) {
      throw Exception('Failed to speak: $e');
    } finally {
      _isSpeaking = false;
    }
  }

  /// Stop speaking
  Future<void> stopSpeaking() async {
    await PainpalTtsService.instance.stop();
    _isSpeaking = false;
  }

  /// Get last recognized words
  String getLastWords() => _lastWords;

  /// Check if currently listening
  bool get isListening => _isListening;

  /// Check if currently speaking
  bool get isSpeaking => _isSpeaking;

  /// Dispose resources
  Future<void> dispose() async {
    try {
      await stopListening();
      await stopSpeaking();
      await platform.invokeMethod('dispose');
    } catch (e) {
      // Ignore errors during cleanup
    }
  }
}
