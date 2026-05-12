import 'dart:convert';

import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../data/auth_service.dart';
import '../data/backend_config.dart';

/// Local daily medication reminders from the clinician schedule (GET /api/patient/medication-schedule).
/// True remote push (FCM) would require Firebase + server; this uses OS-scheduled local notifications.
class MedicationReminderService {
  MedicationReminderService._();
  static final MedicationReminderService instance = MedicationReminderService._();

  static const _prefsKey = 'medication_reminder_notification_ids';
  static const _channelId = 'medication_reminders';

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> _ensureInit() async {
    if (_initialized) return;

    tzdata.initializeTimeZones();
    try {
      final tzInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(tzInfo.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);

    await _plugin.initialize(settings: initSettings);

    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        'Medication reminders',
        description: 'Scheduled from your clinician’s prescription in PainPal',
        importance: Importance.defaultImportance,
      ),
    );

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await android?.requestNotificationsPermission();
    }

    _initialized = true;
  }

  Future<void> syncWithBackend(AuthService auth) async {
    if (!auth.isAuthenticated) return;
    await _ensureInit();

    final base = await auth.resolveApiBaseUrl();
    final uri = Uri.parse('$base${BackendConfig.patientMedicationScheduleEndpoint}');
    final res = await http.get(
      uri,
      headers: auth.getAuthHeaders(),
    ).timeout(BackendConfig.requestTimeout);

    if (res.statusCode != 200) return;

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final groups = (body['groups'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    final prefs = await SharedPreferences.getInstance();
    final oldIds = prefs.getStringList(_prefsKey) ?? [];
    for (final s in oldIds) {
      final id = int.tryParse(s);
      if (id != null) await _plugin.cancel(id: id);
    }

    final newIds = <String>[];
    final timeRe = RegExp(r'^(\d{1,2}):(\d{2})$');

    for (final g in groups) {
      final entries = (g['entries'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final groupName = g['groupName'] as String? ?? 'Medication';
      var i = 0;
      for (final e in entries) {
        final name = e['name'] as String? ?? '';
        final timeStr = (e['time'] as String?)?.trim() ?? '';
        final tablets = (e['tablets'] as num?)?.toInt() ?? 1;
        if (name.isEmpty || timeStr.isEmpty) continue;
        final m = timeRe.firstMatch(timeStr);
        if (m == null) continue;
        final hour = int.tryParse(m.group(1)!) ?? 9;
        final minute = int.tryParse(m.group(2)!) ?? 0;
        if (hour < 0 || hour > 23 || minute < 0 || minute > 59) continue;

        final id = _stableId(groupName, name, i);
        final now = tz.TZDateTime.now(tz.local);
        var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
        if (!scheduled.isAfter(now)) {
          scheduled = scheduled.add(const Duration(days: 1));
        }

        final androidDetails = AndroidNotificationDetails(
          _channelId,
          'Medication reminders',
          channelDescription: 'PainPal clinician schedule',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        );
        const iosDetails = DarwinNotificationDetails();
        final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

        await _plugin.zonedSchedule(
          id: id,
          scheduledDate: scheduled,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          title: 'Medication: $name',
          body: 'Take $tablets tablet(s) · $groupName',
          matchDateTimeComponents: DateTimeComponents.time,
        );
        newIds.add('$id');
        i++;
      }
    }

    await prefs.setStringList(_prefsKey, newIds);
  }

  static int _stableId(String groupName, String medName, int index) {
    return 20000 + (Object.hash(groupName, medName, index) & 0x7ffff);
  }
}
