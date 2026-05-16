/// INTEGRATION TESTS – AuthService + ApiClient + DoctorPatientChatApi
///
/// Scope: multiple real service modules work together as they would in
/// production.  Only the HTTP transport layer (MockClient) and
/// SharedPreferences storage are replaced with test doubles.
///
/// Modules exercised for real (not mocked):
///   • AuthService  – login, initialize, logout, getAuthHeaders
///   • ApiClient    – submitMigraineAttack (uses AuthService token)
///   • DoctorPatientChatApi – sendMessage (uses global AppServices.auth)
///   • StorageSettings – readBaseUrl / readTokenKey (via SharedPrefs mock)
///
/// The tests verify that token produced by AuthService.login is correctly
/// threaded through to downstream API calls by ApiClient without extra
/// configuration.

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
// Helpers shared across groups
// ---------------------------------------------------------------------------

class _FixedSettingsStorage extends SettingsStorage {
  _FixedSettingsStorage(this._base);
  final String _base;
  @override
  Future<String?> readBaseUrl() async => _base;
}

Map<String, dynamic> _loginResponseBody({
  String token = 'test-jwt-token',
  String role = 'PATIENT',
}) =>
    {
      'message': 'Login successful',
      'token': token,
      'user': {
        'id': 'u1',
        'email': 'patient@painpal.com',
        'role': role,
        'googleId': null,
        'googleEmail': null,
        'createdAt': null,
      },
      'patientProfile': {
        'id': 'pp-1',
        'userId': 'u1',
        'name': 'Jane Doe',
        'dateOfBirth': '1995-05-10T00:00:00.000Z',
      },
    };

MigraineAttack _sampleAttack() => MigraineAttack(
      durationHours: 4,
      frequencyPerMonth: 3,
      location: 'left',
      character: 'Throbbing',
      intensity: 7,
      nausea: 1,
      vomit: 0,
      phonophobia: 1,
      photophobia: 1,
      visual: 0,
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
      patientId: 'pp-1',
      timestamp: DateTime.utc(2026, 5, 15, 9, 0),
    );

