import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../debug/agent_ndjson_log.dart';

/// Single shared Text-to-Speech pipeline: safe init ordering, explicit [Voice],
/// queued [speak], and emulator/device-safe fallbacks.
///
/// Android: `flutter_tts` may log `getDefaultLocale` when [TextToSpeech.defaultVoice]
/// is null at init; we avoid relying on default voice by selecting a concrete voice
/// from [FlutterTts.getVoices] before [speak].
final class PainpalTtsService {
  PainpalTtsService._();
  static final PainpalTtsService instance = PainpalTtsService._();

  FlutterTts? _tts;
  Future<void>? _initFuture;
  Future<void> _speakChain = Future<void>.value();
  bool _initialized = false;
  String? _lastInitError;

  String? get lastInitError => _lastInitError;

  /// Await before any [speak]. Idempotent; clears and retries after a failed init.
  Future<void> ensureInitialized() {
    // #region agent log
    unawaited(
      agentNdjsonLog(
        hypothesisId: 'H1',
        location: 'painpal_tts_service.dart:ensureInitialized',
        message: 'ensure_called',
        data: {'hasFuture': _initFuture != null, 'inited': _initialized},
      ),
    );
    // #endregion
    if (_initFuture != null) {
      return _initFuture!;
    }
    final c = Completer<void>();
    _initFuture = c.future;
    _runInitCompleter(c);
    return _initFuture!;
  }

  Future<void> _runInitCompleter(Completer<void> c) async {
    try {
      await _initializeInternal();
      c.complete();
    } catch (e, st) {
      _initFuture = null;
      if (!c.isCompleted) {
        c.completeError(e, st);
      }
    }
  }

  Future<void> _initializeInternal() async {
    _lastInitError = null;
    final tts = FlutterTts();
    _tts = tts;

    // #region agent log
    await agentNdjsonLog(
      hypothesisId: 'H1',
      location: 'painpal_tts_service.dart:_initializeInternal',
      message: 'tts_instance_created',
      data: {'platform': Platform.operatingSystem},
    );
    // #endregion

    tts.setErrorHandler((dynamic msg) {
      // #region agent log
      unawaited(
        agentNdjsonLog(
          hypothesisId: 'H4',
          location: 'painpal_tts_service.dart:setErrorHandler',
          message: 'engine_error',
          data: {'detail': msg.toString()},
        ),
      );
      // #endregion
      if (kDebugMode) {
        debugPrint('PainpalTtsService: $msg');
      }
    });

    try {
      if (Platform.isAndroid) {
        await tts.awaitSpeakCompletion(true);
      }
      if (!kIsWeb && Platform.isIOS) {
        await tts.setSharedInstance(true);
      }

      var voices = await _pollVoices(tts);
      // #region agent log
      await agentNdjsonLog(
        hypothesisId: 'H2',
        location: 'painpal_tts_service.dart:_initializeInternal',
        message: 'voices_after_poll',
        data: {'count': voices.length},
      );
      // #endregion

      if (voices.isEmpty && Platform.isAndroid) {
        final switched = await _trySwitchToGoogleEngine(tts);
        // #region agent log
        await agentNdjsonLog(
          hypothesisId: 'H2',
          location: 'painpal_tts_service.dart:_initializeInternal',
          message: 'post_engine_switch',
          data: {'switched': switched},
        );
        // #endregion
        if (switched) {
          voices = await _pollVoices(tts);
        }
      }

      await _applyLanguageAndVoice(tts, voices);

      await tts.setSpeechRate(0.85);
      await tts.setVolume(1.0);
      await tts.setPitch(1.0);

      _initialized = true;
      // #region agent log
      await agentNdjsonLog(
        hypothesisId: 'H1',
        location: 'painpal_tts_service.dart:_initializeInternal',
        message: 'init_ok',
        data: {'voiceReady': voices.isNotEmpty},
      );
      // #endregion
    } catch (e, st) {
      _lastInitError = e.toString();
      _initialized = false;
      // #region agent log
      await agentNdjsonLog(
        hypothesisId: 'H3',
        location: 'painpal_tts_service.dart:_initializeInternal',
        message: 'init_failed',
        data: {'error': e.toString(), 'st': st.toString()},
      );
      // #endregion
      rethrow;
    }
  }

