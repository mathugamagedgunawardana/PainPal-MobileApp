import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'auth_service.dart';
import 'backend_config.dart';
import 'models.dart';
import '../services/app_services.dart';

/// HTTP client for Next.js APIs ([/api/summary], [/api/mri/predict], etc.).
///
/// Sends [AppServices.auth] JWT when the user is signed in (home tab login).
class ApiClient {
  ApiClient({
    required this.baseUrl,
    http.Client? client,
    AuthService? authService,
  })  : _client = client ?? http.Client(),
        _authService = authService;

  final String baseUrl;
  final http.Client _client;
  final AuthService? _authService;

  AuthService get _auth => _authService ?? AppServices.auth;

  Map<String, String> _getHeaders() {
    final headers = {'Content-Type': 'application/json'};
    final token = _auth.authToken;
    if (_auth.isAuthenticated && token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<MigraineApiResponse> submitMigraineAttack(
    MigraineAttack attack,
  ) async {
    final uri = Uri.parse('$baseUrl/api/summary');
    final response = await _client.post(
      uri,
      headers: _getHeaders(),
      body: jsonEncode(attack.toApiJson()),
    ).timeout(BackendConfig.requestTimeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'Migraine request failed (${response.statusCode}): ${response.body}',
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

    final token = _auth.authToken;
    if (_auth.isAuthenticated && token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    if (patientId != null && patientId.isNotEmpty) {
      request.fields['patient_id'] = patientId;
    }

    request.files.add(await http.MultipartFile.fromPath('file', image.path));

    final streamed = await request.send().timeout(BackendConfig.requestTimeout);
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'MRI request failed (${response.statusCode}): ${response.body}',
      );
    }

    return MriApiResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
}

