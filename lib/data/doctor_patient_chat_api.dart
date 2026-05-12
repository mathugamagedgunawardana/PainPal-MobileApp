import 'dart:convert';

import 'package:http/http.dart' as http;

import 'backend_config.dart';
import 'storage.dart';
import '../services/app_services.dart';

/// One row from `GET /api/chat/conversations`.
class PatientChatConversation {
  PatientChatConversation({
    required this.id,
    required this.otherPartyId,
    required this.otherPartyName,
    this.lastMessagePreview,
    this.lastMessageAt,
  });

  final String id;
  final String otherPartyId;
  final String otherPartyName;
  final String? lastMessagePreview;
  final DateTime? lastMessageAt;

  static PatientChatConversation fromJson(Map<String, dynamic> json) {
    final other = json['otherParty'] as Map<String, dynamic>? ?? {};
    final lm = json['lastMessage'] as Map<String, dynamic>?;
    return PatientChatConversation(
      id: json['id'] as String,
      otherPartyId: other['id'] as String? ?? '',
      otherPartyName: other['name'] as String? ?? 'Doctor',
      lastMessagePreview: lm?['content'] as String?,
      lastMessageAt: lm?['createdAt'] != null
          ? DateTime.tryParse(lm!['createdAt'] as String)
          : null,
    );
  }
}

/// Message from `GET/POST .../messages`.
class PatientChatMessage {
  PatientChatMessage({
    required this.id,
    required this.senderRole,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final String senderRole; // DOCTOR | PATIENT
  final String content;
  final DateTime createdAt;

  static PatientChatMessage fromJson(Map<String, dynamic> json) {
    return PatientChatMessage(
      id: json['id'] as String,
      senderRole: (json['senderRole'] as String? ?? '').toUpperCase(),
      content: json['content'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

Map<String, String> _headers(String token) => {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

String _root(String baseUrl) => baseUrl.trim().replaceAll(RegExp(r'/+$'), '');

/// Lists conversations, loads messages, sends messages (same contract as web [ChatPanel]).
class DoctorPatientChatApi {
  DoctorPatientChatApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<String> _base() async {
    final fromSettings = await SettingsStorage().readBaseUrl();
    if (fromSettings != null && fromSettings.trim().isNotEmpty) {
      return _root(fromSettings);
    }
    return _root(await AppServices.auth.resolveApiBaseUrl());
  }

  String? _token() {
    final t = AppServices.auth.authToken;
    if (t == null || t.isEmpty) {
      return null;
    }
    return t;
  }

  Future<List<PatientChatConversation>> listConversations() async {
    final token = _token();
    if (token == null) {
      throw StateError('Not signed in');
    }
    final base = await _base();
    final uri = Uri.parse('$base${BackendConfig.chatConversationsEndpoint}');
    final res = await _client
        .get(uri, headers: _headers(token))
        .timeout(BackendConfig.requestTimeout);
    if (res.statusCode != 200) {
      throw Exception('Chat list failed (${res.statusCode}): ${res.body}');
    }
    final list = jsonDecode(res.body) as List<dynamic>;
    return list
        .map((e) => PatientChatConversation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Patient: `{ doctorId }`. Returns conversation id.
  Future<String> ensureConversationForDoctor(String doctorProfileId) async {
    final token = _token();
    if (token == null) {
      throw StateError('Not signed in');
    }
    final base = await _base();
    final uri = Uri.parse('$base${BackendConfig.chatConversationsEndpoint}');
    final res = await _client
        .post(
          uri,
          headers: _headers(token),
          body: jsonEncode({'doctorId': doctorProfileId}),
        )
        .timeout(BackendConfig.requestTimeout);
    if (res.statusCode != 200) {
      throw Exception('Could not open chat (${res.statusCode}): ${res.body}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return data['id'] as String;
  }

  Future<List<PatientChatMessage>> fetchMessages(
    String conversationId, {
    int limit = 50,
  }) async {
    final token = _token();
    if (token == null) {
      throw StateError('Not signed in');
    }
    final base = await _base();
    final path = BackendConfig.chatMessagesEndpoint(conversationId);
    final uri = Uri.parse('$base$path').replace(queryParameters: {
      'limit': '$limit',
    });
    final res = await _client
        .get(uri, headers: _headers(token))
        .timeout(BackendConfig.requestTimeout);
    if (res.statusCode != 200) {
      throw Exception('Messages failed (${res.statusCode}): ${res.body}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final raw = (data['messages'] as List?) ?? [];
    return raw
        .map((e) => PatientChatMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PatientChatMessage> sendMessage(
    String conversationId,
    String content,
  ) async {
    final token = _token();
    if (token == null) {
      throw StateError('Not signed in');
    }
    final base = await _base();
    final uri = Uri.parse('$base${BackendConfig.chatMessagesEndpoint(conversationId)}');
    final res = await _client
        .post(
          uri,
          headers: _headers(token),
          body: jsonEncode({'content': content}),
        )
        .timeout(BackendConfig.requestTimeout);
    if (res.statusCode != 200) {
      throw Exception('Send failed (${res.statusCode}): ${res.body}');
    }
    return PatientChatMessage.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }
}
