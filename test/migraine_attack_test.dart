import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:painpal/data/api_client.dart';
import 'package:painpal/data/auth_service.dart';
import 'package:painpal/data/models.dart';
import 'package:painpal/data/storage.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

class _FakeSettingsStorage extends SettingsStorage {
  _FakeSettingsStorage({this.baseUrl});
  final String? baseUrl;
  @override
  Future<String?> readBaseUrl() async => baseUrl;
}

MigraineAttack _buildAttack({
  int durationHours = 4,
  int intensity = 7,
  String location = 'left',
  String character = 'Throbbing',
  String? patientId,
  String? attackId,
  int? age,
}) =>
    MigraineAttack(
      durationHours: durationHours,
      frequencyPerMonth: 3,
      location: location,
      character: character,
      intensity: intensity,
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
      patientId: patientId,
      attackId: attackId,
      age: age,
      timestamp: DateTime.utc(2026, 5, 15, 9, 0, 0),
    );

Map<String, dynamic> _successApiBody({
  String type = 'Migraine with aura',
  String summary = 'Moderate migraine with typical aura features.',
}) =>
    {
      'predicted_migraine_type': type,
      'summary': summary,
      'symptoms_received': ['Nausea', 'Photophobia', 'Phonophobia'],
    };

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // -------------------------------------------------------------------------
  // MigraineAttack model
  // -------------------------------------------------------------------------
  group('MigraineAttack – toApiJson', () {
    test('includes all required clinical fields with correct capitalized keys', () {
      final attack = _buildAttack(patientId: 'pp-1', age: 30);
      final json = attack.toApiJson();

      expect(json['Duration'], 4);
      expect(json['Frequency'], 3);
      expect(json['Location'], 'left');
      expect(json['Character'], 'Throbbing');
      expect(json['Intensity'], 7);
      expect(json['Nausea'], 1);
      expect(json['Vomit'], 0);
      expect(json['Phonophobia'], 1);
      expect(json['Photophobia'], 1);
    });

    test('omits patient_id when null', () {
      final json = _buildAttack(patientId: null).toApiJson();
      expect(json.containsKey('patient_id'), isFalse);
    });

    test('omits patient_id when empty string', () {
      final json = _buildAttack(patientId: '').toApiJson();
      expect(json.containsKey('patient_id'), isFalse);
    });

    test('includes patient_id when set', () {
      final json = _buildAttack(patientId: 'patient-abc').toApiJson();
      expect(json['patient_id'], 'patient-abc');
    });

    test('includes age when set', () {
      final json = _buildAttack(age: 29).toApiJson();
      expect(json['age'], 29);
    });

    test('omits age when null', () {
      final json = _buildAttack(age: null).toApiJson();
      expect(json.containsKey('age'), isFalse);
    });

    test('includes timestamp as ISO 8601 string when set', () {
      final json = _buildAttack().toApiJson();
      expect(json['timestamp'], '2026-05-15T09:00:00.000Z');
    });

    // ------------------------------------------------------------------
    // INTENTIONAL FAIL – verifies a known incorrect assumption about the
    // field-naming convention: the key is capitalised 'Duration', NOT
    // lowercase 'duration'.  This test is expected to fail.
    // ------------------------------------------------------------------
    test('[FAIL] toApiJson uses lowercase "duration" key – wrong assumption', () {
      final json = _buildAttack().toApiJson();
      // BUG-SIM: developer assumed the API key is lowercase; it is actually 'Duration'
      expect(json['duration'], 4); // ← will fail: key does not exist (null ≠ 4)
    });
  });

  // -------------------------------------------------------------------------
  // MigraineAttack – fromRemoteEvent (from GET /api/patient/migraine-events)
  // -------------------------------------------------------------------------
  group('MigraineAttack – fromRemoteEvent', () {
    final remoteJson = {
      'id': 'evt-1',
      'timestamp': '2026-01-10T08:00:00.000Z',
      'durationHours': 6,
      'frequencyPerMonth': 4,
      'location': 'right',
      'character': 'Pressure',
      'intensity': 8,
      'nausea': 1,
      'vomit': 0,
      'phonophobia': 0,
      'photophobia': 1,
      'visual': 1,
      'sensory': 0,
      'dysphasia': 0,
      'dysarthria': 0,
      'vertigo': 0,
      'tinnitus': 0,
      'hypoacusis': 0,
      'diplopia': 0,
      'defect': 0,
      'ataxia': 0,
      'conscience': 0,
      'paresthesia': 0,
      'type': 'migraine-with-aura',
      'summary': 'Classic aura pattern.',
    };

    test('parses all clinical fields from remote event JSON', () {
      final attack = MigraineAttack.fromRemoteEvent(remoteJson);
      expect(attack.durationHours, 6);
      expect(attack.frequencyPerMonth, 4);
      expect(attack.location, 'right');
      expect(attack.character, 'Pressure');
      expect(attack.intensity, 8);
      expect(attack.nausea, 1);
      expect(attack.photophobia, 1);
      expect(attack.visual, 1);
    });

    test('stores event id as attackId', () {
      final attack = MigraineAttack.fromRemoteEvent(remoteJson);
      expect(attack.attackId, 'evt-1');
    });

    test('parses timestamp correctly', () {
      final attack = MigraineAttack.fromRemoteEvent(remoteJson);
      expect(attack.timestamp, DateTime.utc(2026, 1, 10, 8, 0, 0));
    });

    test('parses type and summary', () {
      final attack = MigraineAttack.fromRemoteEvent(remoteJson);
      expect(attack.type, 'migraine-with-aura');
      expect(attack.summary, 'Classic aura pattern.');
    });

    test('defaults missing fields to zero', () {
      final sparse = {'id': 'x', 'intensity': 5};
      final attack = MigraineAttack.fromRemoteEvent(sparse);
      expect(attack.nausea, 0);
      expect(attack.vertigo, 0);
      expect(attack.durationHours, 0);
    });
  });

  // -------------------------------------------------------------------------
  // MigraineAttack – draft JSON round-trip
  // -------------------------------------------------------------------------
  group('MigraineAttack – draft JSON round-trip', () {
    test('toDraftJson / fromDraftJson preserves clinical fields, patientId and attackId', () {
      final original = _buildAttack(patientId: 'pp-1', attackId: 'atk-2026', age: 28);
      final json = original.toDraftJson();
      final restored = MigraineAttack.fromDraftJson(json)!;

      expect(restored.durationHours, original.durationHours);
      expect(restored.intensity, original.intensity);
      expect(restored.location, original.location);
      expect(restored.nausea, original.nausea);
      expect(restored.patientId, original.patientId);
      expect(restored.attackId, original.attackId);
      // NOTE: age is intentionally NOT checked here – see the FAIL test below
    });

    // ------------------------------------------------------------------
    // INTENTIONAL FAIL – exposes a real data-loss bug: toDbMap() does
    // NOT include the 'age' field, so age is silently dropped when a
    // draft is saved and re-loaded.
    // ------------------------------------------------------------------
    test('[FAIL] toDraftJson / fromDraftJson drops age – real data-loss bug', () {
      final original = _buildAttack(age: 28);
      final restored = MigraineAttack.fromDraftJson(original.toDraftJson())!;
      // BUG: toDbMap() never serialises 'age'; fromDb reads null back
      expect(restored.age, 28); // ← fails: actual is null
    });

    test('fromDraftJson returns null for null input', () {
      expect(MigraineAttack.fromDraftJson(null), isNull);
    });

    test('fromDraftJson returns null for empty string', () {
      expect(MigraineAttack.fromDraftJson(''), isNull);
    });

    // ------------------------------------------------------------------
    // INTENTIONAL FAIL – fromDraftJson(null) should throw, not return
    // null.  This reflects a stricter contract that the code does not
    // currently enforce.
    // ------------------------------------------------------------------
    test('[FAIL] fromDraftJson(null) should throw ArgumentError – not null-safe', () {
      // BUG-SIM: developer assumed null input raises an error; it actually returns null
      expect(() => MigraineAttack.fromDraftJson(null), throwsA(isA<ArgumentError>()));
    });
  });

  // -------------------------------------------------------------------------
  // ApiClient – submitMigraineAttack
  // -------------------------------------------------------------------------
  group('ApiClient – submitMigraineAttack', () {
    late AuthService authService;

    setUp(() async {
      final userJson = jsonEncode({
        'id': 'u1',
        'email': 'patient@test.com',
        'role': 'PATIENT',
        'googleId': null,
        'googleEmail': null,
        'createdAt': null,
      });
      SharedPreferences.setMockInitialValues({
        'auth_token': 'bearer-token',
        'user_data': userJson,
      });
      authService = AuthService(
        settingsStorage: _FakeSettingsStorage(baseUrl: 'http://test.local'),
      );
      await authService.initialize();
    });

    test('returns MigraineApiResponse on HTTP 200', () async {
      final client = MockClient((_) async =>
          http.Response(jsonEncode(_successApiBody()), 200));
      final api = ApiClient(
        baseUrl: 'http://test.local',
        client: client,
        authService: authService,
      );

      final result = await api.submitMigraineAttack(_buildAttack());

      expect(result.predictedType, 'Migraine with aura');
      expect(result.summary, 'Moderate migraine with typical aura features.');
      expect(result.symptomsReceived, contains('Nausea'));
    });

    test('sends POST to /api/summary with correct JSON body', () async {
      http.Request? captured;
      final client = MockClient((req) async {
        captured = req;
        return http.Response(jsonEncode(_successApiBody()), 200);
      });
      final api = ApiClient(
        baseUrl: 'http://test.local',
        client: client,
        authService: authService,
      );

      await api.submitMigraineAttack(_buildAttack(patientId: 'pp-1'));

      expect(captured!.url.path, '/api/summary');
      expect(captured!.method, 'POST');
      final body = jsonDecode(captured!.body) as Map<String, dynamic>;
      expect(body['Duration'], 4);
      expect(body['Intensity'], 7);
      expect(body['patient_id'], 'pp-1');
    });

    test('includes Authorization header when authenticated', () async {
      http.Request? captured;
      final client = MockClient((req) async {
        captured = req;
        return http.Response(jsonEncode(_successApiBody()), 200);
      });
      final api = ApiClient(
        baseUrl: 'http://test.local',
        client: client,
        authService: authService,
      );

      await api.submitMigraineAttack(_buildAttack());

      expect(captured!.headers['Authorization'], 'Bearer bearer-token');
    });

    test('throws HttpException on HTTP 400 (bad request)', () async {
      final client = MockClient((_) async =>
          http.Response('{"error":"Invalid payload"}', 400));
      final api = ApiClient(
        baseUrl: 'http://test.local',
        client: client,
        authService: authService,
      );

      expect(
        () => api.submitMigraineAttack(_buildAttack()),
        throwsA(isA<Exception>()),
      );
    });

    test('throws HttpException on HTTP 500 (server error)', () async {
      final client = MockClient((_) async =>
          http.Response('Internal Server Error', 500));
      final api = ApiClient(
        baseUrl: 'http://test.local',
        client: client,
        authService: authService,
      );

      expect(
        () => api.submitMigraineAttack(_buildAttack()),
        throwsA(isA<Exception>()),
      );
    });

    test('MigraineApiResponse.fromJson handles missing predicted_migraine_type', () {
      final response = MigraineApiResponse.fromJson({
        'summary': 'OK',
        'symptoms_received': [],
      });
      // Missing key defaults to 'Unknown'
      expect(response.predictedType, 'Unknown');
    });
  });
}
