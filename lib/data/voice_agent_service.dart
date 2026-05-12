import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Service for handling voice input and output
class VoiceAgentService {
  static const platform = MethodChannel('com.painpal.voice/channel');
  FlutterTts? _flutterTts;
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

  /// Avoid starting the Android TTS engine until [speak] runs (reduces emulator churn / log spam).
  Future<void> _ensureTts() async {
    if (_flutterTts != null) {
      return;
    }
    final tts = FlutterTts();
    await tts.setLanguage('en-US');
    await tts.setSpeechRate(0.85);
    await tts.setVolume(1.0);
    await tts.setPitch(1.0);
    _flutterTts = tts;
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
      // First initialize if needed
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

  /// Speak text using text-to-speech
  Future<void> speak(String text) async {
    await _ensureTts();
    final tts = _flutterTts!;
    if (_isSpeaking) {
      await tts.stop();
    }

    _isSpeaking = true;
    try {
      await tts.speak(text);
      _isSpeaking = false;
    } catch (e) {
      _isSpeaking = false;
      throw Exception('Failed to speak: $e');
    }
  }

  /// Stop speaking
  Future<void> stopSpeaking() async {
    if (_isSpeaking && _flutterTts != null) {
      await _flutterTts!.stop();
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
  Future<void> dispose() async {
    try {
      await stopListening();
      await stopSpeaking();
      if (_flutterTts != null) {
        await _flutterTts!.stop();
      }
      await platform.invokeMethod('dispose');
    } catch (e) {
      // Ignore errors during cleanup
    }
  }
}
