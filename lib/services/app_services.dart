import '../data/auth_service.dart';
import '../theme/theme_preference_controller.dart';
import 'attack_timer_service.dart';

/// Global services initialized in [main] before [runApp].
class AppServices {
  AppServices._();

  static final AuthService auth = AuthService();
  static final AttackTimerService attackTimer = AttackTimerService();
  static final ThemePreferenceController theme = ThemePreferenceController();

  static Future<void> init() async {
    await auth.initialize();
    await theme.load();
  }
}
