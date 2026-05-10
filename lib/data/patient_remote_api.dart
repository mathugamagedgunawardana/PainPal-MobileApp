import 'dart:convert';

import 'package:http/http.dart' as http;

import 'backend_config.dart';
import 'models.dart';

/// Loads migraine events from Next.js (`GET /api/patient/migraine-events`).
Future<List<MigraineAttack>> fetchPatientMigraineEvents({
  required String baseUrl,
  required String bearerToken,
  http.Client? client,
}) async {
  final c = client ?? http.Client();
  final root = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
  final uri = Uri.parse('$root${BackendConfig.patientMigraineEventsEndpoint}');

  final response = await c
      .get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $bearerToken',
        },
      )
      .timeout(BackendConfig.requestTimeout);

  if (response.statusCode != 200) {
    throw Exception(
      'Migraine list failed (${response.statusCode}): ${response.body}',
    );
  }

  final data = jsonDecode(response.body) as Map<String, dynamic>;
  final raw = (data['events'] as List?)?.cast<Map<String, dynamic>>() ?? [];
  return raw.map(MigraineAttack.fromRemoteEvent).toList();
}

/// Loads MRI rows from Next.js (`GET /api/patient/mri-scans`); may be empty until scans are persisted server-side.
Future<List<MriScan>> fetchPatientMriScans({
  required String baseUrl,
  required String bearerToken,
  http.Client? client,
}) async {
  final c = client ?? http.Client();
  final root = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
  final uri = Uri.parse('$root${BackendConfig.patientMriScansEndpoint}');

  final response = await c
      .get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $bearerToken',
        },
      )
      .timeout(BackendConfig.requestTimeout);

  if (response.statusCode != 200) {
    throw Exception(
      'MRI list failed (${response.statusCode}): ${response.body}',
    );
  }

  final data = jsonDecode(response.body) as Map<String, dynamic>;
  final raw = (data['scans'] as List?)?.cast<Map<String, dynamic>>() ?? [];
  return raw.map(MriScan.fromRemoteJson).toList();
}
