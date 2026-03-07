import 'package:shared_preferences/shared_preferences.dart';

class SettingsStorage {
  static const _baseUrlKey = 'base_url';
  static const _patientIdKey = 'patient_id';
  static const _draftAttackKey = 'draft_attack';
  static const _notificationsRiskKey = 'notifications_risk';
  static const _notificationsMedicationKey = 'notifications_medication';
  static const _notificationsDailyKey = 'notifications_daily';
  static const _quickAttackStartKey = 'quick_attack_start';
  static const _quickAttackIntensityKey = 'quick_attack_intensity';

  Future<void> saveBaseUrl(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, value.trim());
  }

  Future<String?> readBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_baseUrlKey);
  }

  Future<void> savePatientId(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_patientIdKey, value.trim());
  }

  Future<String?> readPatientId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_patientIdKey);
  }

  Future<void> saveDraftAttack(String json) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_draftAttackKey, json);
  }

  Future<String?> readDraftAttack() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_draftAttackKey);
  }

  Future<void> clearDraftAttack() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftAttackKey);
  }

  Future<void> setNotificationsRisk(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsRiskKey, value);
  }

  Future<bool> getNotificationsRisk() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsRiskKey) ?? true;
  }

  Future<void> setNotificationsMedication(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsMedicationKey, value);
  }

  Future<bool> getNotificationsMedication() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsMedicationKey) ?? true;
  }

  Future<void> setNotificationsDaily(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsDailyKey, value);
  }

  Future<bool> getNotificationsDaily() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsDailyKey) ?? true;
  }

  Future<void> setQuickAttackStart(String? isoDate) async {
    final prefs = await SharedPreferences.getInstance();
    if (isoDate == null) {
      await prefs.remove(_quickAttackStartKey);
    } else {
      await prefs.setString(_quickAttackStartKey, isoDate);
    }
  }

  Future<String?> getQuickAttackStart() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_quickAttackStartKey);
  }

  Future<void> setQuickAttackIntensity(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_quickAttackIntensityKey, value);
  }

  Future<int> getQuickAttackIntensity() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_quickAttackIntensityKey) ?? 5;
  }
}

