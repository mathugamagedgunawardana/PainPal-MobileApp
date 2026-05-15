import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:painpal/data/doctor_patient_chat_api.dart';
import 'package:painpal/services/app_services.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Map<String, dynamic> _convJson({
  String id = 'conv-1',
  String otherPartyId = 'doc-1',
  String otherPartyName = 'Dr. Smith',
  String? lastContent,
  String? lastAt,
}) =>
    {
      'id': id,
      'otherParty': {'id': otherPartyId, 'name': otherPartyName},
      if (lastContent != null || lastAt != null)
        'lastMessage': {
          'content': lastContent ?? '',
          'createdAt': lastAt ?? '2026-05-15T08:00:00.000Z',
        },
    };

Map<String, dynamic> _msgJson({
  String id = 'msg-1',
  String content = 'Hello doctor',
  String senderRole = 'PATIENT',
  String createdAt = '2026-05-15T09:00:00.000Z',
}) =>
    {
      'id': id,
      'content': content,
      'senderRole': senderRole,
      'createdAt': createdAt,
    };

/// Signs in the global AppServices.auth via SharedPreferences mock.
Future<void> _signInGlobal() async {
  final userJson = jsonEncode({
    'id': 'u1',
    'email': 'patient@painpal.com',
    'role': 'PATIENT',
    'googleId': null,
    'googleEmail': null,
    'createdAt': null,
  });
  SharedPreferences.setMockInitialValues({
    'auth_token': 'global-token',
    'user_data': userJson,
    'base_url': 'http://test.local',
  });
  await AppServices.init();
}

/// Signs out the global AppServices.auth.
Future<void> _signOutGlobal() async {
  SharedPreferences.setMockInitialValues({});
  await AppServices.auth.logout();
}

