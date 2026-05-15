import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:painpal/data/auth_models.dart';
import 'package:painpal/data/auth_service.dart';
import 'package:painpal/data/storage.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Fake SettingsStorage that returns a fixed base URL, bypassing SharedPreferences.
class _FakeSettingsStorage extends SettingsStorage {
  _FakeSettingsStorage({this.baseUrl});
  final String? baseUrl;

  @override
  Future<String?> readBaseUrl() async => baseUrl;
}

/// Build a JSON success response body matching the login API shape.
Map<String, dynamic> _buildSuccessBody({
  String userId = 'u1',
  String email = 'patient@painpal.com',
  String role = 'PATIENT',
  String name = 'Jane Doe',
  String token = 'test-jwt-token',
  Map<String, dynamic>? patientProfile,
}) {
  return {
    'message': 'Login successful',
    'token': token,
    'user': {
      'id': userId,
      'email': email,
      'role': role,
      'googleId': null,
      'googleEmail': null,
      'createdAt': null,
    },
    if (patientProfile != null) 'patientProfile': patientProfile,
  };
}

/// Build an AuthService wired to a MockClient and a fixed API base URL.
AuthService _makeService(MockClient client, {String baseUrl = 'http://test.local'}) {
  return AuthService(
    client: client,
    settingsStorage: _FakeSettingsStorage(baseUrl: baseUrl),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // -------------------------------------------------------------------------
  // Initial state
  // -------------------------------------------------------------------------
  group('AuthService – initial state', () {
    test('isAuthenticated is false before any login', () {
      final service = _makeService(MockClient((_) async => http.Response('', 500)));
      expect(service.isAuthenticated, isFalse);
      expect(service.authToken, isNull);
      expect(service.currentUser, isNull);
    });

    test('getAuthHeaders returns only Content-Type when not authenticated', () {
      final service = _makeService(MockClient((_) async => http.Response('', 500)));
      final headers = service.getAuthHeaders();
      expect(headers['Content-Type'], 'application/json');
      expect(headers.containsKey('Authorization'), isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // login – success
  // -------------------------------------------------------------------------
  group('AuthService – login success', () {
    final patientProfileJson = {
      'id': 'pp-1',
      'userId': 'u1',
      'name': 'Jane Doe',
      'dateOfBirth': '1995-05-10T00:00:00.000Z',
    };

    final successBody = _buildSuccessBody(patientProfile: patientProfileJson);

    late MockClient client;
    late AuthService service;

    setUp(() {
      client = MockClient((req) async {
        return http.Response(jsonEncode(successBody), 200);
      });
      service = _makeService(client);
    });

    test('returns a LoginResponse on HTTP 200', () async {
      final response = await service.login('patient@painpal.com', 'Patient@123');
      expect(response.token, 'test-jwt-token');
      expect(response.user.email, 'patient@painpal.com');
      expect(response.user.role, UserRole.patient);
    });

    test('sets isAuthenticated to true after successful login', () async {
      await service.login('patient@painpal.com', 'Patient@123');
      expect(service.isAuthenticated, isTrue);
    });

    test('stores token in memory after login', () async {
      await service.login('patient@painpal.com', 'Patient@123');
      expect(service.authToken, 'test-jwt-token');
    });

    test('stores currentUser in memory after login', () async {
      await service.login('patient@painpal.com', 'Patient@123');
      expect(service.currentUser?.email, 'patient@painpal.com');
    });

    test('parses and stores patientProfile after login', () async {
      await service.login('patient@painpal.com', 'Patient@123');
      expect(service.patientProfile?.name, 'Jane Doe');
    });

    test('persists token to SharedPreferences', () async {
      await service.login('patient@painpal.com', 'Patient@123');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('auth_token'), 'test-jwt-token');
    });

    test('sends request to the login endpoint with JSON body', () async {
      http.Request? capturedRequest;
      final capturingClient = MockClient((req) async {
        capturedRequest = req;
        return http.Response(jsonEncode(successBody), 200);
      });
      final svc = _makeService(capturingClient);

      await svc.login('patient@painpal.com', 'Patient@123');

      expect(capturedRequest, isNotNull);
      expect(capturedRequest!.url.path, '/api/auth/login');
      expect(capturedRequest!.method, 'POST');
      final sentBody = jsonDecode(capturedRequest!.body) as Map<String, dynamic>;
      expect(sentBody['email'], 'patient@painpal.com');
      expect(sentBody['password'], 'Patient@123');
    });

    test('getAuthHeaders includes Authorization header after login', () async {
      await service.login('patient@painpal.com', 'Patient@123');
      final headers = service.getAuthHeaders();
      expect(headers['Authorization'], 'Bearer test-jwt-token');
    });
  });

  // -------------------------------------------------------------------------
  // login – failure
  // -------------------------------------------------------------------------
  group('AuthService – login failure', () {
    test('throws AuthException on HTTP 401', () async {
      final client = MockClient((_) async =>
          http.Response(jsonEncode({'error': 'Invalid credentials'}), 401));
      final service = _makeService(client);

      expect(
        () => service.login('bad@email.com', 'wrongpass'),
        throwsA(isA<AuthException>()),
      );
    });

    test('throws AuthException on HTTP 400', () async {
      final client = MockClient((_) async =>
          http.Response(jsonEncode({'error': 'Missing credentials'}), 400));
      final service = _makeService(client);

      expect(
        () => service.login('', ''),
        throwsA(isA<AuthException>()),
      );
    });

    test('throws AuthException on HTTP 503 (database unavailable)', () async {
      final client = MockClient((_) async =>
          http.Response(jsonEncode({'error': 'Database unavailable'}), 503));
      final service = _makeService(client);

      expect(
        () => service.login('user@example.com', 'pass'),
        throwsA(isA<AuthException>()),
      );
    });

    test('does not set isAuthenticated on failure', () async {
      final client = MockClient((_) async =>
          http.Response(jsonEncode({'error': 'Invalid credentials'}), 401));
      final service = _makeService(client);

      try {
        await service.login('bad@email.com', 'wrongpass');
      } on AuthException {
        // expected
      }

      expect(service.isAuthenticated, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // logout
  // -------------------------------------------------------------------------
  group('AuthService – logout', () {
    test('clears isAuthenticated after logout', () async {
      final loginBody = _buildSuccessBody();
      final client = MockClient((_) async => http.Response(jsonEncode(loginBody), 200));
      final service = _makeService(client);

      await service.login('patient@painpal.com', 'Patient@123');
      expect(service.isAuthenticated, isTrue);

      await service.logout();
      expect(service.isAuthenticated, isFalse);
    });

    test('clears authToken and currentUser after logout', () async {
      final loginBody = _buildSuccessBody();
      final client = MockClient((_) async => http.Response(jsonEncode(loginBody), 200));
      final service = _makeService(client);

      await service.login('patient@painpal.com', 'Patient@123');
      await service.logout();

      expect(service.authToken, isNull);
      expect(service.currentUser, isNull);
    });

    test('removes token from SharedPreferences after logout', () async {
      final loginBody = _buildSuccessBody();
      final client = MockClient((_) async => http.Response(jsonEncode(loginBody), 200));
      final service = _makeService(client);

      await service.login('patient@painpal.com', 'Patient@123');
      await service.logout();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('auth_token'), isNull);
    });
  });

  // -------------------------------------------------------------------------
  // initialize (restore persisted session)
  // -------------------------------------------------------------------------
  group('AuthService – initialize', () {
    test('restores token and user from SharedPreferences', () async {
      final userJson = jsonEncode({
        'id': 'u-saved',
        'email': 'saved@example.com',
        'role': 'PATIENT',
        'googleId': null,
        'googleEmail': null,
        'createdAt': null,
      });
      SharedPreferences.setMockInitialValues({
        'auth_token': 'saved-jwt',
        'user_data': userJson,
      });

      final service = _makeService(MockClient((_) async => http.Response('', 500)));
      await service.initialize();

      expect(service.authToken, 'saved-jwt');
      expect(service.isAuthenticated, isTrue);
      expect(service.currentUser?.email, 'saved@example.com');
    });

    test('remains unauthenticated when no saved token', () async {
      SharedPreferences.setMockInitialValues({});

      final service = _makeService(MockClient((_) async => http.Response('', 500)));
      await service.initialize();

      expect(service.isAuthenticated, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // refreshToken
  // -------------------------------------------------------------------------
  group('AuthService – refreshToken', () {
    test('throws AuthException when no token is stored', () async {
      final service = _makeService(MockClient((_) async => http.Response('', 500)));
      expect(
        () => service.refreshToken(),
        throwsA(isA<AuthException>()),
      );
    });

    test('returns new token on HTTP 200', () async {
      final loginBody = _buildSuccessBody();
      int callCount = 0;
      final client = MockClient((_) async {
        callCount++;
        if (callCount == 1) {
          // login call
          return http.Response(jsonEncode(loginBody), 200);
        }
        // refresh call
        return http.Response(jsonEncode({'token': 'refreshed-token'}), 200);
      });
      final service = _makeService(client);

      await service.login('patient@painpal.com', 'Patient@123');
      final newToken = await service.refreshToken();

      expect(newToken, 'refreshed-token');
      expect(service.authToken, 'refreshed-token');
    });

    test('throws AuthException on HTTP 401 during refresh', () async {
      final loginBody = _buildSuccessBody();
      int callCount = 0;
      final client = MockClient((_) async {
        callCount++;
        if (callCount == 1) return http.Response(jsonEncode(loginBody), 200);
        return http.Response(jsonEncode({'error': 'Unauthorized'}), 401);
      });
      final service = _makeService(client);

      await service.login('patient@painpal.com', 'Patient@123');
      expect(
        () => service.refreshToken(),
        throwsA(isA<AuthException>()),
      );
    });
  });

  // -------------------------------------------------------------------------
  // AuthException
  // -------------------------------------------------------------------------
  group('AuthException', () {
    test('toString includes message and responseBody', () {
      final ex = AuthException('Login failed with status 401', '{"error":"Invalid credentials"}');
      expect(ex.toString(), contains('Login failed'));
      expect(ex.toString(), contains('Invalid credentials'));
    });
  });
}