  static Future<List<Map<String, String>>> _pollVoices(FlutterTts tts) async {
    const maxAttempts = 24;
    for (var i = 0; i < maxAttempts; i++) {
      final parsed = _parseVoices(await tts.getVoices);
      if (parsed.isNotEmpty) {
        return parsed;
      }
      await Future<void>.delayed(Duration(milliseconds: i < 8 ? 40 : 80));
    }
    return const [];
  }

  static List<Map<String, String>> _parseVoices(dynamic raw) {
    if (raw == null) return const [];
    if (raw is! List<dynamic>) return const [];
    final out = <Map<String, String>>[];
    for (final e in raw) {
      if (e is Map) {
        final m = <String, String>{};
        e.forEach((k, v) {
          m[k.toString()] = v?.toString() ?? '';
        });
        if ((m['name'] ?? '').isNotEmpty) {
          out.add(m);
        }
      }
    }
    return out;
  }

  static bool _truthy(dynamic v) =>
      v == true || v == 1 || v == '1' || v == 'true';

  static Future<bool> _trySwitchToGoogleEngine(FlutterTts tts) async {
    try {
      final engines = await tts.getEngines;
      if (engines is! List) return false;
      final names = engines.map((e) => e.toString()).toList();
      const google = 'com.google.android.tts';
      if (!names.contains(google)) {
        return false;
      }
      await tts.setEngine(google);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _applyLanguageAndVoice(
    FlutterTts tts,
    List<Map<String, String>> voices,
  ) async {
    const candidates = <String>[
      'en-US',
      'en_US',
      'en-GB',
      'en_GB',
      'en-AU',
      'en',
    ];

    for (final tag in candidates) {
      try {
        final ok = await tts.isLanguageAvailable(tag);
        if (_truthy(ok)) {
          await tts.setLanguage(tag);
          break;
        }
      } catch (_) {}
    }

    if (voices.isEmpty) {
      return;
    }

    Map<String, String>? pickLocal(List<Map<String, String>> vs) {
      Map<String, String>? firstEn;
      for (final v in vs) {
        final net = v['network_required'] == '1';
        final loc = (v['locale'] ?? '').toLowerCase();
        if (loc.startsWith('en') && !net) {
          return v;
        }
        if (firstEn == null && loc.startsWith('en')) {
          firstEn = v;
        }
      }
      return firstEn ?? vs.first;
    }

    final voice = pickLocal(voices);
    if (voice == null) {
      return;
    }
    final name = voice['name'] ?? '';
    final locale = voice['locale'] ?? '';
    if (name.isEmpty || locale.isEmpty) {
      return;
    }
    try {
      await tts.setVoice({'name': name, 'locale': locale});
    } catch (_) {}
  }

  /// Speaks [text] after initialization. Serialized so [speak] is never concurrent.
  Future<void> speak(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return;
    }
    final completer = Completer<void>();
    final previous = _speakChain;
    _speakChain = completer.future;
    await previous;
    try {
      await ensureInitialized();
      final tts = _tts;
      if (tts == null || !_initialized) {
        throw StateError('TTS not initialized: $_lastInitError');
      }
      // #region agent log
      await agentNdjsonLog(
        hypothesisId: 'H3',
        location: 'painpal_tts_service.dart:speak',
        message: 'speak_start',
        data: {'len': trimmed.length},
      );
      // #endregion
      await tts.stop();
      final result = await tts.speak(trimmed);
      if (result != 1 && result != true && result != 0) {
        if (kDebugMode) {
          debugPrint('PainpalTtsService: speak returned $result');
        }
      }
      // #region agent log
      await agentNdjsonLog(
        hypothesisId: 'H3',
        location: 'painpal_tts_service.dart:speak',
        message: 'speak_end',
        data: {'result': result.toString()},
      );
      // #endregion
    } catch (e, st) {
      // #region agent log
      await agentNdjsonLog(
        hypothesisId: 'H3',
        location: 'painpal_tts_service.dart:speak',
        message: 'speak_error',
        data: {'error': e.toString(), 'st': st.toString()},
      );
      // #endregion
      rethrow;
    } finally {
      completer.complete();
    }
  }

  Future<void> stop() async {
    try {
      await _tts?.stop();
    } catch (_) {}
  }

  /// Hard reset (e.g. after engine failure). Next [ensureInitialized] rebuilds engine.
  Future<void> reset() async {
    await stop();
    _initFuture = null;
    _initialized = false;
    _tts = null;
    _lastInitError = null;
  }
}
