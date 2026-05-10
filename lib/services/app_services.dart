import '../data/auth_service.dart';

/// Global services initialized in [main] before [runApp].
class AppServices {
  AppServices._();

  static final AuthService auth = AuthService();

  static Future<void> init() => auth.initialize();
}
