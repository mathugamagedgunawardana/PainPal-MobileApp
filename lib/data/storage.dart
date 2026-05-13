import 'package:shared_preferences/shared_preferences.dart';

class SettingsStorage {
  static const _baseUrlKey = 'base_url';
  static const _patientIdKey = 'patient_id';
  static const _draftAttackKey = 'draft_attack';
  static const _chatDoctorProfileIdKey = 'chat_doctor_profile_id';

  /// Local medication reminder notifications (see [MedicationReminderService]).
  static const medicationRemindersEnabledKey = 'pref_medication_reminders_enabled';

  /// When false, the Gemini assistant receives only a short privacy notice, not logs/MRI/analytics.
  static const aiUseHealthDataKey = 'pref_ai_use_health_data';

  Future<bool> readMedicationRemindersEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(medicationRemindersEnabledKey) ?? true;
  }

  Future<void> saveMedicationRemindersEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(medicationRemindersEnabledKey, value);
  }

  Future<bool> readAiUseHealthData() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(aiUseHealthDataKey) ?? true;
  }

  Future<void> saveAiUseHealthData(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(aiUseHealthDataKey, value);
  }

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

  /// Optional [DoctorProfile.id] (Mongo ObjectId) for starting clinic chat when no conversation exists yet.
  Future<void> saveChatDoctorProfileId(String value) async {
    final prefs = await SharedPreferences.getInstance();
    final v = value.trim();
    if (v.isEmpty) {
      await prefs.remove(_chatDoctorProfileIdKey);
    } else {
      await prefs.setString(_chatDoctorProfileIdKey, v);
    }
  }

  Future<String?> readChatDoctorProfileId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_chatDoctorProfileIdKey);
  }
}

