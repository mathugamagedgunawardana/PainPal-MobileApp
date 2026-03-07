import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Handles local notifications for migraine risk, medication reminder, and daily tracking.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const int idRiskAlert = 1;
  static const int idMedicationReminder = 2;
  static const int idDailyReminder = 3;

  Future<void> initialize() async {
    if (_initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
    );
    const initSettings = InitializationSettings(android: android, iOS: ios);
    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onSelect,
    );
    _initialized = true;
  }

  void _onSelect(NotificationResponse? response) {
    // Could navigate to a specific screen based on response?.payload
  }

  /// Request permissions (call after initialize).
  Future<bool> requestPermissions() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }
    final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      await iosPlugin.requestPermissions(alert: true, badge: true);
    }
    return true;
  }

  /// Show high migraine risk alert (e.g. when risk > 70%).
  Future<void> showRiskAlert() async {
    await initialize();
    const android = AndroidNotificationDetails(
      'migraine_risk',
      'Migraine Risk',
      channelDescription: 'High migraine risk alerts',
      importance: Importance.high,
      priority: Priority.high,
    );
    const ios = DarwinNotificationDetails();
    const details = NotificationDetails(android: android, iOS: ios);
    await _plugin.show(
      idRiskAlert,
      'High migraine risk today',
      'Consider hydration, rest, and avoiding triggers.',
      details,
    );
  }

  /// Show medication reminder.
  Future<void> showMedicationReminder() async {
    await initialize();
    const android = AndroidNotificationDetails(
      'medication_reminder',
      'Medication Reminder',
      channelDescription: 'Remind to take migraine medication',
      importance: Importance.defaultImportance,
    );
    const ios = DarwinNotificationDetails();
    const details = NotificationDetails(android: android, iOS: ios);
    await _plugin.show(
      idMedicationReminder,
      'Medication reminder',
      'Take your migraine medication.',
      details,
    );
  }

  /// Show daily tracking reminder.
  Future<void> showDailyReminder() async {
    await initialize();
    const android = AndroidNotificationDetails(
      'daily_tracking',
      'Daily Reminder',
      channelDescription: 'Remind to log migraine symptoms',
      importance: Importance.defaultImportance,
    );
    const ios = DarwinNotificationDetails();
    const details = NotificationDetails(android: android, iOS: ios);
    await _plugin.show(
      idDailyReminder,
      'Don\'t forget to log',
      'Log your migraine symptoms today.',
      details,
    );
  }

  /// Cancel all pending notifications.
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
