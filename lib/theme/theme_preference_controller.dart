import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists light/dark choice under `@theme_preference` (parity with web AsyncStorage key).
class ThemePreferenceController extends ChangeNotifier {
  ThemePreferenceController();

  static const storageKey = '@theme_preference';

  ThemeMode _mode = ThemeMode.system;
  ThemeMode get themeMode => _mode;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(storageKey);
    if (v == 'light') {
      _mode = ThemeMode.light;
    } else if (v == 'dark') {
      _mode = ThemeMode.dark;
    } else {
      _mode = ThemeMode.system;
    }
    notifyListeners();
  }

  /// Sun/moon toggle: switches explicit light ↔ dark and saves.
  Future<void> toggleLightDark() async {
    final platformDark =
        WidgetsBinding.instance.platformDispatcher.platformBrightness ==
            Brightness.dark;
    final bool currentlyDark = _mode == ThemeMode.dark ||
        (_mode == ThemeMode.system && platformDark);
    final next = currentlyDark ? ThemeMode.light : ThemeMode.dark;
    _mode = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      storageKey,
      next == ThemeMode.light ? 'light' : 'dark',
    );
    notifyListeners();
  }
}
