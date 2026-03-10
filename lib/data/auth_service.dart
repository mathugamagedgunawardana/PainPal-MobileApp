import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_models.dart';
import 'backend_config.dart';
import 'environment.dart';

/// Authentication service for handling user login, registration, and token management.
/// Uses the backend API (configured in Settings → Base URL); the backend connects to MongoDB Atlas.
class AuthService {
  AuthService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  static const String _patientProfileKey = 'patient_profile';
  static const String _doctorProfileKey = 'doctor_profile';
  static const String _baseUrlKey = 'base_url';

  /// Current authenticated user
  User? _currentUser;
  String? _authToken;
  PatientProfile? _currentPatientProfile;
  DoctorProfile? _currentDoctorProfile;

  /// Getters
  User? get currentUser => _currentUser;
  String? get authToken => _authToken;
  bool get isAuthenticated => _authToken != null && _currentUser != null;
  PatientProfile? get patientProfile => _currentPatientProfile;
  DoctorProfile? get doctorProfile => _currentDoctorProfile;

  /// Initialize auth service by loading saved credentials
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString(_tokenKey);

    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      _currentUser = User.fromJson(jsonDecode(userJson));
    }

    final patientJson = prefs.getString(_patientProfileKey);
    if (patientJson != null) {
      _currentPatientProfile = PatientProfile.fromJson(jsonDecode(patientJson));
    }

    final doctorJson = prefs.getString(_doctorProfileKey);
    if (doctorJson != null) {
      _currentDoctorProfile = DoctorProfile.fromJson(jsonDecode(doctorJson));
    }
  }

  /// Resolves the backend base URL (from Settings or default). Use this for API calls.
  Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_baseUrlKey);
    if (stored != null && stored.trim().isNotEmpty) return stored.trim();
    return Environment.getApiBaseUrl();
  }

  /// Login with email and password
  Future<LoginResponse> login(String email, String password) async {
    final baseUrl = await getBaseUrl();
    final uri = Uri.parse('$baseUrl${BackendConfig.loginEndpoint}');

    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(LoginRequest(email: email, password: password).toJson()),
    ).timeout(BackendConfig.requestTimeout);

    if (response.statusCode != 200) {
      throw AuthException(
        'Login failed with status ${response.statusCode}',
        response.body,
      );
    }

    final loginResponse = LoginResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );

    await _saveCredentials(loginResponse);
    return loginResponse;
  }

  /// Register a new user
  Future<LoginResponse> register({
    required String email,
    required String password,
    required UserRole role,
    String? name,
    DateTime? dateOfBirth,
  }) async {
    final baseUrl = await getBaseUrl();
    final uri = Uri.parse('$baseUrl${BackendConfig.registerEndpoint}');

    final request = RegisterRequest(
      email: email,
      password: password,
      role: role,
      name: name,
      dateOfBirth: dateOfBirth,
    );

    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    ).timeout(BackendConfig.requestTimeout);

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw AuthException(
        'Registration failed with status ${response.statusCode}',
        response.body,
      );
    }

    final loginResponse = LoginResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );

    await _saveCredentials(loginResponse);
    return loginResponse;
  }

  /// Refresh authentication token
  Future<String> refreshToken() async {
    if (_authToken == null) {
      throw AuthException('No token available to refresh', '');
    }

    final baseUrl = await getBaseUrl();
    final uri = Uri.parse('$baseUrl${BackendConfig.refreshTokenEndpoint}');

    final response = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_authToken',
      },
    ).timeout(BackendConfig.requestTimeout);

    if (response.statusCode != 200) {
      throw AuthException(
        'Token refresh failed with status ${response.statusCode}',
        response.body,
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final newToken = data['token'] as String;

    _authToken = newToken;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, newToken);

    return newToken;
  }

  /// Logout and clear stored credentials
  Future<void> logout() async {
    _currentUser = null;
    _authToken = null;
    _currentPatientProfile = null;
    _currentDoctorProfile = null;

    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(_tokenKey),
      prefs.remove(_userKey),
      prefs.remove(_patientProfileKey),
      prefs.remove(_doctorProfileKey),
    ]);
  }

  /// Get authorization header for API requests
  Map<String, String> getAuthHeaders() {
    return {
      'Content-Type': 'application/json',
      if (_authToken != null) 'Authorization': 'Bearer $_authToken',
    };
  }

  /// Save credentials to local storage and memory
  Future<void> _saveCredentials(LoginResponse response) async {
    _currentUser = response.user;
    _authToken = response.token;
    _currentPatientProfile = response.patientProfile;
    _currentDoctorProfile = response.doctorProfile;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, response.token);
    await prefs.setString(_userKey, jsonEncode(response.user.toJson()));

    if (response.patientProfile != null) {
      await prefs.setString(
        _patientProfileKey,
        jsonEncode(response.patientProfile!.toJson()),
      );
    }

    if (response.doctorProfile != null) {
      await prefs.setString(
        _doctorProfileKey,
        jsonEncode(response.doctorProfile!.toJson()),
      );
    }
  }
}

/// Custom exception for authentication errors
class AuthException implements Exception {
  AuthException(this.message, this.responseBody);

  final String message;
  final String responseBody;

  @override
  String toString() => 'AuthException: $message\nResponse: $responseBody';
}

