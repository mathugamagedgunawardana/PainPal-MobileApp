/// USER ACCEPTANCE TESTS (UAT) – Patient Journey
///
/// These tests are written from the END USER's perspective as acceptance
/// criteria (Given / When / Then).  They exercise the full service + data
/// layer as a patient would experience it, with only the network transport
/// and device storage replaced by test doubles.
///
/// UAT scenarios covered:
///   UAT-01  Patient can sign in with valid credentials
///   UAT-02  Patient cannot sign in with wrong password
///   UAT-03  Patient session persists after app restart
///   UAT-04  Patient can sign out and session is cleared
///   UAT-05  Patient can log a migraine attack and receive a prediction
///   UAT-06  Patient receives an error when server is unavailable during attack logging
///   UAT-07  Patient can send a message to their doctor
///   UAT-08  Patient can view their conversation history
///   UAT-09  Doctor link validation – patient cannot open chat without a token
///   UAT-10  Patient can start a new conversation using a doctor profile ID

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:painpal/data/api_client.dart';
import 'package:painpal/data/auth_service.dart';
import 'package:painpal/data/doctor_patient_chat_api.dart';
import 'package:painpal/data/models.dart';
import 'package:painpal/data/storage.dart';
import 'package:painpal/services/app_services.dart';

// ---------------------------------------------------------------------------
// Test infrastructure
// ---------------------------------------------------------------------------

class _FakeSettings extends SettingsStorage {
  _FakeSettings([this._url = 'http://api.painpal.test']);
  final String _url;
  @override
  Future<String?> readBaseUrl() async => _url;
}

Map<String, dynamic> _patientLoginBody({String token = 'uat-patient-token'}) => {
      'message': 'Login successful',
      'token': token,
      'user': {
        'id': 'user-jane',
        'email': 'patient@painpal.com',
        'role': 'PATIENT',
        'googleId': null,
        'googleEmail': null,
        'createdAt': null,
      },
      'patientProfile': {
        'id': 'profile-jane',
        'userId': 'user-jane',
        'name': 'Jane Doe',
        'dateOfBirth': '1995-05-10T00:00:00.000Z',
        'condition': 'migraine-with-aura',
      },
    };

MigraineAttack _migraineAttack() => MigraineAttack(
      durationHours: 6,
      frequencyPerMonth: 4,
      location: 'left',
      character: 'Throbbing',
      intensity: 8,
      nausea: 1,
      vomit: 0,
      phonophobia: 1,
      photophobia: 1,
      visual: 1,
      sensory: 0,
      dysphasia: 0,
      dysarthria: 0,
      vertigo: 0,
      tinnitus: 0,
      hypoacusis: 0,
      diplopia: 0,
      defect: 0,
      ataxia: 0,
      conscience: 0,
      paresthesia: 0,
      patientId: 'profile-jane',
      timestamp: DateTime.utc(2026, 5, 15, 8, 30),
    );

