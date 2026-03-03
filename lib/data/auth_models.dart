import 'dart:convert' as convert;

/// User authentication model based on Prisma schema
class User {
  User({
    required this.id,
    required this.email,
    this.role = UserRole.patient,
    this.googleId,
    this.googleEmail,
    this.createdAt,
  });

  final String id;
  final String email;
  final UserRole role;
  final String? googleId;
  final String? googleEmail;
  final DateTime? createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'role': role.toString().split('.').last.toUpperCase(),
        'googleId': googleId,
        'googleEmail': googleEmail,
        'createdAt': createdAt?.toIso8601String(),
      };

  static User fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      role: _parseRole(json['role']),
      googleId: json['googleId'],
      googleEmail: json['googleEmail'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }
}

enum UserRole { admin, patient, doctor }

UserRole _parseRole(String? role) {
  switch (role?.toUpperCase()) {
    case 'ADMIN':
      return UserRole.admin;
    case 'DOCTOR':
      return UserRole.doctor;
    default:
      return UserRole.patient;
  }
}

/// Patient profile model based on Prisma schema
class PatientProfile {
  PatientProfile({
    required this.id,
    required this.userId,
    required this.name,
    required this.dateOfBirth,
    this.gender,
    this.phone,
    this.email,
    this.address,
    this.condition,
    this.ehrRecordId,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String name;
  final DateTime dateOfBirth;
  final String? gender;
  final String? phone;
  final String? email;
  final String? address;
  final String? condition;
  final String? ehrRecordId;
  final DateTime? createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'name': name,
        'dateOfBirth': dateOfBirth.toIso8601String(),
        'gender': gender,
        'phone': phone,
        'email': email,
        'address': address,
        'condition': condition,
        'ehrRecordId': ehrRecordId,
        'createdAt': createdAt?.toIso8601String(),
      };

  static PatientProfile fromJson(Map<String, dynamic> json) {
    return PatientProfile(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      dateOfBirth: DateTime.parse(json['dateOfBirth'] as String),
      gender: json['gender'],
      phone: json['phone'],
      email: json['email'],
      address: json['address'],
      condition: json['condition'],
      ehrRecordId: json['ehrRecordId'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }
}

/// Doctor profile model based on Prisma schema
class DoctorProfile {
  DoctorProfile({
    required this.id,
    required this.userId,
    required this.name,
    required this.specialization,
    required this.clinicId,
  });

  final String id;
  final String userId;
  final String name;
  final String specialization;
  final String clinicId;

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'name': name,
        'specialization': specialization,
        'clinicId': clinicId,
      };

  static DoctorProfile fromJson(Map<String, dynamic> json) {
    return DoctorProfile(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      specialization: json['specialization'] as String,
      clinicId: json['clinicId'] as String,
    );
  }
}

/// Authentication request/response models
class LoginRequest {
  LoginRequest({required this.email, required this.password});

  final String email;
  final String password;

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
      };
}

class LoginResponse {
  LoginResponse({
    required this.user,
    required this.token,
    this.patientProfile,
    this.doctorProfile,
  });

  final User user;
  final String token;
  final PatientProfile? patientProfile;
  final DoctorProfile? doctorProfile;

  static LoginResponse fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      user: User.fromJson(json['user']),
      token: json['token'] as String,
      patientProfile: json['patientProfile'] != null
          ? PatientProfile.fromJson(json['patientProfile'])
          : null,
      doctorProfile: json['doctorProfile'] != null
          ? DoctorProfile.fromJson(json['doctorProfile'])
          : null,
    );
  }
}

class RegisterRequest {
  RegisterRequest({
    required this.email,
    required this.password,
    required this.role,
    this.name,
    this.dateOfBirth,
    this.googleId,
  });

  final String email;
  final String password;
  final UserRole role;
  final String? name;
  final DateTime? dateOfBirth;
  final String? googleId;

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
        'role': role.toString().split('.').last.toUpperCase(),
        'name': name,
        'dateOfBirth': dateOfBirth?.toIso8601String(),
        'googleId': googleId,
      };
}

