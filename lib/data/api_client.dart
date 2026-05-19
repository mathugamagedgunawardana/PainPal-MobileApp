import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

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

  Map<String, String> _jsonHeaders() {
    final headers = <String, String>{'Content-Type': 'application/json'};
    final token = _auth.authToken;
    if (_auth.isAuthenticated && token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Map<String, String> _authOnlyHeaders() {
    final headers = <String, String>{};
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
      headers: _jsonHeaders(),
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

  /// Upload MRI to Vercel Blob via Next.js, then run ResNet18 prediction.
  Future<MriApiResponse> submitMriScan({
    required File image,
    String? patientId,
  }) async {
    final blobMeta = await _uploadMriToBlob(image: image, patientId: patientId);
    return _predictMriFromBlob(blobMeta);
  }

  /// POST /api/mri/upload-file — stores image in Vercel Blob (private).
  Future<Map<String, dynamic>> _uploadMriToBlob({
    required File image,
    String? patientId,
  }) async {
    final uri = Uri.parse('$baseUrl${BackendConfig.mriUploadFileEndpoint}');
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(_authOnlyHeaders());

    if (patientId != null && patientId.isNotEmpty) {
      request.fields['patient_id'] = patientId;
    }

    final fileName = p.basename(image.path);
    request.files.add(
      await http.MultipartFile.fromPath('file', image.path, filename: fileName),
    );

    final streamed = await request.send().timeout(BackendConfig.mriRequestTimeout);
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'MRI upload failed (${response.statusCode}): ${response.body}',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final pathname = body['blobPathname'] as String? ?? '';
    if (!pathname.startsWith('mri/')) {
      throw HttpException('MRI upload returned an invalid blob path.');
    }
    return body;
  }

  /// POST /api/mri/predict — JSON body after Blob upload.
  Future<MriApiResponse> _predictMriFromBlob(Map<String, dynamic> blobMeta) async {
    final uri = Uri.parse('$baseUrl${BackendConfig.mriPredictEndpoint}');
    final response = await _client
        .post(
          uri,
          headers: _jsonHeaders(),
          body: jsonEncode({
            'blobPathname': blobMeta['blobPathname'],
            if (blobMeta['blobUrl'] != null) 'blobUrl': blobMeta['blobUrl'],
            'originalFileName': blobMeta['originalFileName'] ?? 'upload',
            if (blobMeta['mimeType'] != null) 'mimeType': blobMeta['mimeType'],
          }),
        )
        .timeout(BackendConfig.mriRequestTimeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'MRI analysis failed (${response.statusCode}): ${response.body}',
      );
    }

    return MriApiResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
}