// ---------------------------------------------------------------------------
// UAT Tests
// ---------------------------------------------------------------------------
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  // ──────────────────────────────────────────────────────────
  // UAT-01  Patient can sign in with valid credentials
  // ──────────────────────────────────────────────────────────
  test('UAT-01 | GIVEN valid credentials WHEN patient signs in THEN session is active and profile is loaded', () async {
    // Arrange
    final client = MockClient((_) async =>
        http.Response(jsonEncode(_patientLoginBody(token: 'uat-01-token')), 200));
    final authSvc = AuthService(client: client, settingsStorage: _FakeSettings());

    // Act
    final response = await authSvc.login('patient@painpal.com', 'Patient@123');

    // Assert
    expect(authSvc.isAuthenticated, isTrue,
        reason: 'Patient should be authenticated after successful login');
    expect(authSvc.authToken, 'uat-01-token',
        reason: 'JWT token must be stored in memory');
    expect(response.user.email, 'patient@painpal.com');
    expect(authSvc.patientProfile?.name, 'Jane Doe',
        reason: 'Patient profile should be loaded automatically on login');
  });

  // ──────────────────────────────────────────────────────────
  // UAT-02  Patient cannot sign in with wrong password
  // ──────────────────────────────────────────────────────────
  test('UAT-02 | GIVEN wrong password WHEN patient attempts sign-in THEN error is shown and session stays inactive', () async {
    // Arrange
    final client = MockClient((_) async => http.Response(
          jsonEncode({'error': 'Invalid credentials', 'message': 'Email or password is incorrect'}),
          401,
        ));
    final authSvc = AuthService(client: client, settingsStorage: _FakeSettings());

    // Act & Assert
    AuthException? caught;
    try {
      await authSvc.login('patient@painpal.com', 'WrongPassword!');
    } on AuthException catch (e) {
      caught = e;
    }

    expect(caught, isNotNull, reason: 'AuthException must be thrown for bad credentials');
    expect(caught!.message, contains('401'),
        reason: 'Error message should include the HTTP status');
    expect(authSvc.isAuthenticated, isFalse,
        reason: 'Session must remain inactive after failed sign-in');
  });

  // ──────────────────────────────────────────────────────────
  // UAT-03  Patient session persists after app restart
  // ──────────────────────────────────────────────────────────
  test('UAT-03 | GIVEN a signed-in patient WHEN the app restarts THEN the session is automatically restored', () async {
    // Arrange – simulate prior login stored in prefs
    final savedUserJson = jsonEncode({
      'id': 'user-jane',
      'email': 'patient@painpal.com',
      'role': 'PATIENT',
      'googleId': null,
      'googleEmail': null,
      'createdAt': null,
    });
    SharedPreferences.setMockInitialValues({
      'auth_token': 'persisted-token',
      'user_data': savedUserJson,
    });

    // Act – simulate fresh app launch
    final freshAuthSvc = AuthService(
      client: MockClient((_) async => http.Response('', 500)),
      settingsStorage: _FakeSettings(),
    );
    await freshAuthSvc.initialize();

    // Assert
    expect(freshAuthSvc.isAuthenticated, isTrue,
        reason: 'Session should be restored from local storage on app restart');
    expect(freshAuthSvc.authToken, 'persisted-token');
    expect(freshAuthSvc.currentUser?.email, 'patient@painpal.com');
  });

  // ──────────────────────────────────────────────────────────
  // UAT-04  Patient can sign out and session is cleared
  // ──────────────────────────────────────────────────────────
  test('UAT-04 | GIVEN a signed-in patient WHEN they sign out THEN session is fully cleared', () async {
    // Arrange
    final client = MockClient((_) async =>
        http.Response(jsonEncode(_patientLoginBody()), 200));
    final authSvc = AuthService(client: client, settingsStorage: _FakeSettings());
    await authSvc.login('patient@painpal.com', 'Patient@123');
    expect(authSvc.isAuthenticated, isTrue); // confirm signed in

    // Act
    await authSvc.logout();

    // Assert
    expect(authSvc.isAuthenticated, isFalse,
        reason: 'Patient must be unauthenticated after sign-out');
    expect(authSvc.authToken, isNull);
    expect(authSvc.currentUser, isNull);
    expect(authSvc.patientProfile, isNull);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('auth_token'), isNull,
        reason: 'Token must be removed from device storage on sign-out');
  });

  // ──────────────────────────────────────────────────────────
  // UAT-05  Patient can log a migraine attack and receive a prediction
  // ──────────────────────────────────────────────────────────
  test('UAT-05 | GIVEN signed-in patient WHEN migraine attack is submitted THEN prediction type and summary are returned', () async {
    // Arrange
    int callNum = 0;
    final client = MockClient((_) async {
      callNum++;
      if (callNum == 1) return http.Response(jsonEncode(_patientLoginBody()), 200);
      return http.Response(
        jsonEncode({
          'predicted_migraine_type': 'Migraine with aura',
          'summary': 'You experienced a moderate migraine with visual aura. Triggers may include stress and bright light.',
          'symptoms_received': ['Nausea', 'Photophobia', 'Phonophobia', 'Visual'],
        }),
        200,
      );
    });

    final authSvc = AuthService(client: client, settingsStorage: _FakeSettings());
    await authSvc.login('patient@painpal.com', 'Patient@123');

    final apiClient = ApiClient(
      baseUrl: 'http://api.painpal.test',
      client: client,
      authService: authSvc,
    );

    // Act
    final result = await apiClient.submitMigraineAttack(_migraineAttack());

    // Assert
    expect(result.predictedType, 'Migraine with aura',
        reason: 'Patient should see the AI-predicted migraine type');
    expect(result.summary, isNotEmpty,
        reason: 'Patient should receive a human-readable summary');
    expect(result.symptomsReceived, contains('Nausea'),
        reason: 'Server should confirm which symptoms were received');
  });

  // ──────────────────────────────────────────────────────────
  // UAT-06  Patient receives an error when server is unavailable during attack logging
  // ──────────────────────────────────────────────────────────
  test('UAT-06 | GIVEN server is down WHEN patient submits a migraine attack THEN an error is surfaced to the UI layer', () async {
    // Arrange
    int callNum = 0;
    final client = MockClient((_) async {
      callNum++;
      if (callNum == 1) return http.Response(jsonEncode(_patientLoginBody()), 200);
      return http.Response('Service Unavailable', 503);
    });

    final authSvc = AuthService(client: client, settingsStorage: _FakeSettings());
    await authSvc.login('patient@painpal.com', 'Patient@123');

    final apiClient = ApiClient(
      baseUrl: 'http://api.painpal.test',
      client: client,
      authService: authSvc,
    );

    // Act & Assert
    expect(
      () => apiClient.submitMigraineAttack(_migraineAttack()),
      throwsA(isA<Exception>()),
      reason: 'Exception must propagate so the UI can display an error message to the patient',
    );
  });

  // ──────────────────────────────────────────────────────────
  // UAT-07  Patient can send a message to their doctor
  // ──────────────────────────────────────────────────────────
  test('UAT-07 | GIVEN authenticated patient WHEN they send a message THEN message is delivered and returned', () async {
    // Arrange – bootstrap global session (DoctorPatientChatApi uses AppServices.auth)
    final userJson = jsonEncode({
      'id': 'user-jane',
      'email': 'patient@painpal.com',
      'role': 'PATIENT',
      'googleId': null,
      'googleEmail': null,
      'createdAt': null,
    });
    SharedPreferences.setMockInitialValues({
      'auth_token': 'uat-07-token',
      'user_data': userJson,
      'base_url': 'http://api.painpal.test',
    });
    await AppServices.init();

    final client = MockClient((_) async => http.Response(
          jsonEncode({
            'id': 'msg-uat-07',
            'content': 'Doctor, my migraine lasted 6 hours today.',
            'senderRole': 'PATIENT',
            'createdAt': '2026-05-15T09:30:00.000Z',
          }),
          200,
        ));
    final chatApi = DoctorPatientChatApi(client: client);

    // Act
    final msg = await chatApi.sendMessage('conv-1', 'Doctor, my migraine lasted 6 hours today.');

    // Assert
    expect(msg.content, 'Doctor, my migraine lasted 6 hours today.',
        reason: 'Message content must be preserved exactly as typed');
    expect(msg.senderRole, 'PATIENT',
        reason: 'Message must be attributed to the correct sender role');

    // Cleanup
    await AppServices.auth.logout();
    SharedPreferences.setMockInitialValues({});
  });

  // ──────────────────────────────────────────────────────────
  // UAT-08  Patient can view their conversation history
  // ──────────────────────────────────────────────────────────
  test('UAT-08 | GIVEN existing conversation WHEN patient opens chat THEN previous messages are displayed', () async {
    // Arrange
    final userJson = jsonEncode({
      'id': 'user-jane',
      'email': 'patient@painpal.com',
      'role': 'PATIENT',
      'googleId': null,
      'googleEmail': null,
      'createdAt': null,
    });
    SharedPreferences.setMockInitialValues({
      'auth_token': 'uat-08-token',
      'user_data': userJson,
      'base_url': 'http://api.painpal.test',
    });
    await AppServices.init();

    final client = MockClient((_) async => http.Response(
          jsonEncode({
            'messages': [
              {'id': 'm1', 'content': 'Hello doctor.', 'senderRole': 'PATIENT', 'createdAt': '2026-05-15T08:00:00.000Z'},
              {'id': 'm2', 'content': 'Good morning! How can I help?', 'senderRole': 'DOCTOR', 'createdAt': '2026-05-15T08:05:00.000Z'},
              {'id': 'm3', 'content': 'My migraine was very severe yesterday.', 'senderRole': 'PATIENT', 'createdAt': '2026-05-15T08:06:00.000Z'},
            ],
          }),
          200,
        ));
    final chatApi = DoctorPatientChatApi(client: client);

    // Act
    final messages = await chatApi.fetchMessages('conv-1');

    // Assert
    expect(messages.length, 3,
        reason: 'All 3 prior messages must be loaded into the chat view');
    expect(messages.first.senderRole, 'PATIENT');
    expect(messages[1].senderRole, 'DOCTOR',
        reason: 'Doctor replies must be distinguished from patient messages');
    expect(messages.last.content, 'My migraine was very severe yesterday.');

    // Cleanup
    await AppServices.auth.logout();
    SharedPreferences.setMockInitialValues({});
  });

  // ──────────────────────────────────────────────────────────
  // UAT-09  Patient cannot open chat without being signed in
  // ──────────────────────────────────────────────────────────
  test('UAT-09 | GIVEN unauthenticated patient WHEN they try to open chat THEN sign-in error is raised', () async {
    // Arrange – ensure no global token
    SharedPreferences.setMockInitialValues({});
    await AppServices.auth.logout();

    final chatApi = DoctorPatientChatApi();

    // Act & Assert
    expect(
      () => chatApi.listConversations(),
      throwsA(isA<StateError>()),
      reason: 'Unauthenticated patients must be blocked from accessing clinic chat',
    );
  });

  // ──────────────────────────────────────────────────────────
  // UAT-10  Patient can start a new conversation using a doctor profile ID
  // ──────────────────────────────────────────────────────────
  test('UAT-10 | GIVEN authenticated patient and a doctor profile ID WHEN they open a conversation THEN conversation ID is returned', () async {
    // Arrange
    final userJson = jsonEncode({
      'id': 'user-jane',
      'email': 'patient@painpal.com',
      'role': 'PATIENT',
      'googleId': null,
      'googleEmail': null,
      'createdAt': null,
    });
    SharedPreferences.setMockInitialValues({
      'auth_token': 'uat-10-token',
      'user_data': userJson,
      'base_url': 'http://api.painpal.test',
    });
    await AppServices.init();

    final client = MockClient((req) async {
      final body = jsonDecode(req.body) as Map<String, dynamic>;
      expect(body['doctorId'], 'dp-dr-johnson',
          reason: 'The correct doctor profile ID must be sent in the request');
      return http.Response(jsonEncode({'id': 'new-conv-uat-10'}), 200);
    });
    final chatApi = DoctorPatientChatApi(client: client);

    // Act
    final convId = await chatApi.ensureConversationForDoctor('dp-dr-johnson');

    // Assert
    expect(convId, 'new-conv-uat-10',
        reason: 'The new conversation ID must be returned so the UI can load messages');

    // Cleanup
    await AppServices.auth.logout();
    SharedPreferences.setMockInitialValues({});
  });
}
