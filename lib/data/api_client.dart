import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'models.dart';

class ApiClient {
  ApiClient({required this.baseUrl, http.Client? client})
      : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Future<MigraineApiResponse> submitMigraineAttack(
    MigraineAttack attack,
  ) async {
    final uri = Uri.parse('$baseUrl/api/summary');
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(attack.toApiJson()),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'Migraine request failed (${response.statusCode})',
      );
    }

    return MigraineApiResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<MriApiResponse> submitMriScan({
    required File image,
    String? patientId,
  }) async {
    final uri = Uri.parse('$baseUrl/api/mri/predict');
    final request = http.MultipartRequest('POST', uri);

    if (patientId != null && patientId.isNotEmpty) {
      request.fields['patient_id'] = patientId;
    }

    request.files.add(await http.MultipartFile.fromPath('file', image.path));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'MRI request failed (${response.statusCode})',
      );
    }

    return MriApiResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
}

