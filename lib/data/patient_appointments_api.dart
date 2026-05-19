import 'dart:convert';

import 'package:http/http.dart' as http;

import 'backend_config.dart';
import 'storage.dart';
import '../services/app_services.dart';

class LinkedDoctorOption {
  LinkedDoctorOption({
    required this.doctorId,
    required this.name,
    required this.specialization,
    required this.clinicName,
    this.clinicAddress,
  });

  final String doctorId;
  final String name;
  final String specialization;
  final String clinicName;
  final String? clinicAddress;

  static LinkedDoctorOption fromJson(Map<String, dynamic> json) {
    return LinkedDoctorOption(
      doctorId: json['doctorId'] as String,
      name: json['name'] as String? ?? 'Doctor',
      specialization: json['specialization'] as String? ?? '',
      clinicName: json['clinicName'] as String? ?? '',
      clinicAddress: json['clinicAddress'] as String?,
    );
  }
}

class PatientAppointmentRow {
  PatientAppointmentRow({
    required this.id,
    required this.doctorId,
    required this.doctorName,
    required this.specialization,
    required this.appointmentDate,
    required this.appointmentType,
    required this.status,
    this.notes,
  });

  final String id;
  final String doctorId;
  final String doctorName;
  final String specialization;
  final DateTime appointmentDate;
  final String appointmentType;
  final String status;
  final String? notes;

  static PatientAppointmentRow fromJson(Map<String, dynamic> json) {
    return PatientAppointmentRow(
      id: json['id'] as String,
      doctorId: json['doctorId'] as String,
      doctorName: json['doctorName'] as String? ?? '',
      specialization: json['specialization'] as String? ?? '',
      appointmentDate: DateTime.tryParse(json['appointmentDate'] as String? ?? '') ??
          DateTime.now(),
      appointmentType: json['appointmentType'] as String? ?? '',
      status: json['status'] as String? ?? '',
      notes: json['notes'] as String?,
    );
  }
}

Map<String, String> _headers(String token) => {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

Future<String> _apiRoot() async {
  final fromSettings = await SettingsStorage().readBaseUrl();
  if (fromSettings != null && fromSettings.trim().isNotEmpty) {
    return fromSettings.trim().replaceAll(RegExp(r'/+$'), '');
  }
  return (await AppServices.auth.resolveApiBaseUrl())
      .trim()
      .replaceAll(RegExp(r'/+$'), '');
}

/// Linked doctors + appointments (patient JWT).
class PatientAppointmentsApi {
  PatientAppointmentsApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  String? _token() {
    final t = AppServices.auth.authToken;
    if (t == null || t.isEmpty) {
      return null;
    }
    return t;
  }

  Future<List<LinkedDoctorOption>> fetchLinkedDoctors() async {
    final token = _token();
    if (token == null) {
      throw StateError('Not signed in');
    }
    final root = await _apiRoot();
    final uri = Uri.parse('$root${BackendConfig.patientLinkedDoctorsEndpoint}');
    final res = await _client
        .get(uri, headers: _headers(token))
        .timeout(BackendConfig.requestTimeout);
    if (res.statusCode != 200) {
      throw Exception('Linked doctors failed (${res.statusCode}): ${res.body}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final raw = (data['doctors'] as List?) ?? [];
    return raw
        .map((e) => LinkedDoctorOption.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<PatientAppointmentRow>> fetchAppointments() async {
    final token = _token();
    if (token == null) {
      throw StateError('Not signed in');
    }
    final root = await _apiRoot();
    final uri = Uri.parse('$root${BackendConfig.patientAppointmentsEndpoint}');
    final res = await _client
        .get(uri, headers: _headers(token))
        .timeout(BackendConfig.requestTimeout);
    if (res.statusCode != 200) {
      throw Exception('Appointments failed (${res.statusCode}): ${res.body}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final raw = (data['appointments'] as List?) ?? [];
    return raw
        .map((e) => PatientAppointmentRow.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PatientAppointmentRow> createAppointment({
    required String doctorId,
    required DateTime appointmentDate,
    String appointmentType = 'General visit',
    String? notes,
  }) async {
    final token = _token();
    if (token == null) {
      throw StateError('Not signed in');
    }
    final root = await _apiRoot();
    final uri = Uri.parse('$root${BackendConfig.patientAppointmentsEndpoint}');
    final res = await _client
        .post(
          uri,
          headers: _headers(token),
          body: jsonEncode({
            'doctorId': doctorId,
            'appointmentDate': appointmentDate.toUtc().toIso8601String(),
            'appointmentType': appointmentType,
            if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
          }),
        )
        .timeout(BackendConfig.requestTimeout);
    if (res.statusCode != 200) {
      throw Exception('Schedule failed (${res.statusCode}): ${res.body}');
    }
    return PatientAppointmentRow.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }
}
