import '../data/auth_service.dart';
import '../data/database.dart';
import 'attack_timer_service.dart';

/// Global services initialized in [main] before [runApp].
class AppServices {
  AppServices._();

  static final AuthService auth = AuthService();
  static final AttackTimerService attackTimer = AttackTimerService();

  static Future<void> init() async {
    await auth.initialize();
    await PainpalDatabase.instance.clearMigraineAttacks();
  }
}
