import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Name + phone for Quick Access emergency calls (stored locally).
class EmergencyContactEntry {
  EmergencyContactEntry({required this.name, required this.phone});

  final String name;
  final String phone;

  Map<String, dynamic> toJson() => {'name': name, 'phone': phone};

  static EmergencyContactEntry fromJson(Map<String, dynamic> json) {
    return EmergencyContactEntry(
      name: (json['name'] as String?)?.trim() ?? '',
      phone: (json['phone'] as String?)?.trim() ?? '',
    );
  }
}

class SettingsStorage {
  static const _baseUrlKey = 'base_url';
  static const _patientIdKey = 'patient_id';
  static const _draftAttackKey = 'draft_attack';
  static const _chatDoctorProfileIdKey = 'chat_doctor_profile_id';
  static const _emergencyContactsKey = 'emergency_contacts_v1';

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

  Future<List<EmergencyContactEntry>> readEmergencyContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_emergencyContactsKey);
    if (raw == null || raw.trim().isEmpty) {
      return [];
    }
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => EmergencyContactEntry.fromJson(e as Map<String, dynamic>))
          .where((e) => e.phone.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveEmergencyContacts(List<EmergencyContactEntry> items) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(items.map((e) => e.toJson()).toList());
    await prefs.setString(_emergencyContactsKey, encoded);
  }
}

