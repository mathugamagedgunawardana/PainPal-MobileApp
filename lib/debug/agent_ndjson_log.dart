import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Debug-mode NDJSON to the Cursor ingest endpoint (Android emulator → host via 10.0.2.2).
Future<void> agentNdjsonLog({
  required String hypothesisId,
  required String location,
  required String message,
  Map<String, Object?> data = const {},
}) async {
  if (!kDebugMode) return;
  final uri = Platform.isAndroid
      ? Uri.parse(
          'http://10.0.2.2:7331/ingest/fd8dbf68-2237-4692-9a2f-a39d94c50740',
        )
      : Uri.parse(
          'http://127.0.0.1:7331/ingest/fd8dbf68-2237-4692-9a2f-a39d94c50740',
        );
  final payload = jsonEncode({
    'sessionId': 'bac298',
    'timestamp': DateTime.now().millisecondsSinceEpoch,
    'hypothesisId': hypothesisId,
    'location': location,
    'message': message,
    'data': data,
  });
  try {
    await http
        .post(
          uri,
          headers: const {
            'Content-Type': 'application/json',
            'X-Debug-Session-Id': 'bac298',
          },
          body: payload,
        )
        .timeout(const Duration(seconds: 2));
  } catch (_) {}
}
