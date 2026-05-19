import 'dart:async';

import 'package:flutter/foundation.dart';

/// Shared attack timer: started from Home FAB or overview, shown on Home tab.
class AttackTimerService extends ChangeNotifier {
  DateTime? _startedAt;
  Timer? _ticker;

  DateTime? get startedAt => _startedAt;

  bool get isRunning => _startedAt != null;

  Duration get elapsed =>
      _startedAt == null ? Duration.zero : DateTime.now().difference(_startedAt!);

  static String formatElapsed(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) {
      return '${h}h ${m.toString().padLeft(2, '0')}m ${s.toString().padLeft(2, '0')}s';
    }
    return '${m}m ${s.toString().padLeft(2, '0')}s';
  }

  void start() {
    if (_startedAt != null) {
      return;
    }
    _startedAt = DateTime.now();
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => notifyListeners());
    notifyListeners();
  }

  void cancel() {
    _ticker?.cancel();
    _ticker = null;
    _startedAt = null;
    notifyListeners();
  }

  /// Clears the timer and returns values for [MigraineFormScreen], or null if idle.
  ({DateTime startedAt, int durationHours})? consumeStopForLog() {
    final s = _startedAt;
    if (s == null) {
      return null;
    }
    final elapsed = DateTime.now().difference(s);
    _ticker?.cancel();
    _ticker = null;
    _startedAt = null;
    notifyListeners();

    final sec = elapsed.inSeconds;
    var hours = sec <= 0 ? 1 : (sec / 3600).ceil();
    if (hours < 1) {
      hours = 1;
    }
    if (hours > 168) {
      hours = 168;
    }
    return (startedAt: s, durationHours: hours);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
