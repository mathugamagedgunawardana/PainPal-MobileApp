import 'package:flutter_test/flutter_test.dart';
import 'package:painpal/data/auth_models.dart';

void main() {
  // ---------------------------------------------------------------------------
  // User model
  // ---------------------------------------------------------------------------
  group('User', () {
    final Map<String, dynamic> patientJson = {
      'id': 'user-1',
      'email': 'jane@example.com',
      'role': 'PATIENT',
      'googleId': null,
      'googleEmail': null,
      'createdAt': '2024-01-15T10:00:00.000Z',
    };

    test('fromJson parses a PATIENT correctly', () {
      final user = User.fromJson(patientJson);
      expect(user.id, 'user-1');
      expect(user.email, 'jane@example.com');
      expect(user.role, UserRole.patient);
      expect(user.createdAt, DateTime.parse('2024-01-15T10:00:00.000Z'));
    });

    test('fromJson parses a DOCTOR correctly', () {
      final user = User.fromJson({...patientJson, 'role': 'DOCTOR', 'id': 'doc-1'});
      expect(user.role, UserRole.doctor);
    });

    test('fromJson parses an ADMIN correctly', () {
      final user = User.fromJson({...patientJson, 'role': 'ADMIN', 'id': 'adm-1'});
      expect(user.role, UserRole.admin);
    });

    test('fromJson defaults unknown role to PATIENT', () {
      final user = User.fromJson({...patientJson, 'role': 'NURSE'});
      expect(user.role, UserRole.patient);
    });

    test('fromJson handles null createdAt', () {
      final user = User.fromJson({...patientJson, 'createdAt': null});
      expect(user.createdAt, isNull);
    });

    test('toJson round-trips to the same values', () {
      final user = User.fromJson(patientJson);
      final json = user.toJson();
      expect(json['id'], 'user-1');
      expect(json['email'], 'jane@example.com');
      expect(json['role'], 'PATIENT');
    });

    test('toJson encodes role as uppercase string', () {
      final doctorUser = User.fromJson({...patientJson, 'role': 'DOCTOR'});
      expect(doctorUser.toJson()['role'], 'DOCTOR');
    });
  });

  // ---------------------------------------------------------------------------
  // PatientProfile model
  // ---------------------------------------------------------------------------
  group('PatientProfile', () {
    final Map<String, dynamic> profileJson = {
      'id': 'pp-1',
      'userId': 'user-1',
      'name': 'Jane Doe',
      'dateOfBirth': '1995-05-10T00:00:00.000Z',
      'gender': 'female',
      'phone': '+1-555-0100',
      'email': 'jane@example.com',
      'address': '1 Main St',
      'condition': 'migraine-with-aura',
      'ehrRecordId': 'ehr-abc',
      'createdAt': '2024-01-15T10:00:00.000Z',
    };

    test('fromJson parses all fields', () {
      final profile = PatientProfile.fromJson(profileJson);
      expect(profile.id, 'pp-1');
      expect(profile.userId, 'user-1');
      expect(profile.name, 'Jane Doe');
      expect(profile.dateOfBirth, DateTime.parse('1995-05-10T00:00:00.000Z'));
      expect(profile.gender, 'female');
      expect(profile.phone, '+1-555-0100');
      expect(profile.condition, 'migraine-with-aura');
      expect(profile.ehrRecordId, 'ehr-abc');
    });

    test('fromJson accepts "dob" as an alias for "dateOfBirth"', () {
      final json = Map<String, dynamic>.from(profileJson)
        ..remove('dateOfBirth')
        ..['dob'] = '2000-06-15T00:00:00.000Z';
      final profile = PatientProfile.fromJson(json);
      expect(profile.dateOfBirth, DateTime.parse('2000-06-15T00:00:00.000Z'));
    });

    test('fromJson handles null optional fields', () {
      final sparse = {
        'id': 'pp-2',
        'userId': 'user-2',
        'name': 'No Extras',
        'dateOfBirth': '1990-01-01T00:00:00.000Z',
      };
      final profile = PatientProfile.fromJson(sparse);
      expect(profile.gender, isNull);
      expect(profile.phone, isNull);
      expect(profile.condition, isNull);
      expect(profile.ehrRecordId, isNull);
      expect(profile.createdAt, isNull);
    });

    test('toJson round-trips key fields', () {
      final profile = PatientProfile.fromJson(profileJson);
      final json = profile.toJson();
      expect(json['id'], 'pp-1');
      expect(json['name'], 'Jane Doe');
      expect(json['gender'], 'female');
    });
  });

  // ---------------------------------------------------------------------------
  // DoctorProfile model
  // ---------------------------------------------------------------------------
  group('DoctorProfile', () {
    final Map<String, dynamic> doctorJson = {
      'id': 'dp-1',
      'userId': 'user-doc-1',
      'name': 'Dr. Smith',
      'specialization': 'Neurology',
      'clinicId': 'clinic-xyz',
    };

    test('fromJson parses all fields', () {
      final profile = DoctorProfile.fromJson(doctorJson);
      expect(profile.id, 'dp-1');
      expect(profile.userId, 'user-doc-1');
      expect(profile.name, 'Dr. Smith');
      expect(profile.specialization, 'Neurology');
      expect(profile.clinicId, 'clinic-xyz');
    });

    test('toJson round-trips all fields', () {
      final profile = DoctorProfile.fromJson(doctorJson);
      final json = profile.toJson();
      expect(json['id'], 'dp-1');
      expect(json['name'], 'Dr. Smith');
      expect(json['specialization'], 'Neurology');
      expect(json['clinicId'], 'clinic-xyz');
    });
  });

  // ---------------------------------------------------------------------------
  // LoginRequest model
  // ---------------------------------------------------------------------------
  group('LoginRequest', () {
    test('toJson encodes email and password', () {
      final req = LoginRequest(email: 'a@b.com', password: 'secret');
      final json = req.toJson();
      expect(json['email'], 'a@b.com');
      expect(json['password'], 'secret');
    });
  });

  // ---------------------------------------------------------------------------
  // RegisterRequest model
  // ---------------------------------------------------------------------------
  group('RegisterRequest', () {
    test('toJson encodes role as uppercase string', () {
      final req = RegisterRequest(
        email: 'p@b.com',
        password: 'pw',
        role: UserRole.patient,
        name: 'Pat',
      );
      final json = req.toJson();
      expect(json['role'], 'PATIENT');
    });

    test('toJson encodes optional dateOfBirth as ISO string', () {
      final dob = DateTime(1990, 6, 15);
      final req = RegisterRequest(
        email: 'p@b.com',
        password: 'pw',
        role: UserRole.patient,
        dateOfBirth: dob,
      );
      final json = req.toJson();
      expect(json['dateOfBirth'], dob.toIso8601String());
    });

    test('toJson emits null when dateOfBirth is omitted', () {
      final req = RegisterRequest(email: 'p@b.com', password: 'pw', role: UserRole.doctor);
      final json = req.toJson();
      expect(json['dateOfBirth'], isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // LoginResponse model
  // ---------------------------------------------------------------------------
  group('LoginResponse', () {
    final Map<String, dynamic> responseJson = {
      'token': 'jwt-abc',
      'user': {
        'id': 'user-1',
        'email': 'jane@example.com',
        'role': 'PATIENT',
        'googleId': null,
        'googleEmail': null,
        'createdAt': null,
      },
      'patientProfile': {
        'id': 'pp-1',
        'userId': 'user-1',
        'name': 'Jane Doe',
        'dateOfBirth': '1995-05-10T00:00:00.000Z',
      },
    };

    test('fromJson parses token and user', () {
      final response = LoginResponse.fromJson(responseJson);
      expect(response.token, 'jwt-abc');
      expect(response.user.email, 'jane@example.com');
      expect(response.user.role, UserRole.patient);
    });

    test('fromJson parses patientProfile when present', () {
      final response = LoginResponse.fromJson(responseJson);
      expect(response.patientProfile, isNotNull);
      expect(response.patientProfile!.name, 'Jane Doe');
    });

    test('fromJson leaves patientProfile null when absent', () {
      final json = Map<String, dynamic>.from(responseJson)..remove('patientProfile');
      final response = LoginResponse.fromJson(json);
      expect(response.patientProfile, isNull);
    });

    test('fromJson parses doctorProfile when present', () {
      final json = {
        'token': 'doc-token',
        'user': {
          'id': 'doc-user-1',
          'email': 'dr@clinic.com',
          'role': 'DOCTOR',
          'googleId': null,
          'googleEmail': null,
          'createdAt': null,
        },
        'doctorProfile': {
          'id': 'dp-1',
          'userId': 'doc-user-1',
          'name': 'Dr. Smith',
          'specialization': 'Neurology',
          'clinicId': 'clinic-xyz',
        },
      };
      final response = LoginResponse.fromJson(json);
      expect(response.doctorProfile, isNotNull);
      expect(response.doctorProfile!.specialization, 'Neurology');
    });

    test('fromJson leaves doctorProfile null when absent', () {
      final response = LoginResponse.fromJson(responseJson);
      expect(response.doctorProfile, isNull);
    });
  });
}
