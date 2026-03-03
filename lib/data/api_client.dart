import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'backend_config.dart';
import 'models.dart';

/// Legacy API client - maintained for backward compatibility
/// For new code, use PatientDataService instead
class ApiClient {
  ApiClient({
    required this.baseUrl,
    http.Client? client,
    dynamic authService,
  })  : _client = client ?? http.Client(),
        _authService = authService;

  final String baseUrl;
  final http.Client _client;
  final dynamic _authService;

  /// Get authorization headers if auth service is available
  Map<String, String> _getHeaders() {
    final headers = {'Content-Type': 'application/json'};
    if (_authService != null) {
      try {
        if (_authService.isAuthenticated) {
          headers['Authorization'] = 'Bearer ${_authService.authToken}';
        }
      } catch (_) {
        // Auth service not available
      }
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

    // Add auth header if available
    if (_authService != null) {
      try {
        if (_authService.isAuthenticated) {
          request.headers['Authorization'] = 'Bearer ${_authService.authToken}';
        }
      } catch (_) {
        // Auth service not available
      }
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

