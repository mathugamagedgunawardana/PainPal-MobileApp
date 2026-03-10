import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_service.dart';

class ConversationSummary {
  ConversationSummary({
    required this.id,
    required this.otherName,
    required this.updatedAt,
  });

  final String id;
  final String otherName;
  final DateTime updatedAt;
}

class DoctorChatMessage {
  DoctorChatMessage({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.isMe,
    required this.senderRole,
  });

  final String id;
  final String content;
  final DateTime createdAt;
  final bool isMe;
  final String senderRole;
}

/// Service for doctor–patient chat backed by the web app (/api/chat/...).
class DoctorChatService {
  DoctorChatService({
    required AuthService authService,
    http.Client? client,
  })  : _authService = authService,
        _client = client ?? http.Client();

  final AuthService _authService;
  final http.Client _client;

  Future<String> _getBaseUrl() async {
    return _authService.getBaseUrl();
  }

  Map<String, String> _headers() {
    return _authService.getAuthHeaders();
  }

  Future<List<ConversationSummary>> listConversations() async {
    final baseUrl = await _getBaseUrl();
    final uri = Uri.parse('$baseUrl/api/chat/conversations');

    final response = await _client
        .get(uri, headers: _headers())
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load conversations (${response.statusCode})',
      );
    }

    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((raw) {
          final map = raw as Map<String, dynamic>;
          return ConversationSummary(
            id: map['id'] as String,
            otherName:
                (map['otherParty']?['name'] as String?) ?? 'Unknown contact',
            updatedAt:
                DateTime.tryParse(map['updatedAt'] as String? ?? '') ??
                    DateTime.now(),
          );
        })
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<List<DoctorChatMessage>> getMessages(String conversationId) async {
    final baseUrl = await _getBaseUrl();
    final uri = Uri.parse(
      '$baseUrl/api/chat/conversations/$conversationId/messages?limit=50',
    );

    final response = await _client
        .get(uri, headers: _headers())
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load messages (${response.statusCode})',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final items = (data['messages'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();

    final currentRole = _authService.currentUser?.role.toString().toUpperCase();

    return items
        .map(
          (m) => DoctorChatMessage(
            id: m['id'] as String,
            content: (m['content'] as String?) ?? '',
            createdAt:
                DateTime.tryParse(m['createdAt'] as String? ?? '') ??
                    DateTime.now(),
            senderRole: (m['senderRole'] as String?) ?? '',
            isMe: ((m['senderRole'] as String?) ?? '')
                    .toUpperCase() ==
                currentRole,
          ),
        )
        .toList();
  }

  Future<DoctorChatMessage> sendMessage({
    required String conversationId,
    required String content,
  }) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      throw Exception('Message cannot be empty');
    }

    final baseUrl = await _getBaseUrl();
    final uri =
        Uri.parse('$baseUrl/api/chat/conversations/$conversationId/messages');

    final response = await _client
        .post(
          uri,
          headers: {
            ..._headers(),
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'content': trimmed}),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'Failed to send message (${response.statusCode})',
      );
    }

    final m = jsonDecode(response.body) as Map<String, dynamic>;
    final currentRole = _authService.currentUser?.role.toString().toUpperCase();

    return DoctorChatMessage(
      id: m['id'] as String,
      content: (m['content'] as String?) ?? trimmed,
      createdAt:
          DateTime.tryParse(m['createdAt'] as String? ?? '') ??
              DateTime.now(),
      senderRole: (m['senderRole'] as String?) ?? '',
      isMe: ((m['senderRole'] as String?) ?? '').toUpperCase() ==
          currentRole,
    );
  }
}

