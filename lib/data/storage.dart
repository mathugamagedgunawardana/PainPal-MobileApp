import 'package:shared_preferences/shared_preferences.dart';

class SettingsStorage {
  static const _baseUrlKey = 'base_url';
  static const _patientIdKey = 'patient_id';
  static const _draftAttackKey = 'draft_attack';
  static const _chatDoctorProfileIdKey = 'chat_doctor_profile_id';

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