// ---------------------------------------------------------------------------
// PatientChatConversation model
// ---------------------------------------------------------------------------
void main() {
  group('PatientChatConversation – fromJson', () {
    test('parses id, otherPartyId, and otherPartyName', () {
      final conv = PatientChatConversation.fromJson(
        _convJson(id: 'c1', otherPartyId: 'dp-1', otherPartyName: 'Dr. Jones'),
      );
      expect(conv.id, 'c1');
      expect(conv.otherPartyId, 'dp-1');
      expect(conv.otherPartyName, 'Dr. Jones');
    });

    test('parses lastMessagePreview and lastMessageAt', () {
      final conv = PatientChatConversation.fromJson(
        _convJson(
          lastContent: 'See you at 3pm',
          lastAt: '2026-05-15T08:00:00.000Z',
        ),
      );
      expect(conv.lastMessagePreview, 'See you at 3pm');
      expect(conv.lastMessageAt, DateTime.utc(2026, 5, 15, 8, 0, 0));
    });

    test('lastMessage fields are null when key is absent', () {
      final conv = PatientChatConversation.fromJson(_convJson());
      expect(conv.lastMessagePreview, isNull);
      expect(conv.lastMessageAt, isNull);
    });

    test('defaults otherPartyName to "Doctor" when name is missing', () {
      final conv = PatientChatConversation.fromJson({
        'id': 'cx',
        'otherParty': {'id': 'dp-x'},
      });
      expect(conv.otherPartyName, 'Doctor');
    });
  });

  // -------------------------------------------------------------------------
  // PatientChatMessage model
  // -------------------------------------------------------------------------
  group('PatientChatMessage – fromJson', () {
    test('parses id, content, senderRole, createdAt', () {
      final msg = PatientChatMessage.fromJson(
        _msgJson(id: 'm1', content: 'Hi!', senderRole: 'doctor'),
      );
      expect(msg.id, 'm1');
      expect(msg.content, 'Hi!');
      expect(msg.senderRole, 'DOCTOR'); // uppercased
      expect(msg.createdAt, DateTime.utc(2026, 5, 15, 9, 0, 0));
    });

    test('uppercases senderRole', () {
      final msg = PatientChatMessage.fromJson(_msgJson(senderRole: 'patient'));
      expect(msg.senderRole, 'PATIENT');
    });

    test('defaults content to empty string when absent', () {
      final msg = PatientChatMessage.fromJson(
        {'id': 'x', 'senderRole': 'PATIENT', 'createdAt': '2026-01-01T00:00:00Z'},
      );
      expect(msg.content, '');
    });

    // ------------------------------------------------------------------
    // INTENTIONAL FAIL – the test expects senderRole to be stored in
    // lowercase, but fromJson() always uppercases it.
    // ------------------------------------------------------------------
    test('[FAIL] senderRole stored as lowercase – wrong assumption', () {
      final msg = PatientChatMessage.fromJson(_msgJson(senderRole: 'DOCTOR'));
      // BUG-SIM: developer expected lowercase; code stores uppercase
      expect(msg.senderRole, 'doctor'); // ← fails: actual value is 'DOCTOR'
    });
  });

  // -------------------------------------------------------------------------
  // DoctorPatientChatApi – listConversations
  // -------------------------------------------------------------------------
  group('DoctorPatientChatApi – listConversations', () {
    setUp(() async => _signInGlobal());
    tearDown(() async => _signOutGlobal());

    test('returns a list of conversations on HTTP 200', () async {
      final client = MockClient((_) async => http.Response(
            jsonEncode([_convJson(), _convJson(id: 'conv-2', otherPartyName: 'Dr. Lee')]),
            200,
          ));
      final api = DoctorPatientChatApi(client: client);

      final convs = await api.listConversations();

      expect(convs.length, 2);
      expect(convs.first.id, 'conv-1');
      expect(convs.first.otherPartyName, 'Dr. Smith');
      expect(convs[1].otherPartyName, 'Dr. Lee');
    });

    test('returns empty list when server returns []', () async {
      final client = MockClient((_) async => http.Response('[]', 200));
      final api = DoctorPatientChatApi(client: client);

      final convs = await api.listConversations();
      expect(convs, isEmpty);
    });

    test('throws when server returns 401', () async {
      final client = MockClient((_) async =>
          http.Response('{"error":"Unauthorized"}', 401));
      final api = DoctorPatientChatApi(client: client);

      expect(() => api.listConversations(), throwsA(isA<Exception>()));
    });

    // ------------------------------------------------------------------
    // INTENTIONAL FAIL – expects AuthException; code throws StateError
    // ------------------------------------------------------------------
    test('[FAIL] throws AuthException when not signed in – wrong exception type', () async {
      await _signOutGlobal(); // ensure no token

      // BUG-SIM: test assumes AuthException but code throws StateError
      expect(
        () => DoctorPatientChatApi().listConversations(),
        throwsA(isA<ArgumentError>()), // ← fails: actual is StateError
      );
    });
  });

  // -------------------------------------------------------------------------
  // DoctorPatientChatApi – fetchMessages
  // -------------------------------------------------------------------------
  group('DoctorPatientChatApi – fetchMessages', () {
    setUp(() async => _signInGlobal());
    tearDown(() async => _signOutGlobal());

    test('returns messages list on HTTP 200', () async {
      final body = jsonEncode({
        'messages': [
          _msgJson(id: 'm1', content: 'Hello', senderRole: 'PATIENT'),
          _msgJson(id: 'm2', content: 'Hi, how are you?', senderRole: 'DOCTOR'),
        ],
      });
      final client = MockClient((_) async => http.Response(body, 200));
      final api = DoctorPatientChatApi(client: client);

      final msgs = await api.fetchMessages('conv-1');

      expect(msgs.length, 2);
      expect(msgs.first.content, 'Hello');
      expect(msgs.first.senderRole, 'PATIENT');
      expect(msgs[1].senderRole, 'DOCTOR');
    });

    test('sends GET to correct messages endpoint', () async {
      http.Request? captured;
      final client = MockClient((req) async {
        captured = req;
        return http.Response(jsonEncode({'messages': []}), 200);
      });
      final api = DoctorPatientChatApi(client: client);

      await api.fetchMessages('conv-abc', limit: 20);

      expect(captured!.url.path, '/api/chat/conversations/conv-abc/messages');
      expect(captured!.url.queryParameters['limit'], '20');
    });

    test('includes Authorization header', () async {
      http.Request? captured;
      final client = MockClient((req) async {
        captured = req;
        return http.Response(jsonEncode({'messages': []}), 200);
      });
      final api = DoctorPatientChatApi(client: client);

      await api.fetchMessages('conv-1');

      expect(captured!.headers['Authorization'], 'Bearer global-token');
    });

    test('throws when server returns 403', () async {
      final client = MockClient((_) async =>
          http.Response('{"error":"Forbidden"}', 403));
      final api = DoctorPatientChatApi(client: client);

      expect(() => api.fetchMessages('conv-1'), throwsA(isA<Exception>()));
    });
  });

  // -------------------------------------------------------------------------
  // DoctorPatientChatApi – sendMessage
  // -------------------------------------------------------------------------
  group('DoctorPatientChatApi – sendMessage', () {
    setUp(() async => _signInGlobal());
    tearDown(() async => _signOutGlobal());

    test('returns PatientChatMessage on HTTP 200', () async {
      final responseMsg = _msgJson(
        id: 'new-msg',
        content: 'I have a headache.',
        senderRole: 'PATIENT',
      );
      final client = MockClient((_) async =>
          http.Response(jsonEncode(responseMsg), 200));
      final api = DoctorPatientChatApi(client: client);

      final msg = await api.sendMessage('conv-1', 'I have a headache.');

      expect(msg.id, 'new-msg');
      expect(msg.content, 'I have a headache.');
      expect(msg.senderRole, 'PATIENT');
    });

    test('sends POST to correct endpoint with content body', () async {
      http.Request? captured;
      final client = MockClient((req) async {
        captured = req;
        return http.Response(jsonEncode(_msgJson()), 200);
      });
      final api = DoctorPatientChatApi(client: client);

      await api.sendMessage('conv-1', 'Hello doctor');

      expect(captured!.url.path, '/api/chat/conversations/conv-1/messages');
      expect(captured!.method, 'POST');
      final body = jsonDecode(captured!.body) as Map<String, dynamic>;
      expect(body['content'], 'Hello doctor');
    });

    test('throws when server returns 400', () async {
      final client = MockClient((_) async =>
          http.Response('{"error":"Content required"}', 400));
      final api = DoctorPatientChatApi(client: client);

      expect(
        () => api.sendMessage('conv-1', ''),
        throwsA(isA<Exception>()),
      );
    });
  });

  // -------------------------------------------------------------------------
  // DoctorPatientChatApi – ensureConversationForDoctor
  // -------------------------------------------------------------------------
  group('DoctorPatientChatApi – ensureConversationForDoctor', () {
    setUp(() async => _signInGlobal());
    tearDown(() async => _signOutGlobal());

    test('returns conversation id from response on HTTP 200', () async {
      final client = MockClient((_) async =>
          http.Response(jsonEncode({'id': 'conv-new-99'}), 200));
      final api = DoctorPatientChatApi(client: client);

      final id = await api.ensureConversationForDoctor('dp-xyz');

      expect(id, 'conv-new-99');
    });

    test('sends POST with doctorId in body', () async {
      http.Request? captured;
      final client = MockClient((req) async {
        captured = req;
        return http.Response(jsonEncode({'id': 'conv-1'}), 200);
      });
      final api = DoctorPatientChatApi(client: client);

      await api.ensureConversationForDoctor('dp-xyz');

      expect(captured!.url.path, '/api/chat/conversations');
      final body = jsonDecode(captured!.body) as Map<String, dynamic>;
      expect(body['doctorId'], 'dp-xyz');
    });

    test('throws when server returns 404 (doctor not found)', () async {
      final client = MockClient((_) async =>
          http.Response('{"error":"Doctor not found"}', 404));
      final api = DoctorPatientChatApi(client: client);

      expect(
        () => api.ensureConversationForDoctor('nonexistent-dp'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
