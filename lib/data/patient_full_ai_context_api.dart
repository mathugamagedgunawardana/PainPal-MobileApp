import 'dart:convert';

import 'package:http/http.dart' as http;

import 'backend_config.dart';

/// Full Prisma-aligned patient export from `GET /api/patient/ai-context` (PATIENT JWT).
Future<String?> fetchPatientAiContextExport({
  required String baseUrl,
  required String bearerToken,
  http.Client? client,
}) async {
  final c = client ?? http.Client();
  final root = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
  final uri = Uri.parse('$root${BackendConfig.patientAiContextEndpoint}');

  final response = await c
      .get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $bearerToken',
        },
      )
      .timeout(const Duration(seconds: 90));

  if (response.statusCode != 200) {
    throw Exception(
      'AI context export failed (${response.statusCode}): ${response.body}',
    );
  }

  final data = jsonDecode(response.body) as Map<String, dynamic>;
  final text = data['contextText'] as String?;
  if (text == null || text.trim().isEmpty) {
    return null;
  }
  return text.trim();
}