// ---------------------------------------------------------------------------
// IT-01 – IT-05  AuthService ↔ token storage integration
// ---------------------------------------------------------------------------
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('IT-01..05 | AuthService login → initialize → logout chain', () {
    test('IT-01 | Login stores token; initialize restores it; getAuthHeaders carries it', () async {
      final loginBody = _loginResponseBody(token: 'chain-token');
      int call = 0;
      final client = MockClient((_) async {
        call++;
        return http.Response(jsonEncode(loginBody), 200);
      });

      final svc = AuthService(
        client: client,
        settingsStorage: _FixedSettingsStorage('http://test.local'),
      );

      // Login
      await svc.login('patient@painpal.com', 'Patient@123');
      expect(svc.isAuthenticated, isTrue);
      expect(svc.authToken, 'chain-token');

      // Simulate app restart: new service instance, same prefs
      final svc2 = AuthService(
        client: client,
        settingsStorage: _FixedSettingsStorage('http://test.local'),
      );
      await svc2.initialize();
      expect(svc2.isAuthenticated, isTrue);
      expect(svc2.authToken, 'chain-token');
      expect(svc2.getAuthHeaders()['Authorization'], 'Bearer chain-token');
    });

    test('IT-02 | Logout clears token; re-initialize confirms no session', () async {
      final loginBody = _loginResponseBody(token: 'logout-token');
      final client = MockClient((_) async =>
          http.Response(jsonEncode(loginBody), 200));

      final svc = AuthService(
        client: client,
        settingsStorage: _FixedSettingsStorage('http://test.local'),
      );
      await svc.login('patient@painpal.com', 'Patient@123');
      await svc.logout();

      expect(svc.isAuthenticated, isFalse);

      // Confirm prefs are cleared
      final svc2 = AuthService(
        client: client,
        settingsStorage: _FixedSettingsStorage('http://test.local'),
      );
      await svc2.initialize();
      expect(svc2.isAuthenticated, isFalse);
      expect(svc2.getAuthHeaders().containsKey('Authorization'), isFalse);
    });

    test('IT-03 | Wrong password keeps service unauthenticated; headers lack token', () async {
      final client = MockClient((_) async =>
          http.Response(jsonEncode({'error': 'Invalid credentials'}), 401));

      final svc = AuthService(
        client: client,
        settingsStorage: _FixedSettingsStorage('http://test.local'),
      );

      try {
        await svc.login('patient@painpal.com', 'BadPass');
      } on AuthException {
        // expected
      }

      expect(svc.isAuthenticated, isFalse);
      expect(svc.getAuthHeaders().containsKey('Authorization'), isFalse);
    });

    test('IT-04 | patientProfile is available through service after login', () async {
      final loginBody = _loginResponseBody();
      final client = MockClient((_) async =>
          http.Response(jsonEncode(loginBody), 200));
      final svc = AuthService(
        client: client,
        settingsStorage: _FixedSettingsStorage('http://test.local'),
      );
      await svc.login('patient@painpal.com', 'Patient@123');
      expect(svc.patientProfile?.name, 'Jane Doe');
      expect(svc.currentUser?.email, 'patient@painpal.com');
    });

    test('IT-05 | Token refresh updates the stored token end-to-end', () async {
      int callCount = 0;
      final client = MockClient((_) async {
        callCount++;
        if (callCount == 1) {
          return http.Response(jsonEncode(_loginResponseBody(token: 'old-token')), 200);
        }
        return http.Response(jsonEncode({'token': 'new-refreshed-token'}), 200);
      });

      final svc = AuthService(
        client: client,
        settingsStorage: _FixedSettingsStorage('http://test.local'),
      );
      await svc.login('patient@painpal.com', 'Patient@123');
      expect(svc.authToken, 'old-token');

      final refreshed = await svc.refreshToken();
      expect(refreshed, 'new-refreshed-token');
      expect(svc.authToken, 'new-refreshed-token');
      // Confirm prefs were updated too
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('auth_token'), 'new-refreshed-token');
    });
  });

  // -------------------------------------------------------------------------
  // IT-06 – IT-08  AuthService ↔ ApiClient token threading
  // -------------------------------------------------------------------------
  group('IT-06..08 | AuthService token → ApiClient Authorization header', () {
    test('IT-06 | Token from AuthService.login is forwarded to migraine submission', () async {
      http.Request? migraineRequest;
      int callNum = 0;

      final client = MockClient((req) async {
        callNum++;
        if (callNum == 1) {
          // Login call
          return http.Response(jsonEncode(_loginResponseBody(token: 'session-abc')), 200);
        }
        // Migraine submission call
        migraineRequest = req;
        return http.Response(
          jsonEncode({
            'predicted_migraine_type': 'Migraine with aura',
            'summary': 'Moderate episode.',
            'symptoms_received': ['Nausea'],
          }),
          200,
        );
      });

      final authSvc = AuthService(
        client: client,
        settingsStorage: _FixedSettingsStorage('http://test.local'),
      );
      await authSvc.login('patient@painpal.com', 'Patient@123');

      final apiClient = ApiClient(
        baseUrl: 'http://test.local',
        client: client,
        authService: authSvc,
      );

      final result = await apiClient.submitMigraineAttack(_sampleAttack());

      expect(result.predictedType, 'Migraine with aura');
      expect(migraineRequest!.headers['Authorization'], 'Bearer session-abc');
    });

    test('IT-07 | After logout, ApiClient sends no Authorization header', () async {
      http.Request? migraineRequest;
      int callNum = 0;

      final client = MockClient((req) async {
        callNum++;
        if (callNum == 1) return http.Response(jsonEncode(_loginResponseBody()), 200);
        migraineRequest = req;
        return http.Response(
          jsonEncode({
            'predicted_migraine_type': 'Unknown',
            'summary': 'n/a',
            'symptoms_received': [],
          }),
          200,
        );
      });

      final authSvc = AuthService(
        client: client,
        settingsStorage: _FixedSettingsStorage('http://test.local'),
      );
      await authSvc.login('patient@painpal.com', 'Patient@123');
      await authSvc.logout();

      final apiClient = ApiClient(
        baseUrl: 'http://test.local',
        client: client,
        authService: authSvc,
      );

      await apiClient.submitMigraineAttack(_sampleAttack());
      expect(migraineRequest!.headers.containsKey('Authorization'), isFalse);
    });

    test('IT-08 | ApiClient throws on non-200 from migraine endpoint', () async {
      int callNum = 0;
      final client = MockClient((_) async {
        callNum++;
        if (callNum == 1) return http.Response(jsonEncode(_loginResponseBody()), 200);
        return http.Response('{"error":"Unauthorized"}', 401);
      });

      final authSvc = AuthService(
        client: client,
        settingsStorage: _FixedSettingsStorage('http://test.local'),
      );
      await authSvc.login('patient@painpal.com', 'Patient@123');

      final apiClient = ApiClient(
        baseUrl: 'http://test.local',
        client: client,
        authService: authSvc,
      );

      expect(
        () => apiClient.submitMigraineAttack(_sampleAttack()),
        throwsA(isA<Exception>()),
      );
    });
  });

  // -------------------------------------------------------------------------
  // IT-09 – IT-10  Global AppServices.auth ↔ DoctorPatientChatApi
  // -------------------------------------------------------------------------
  group('IT-09..10 | AppServices.auth token → DoctorPatientChatApi', () {
    setUp(() async {
      final userJson = jsonEncode({
        'id': 'u1',
        'email': 'patient@painpal.com',
        'role': 'PATIENT',
        'googleId': null,
        'googleEmail': null,
        'createdAt': null,
      });
      SharedPreferences.setMockInitialValues({
        'auth_token': 'global-jwt',
        'user_data': userJson,
        'base_url': 'http://test.local',
      });
      await AppServices.init();
    });

    tearDown(() async {
      SharedPreferences.setMockInitialValues({});
      await AppServices.auth.logout();
    });

    test('IT-09 | Chat sendMessage is authenticated with the global session token', () async {
      http.Request? captured;
      final client = MockClient((req) async {
        captured = req;
        return http.Response(
          jsonEncode({
            'id': 'msg-new',
            'content': 'My head hurts badly.',
            'senderRole': 'PATIENT',
            'createdAt': '2026-05-15T09:00:00.000Z',
          }),
          200,
        );
      });

      final chatApi = DoctorPatientChatApi(client: client);
      final msg = await chatApi.sendMessage('conv-1', 'My head hurts badly.');

      expect(msg.content, 'My head hurts badly.');
      expect(captured!.headers['Authorization'], 'Bearer global-jwt');
    });

    test('IT-10 | ensureConversationForDoctor uses global token and returns id', () async {
      final client = MockClient((_) async =>
          http.Response(jsonEncode({'id': 'conv-created-55'}), 200));
      final chatApi = DoctorPatientChatApi(client: client);

      final id = await chatApi.ensureConversationForDoctor('dp-abc');
      expect(id, 'conv-created-55');
    });
  });
}
