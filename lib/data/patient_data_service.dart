import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import 'auth_service.dart';
import 'backend_config.dart';
import 'models.dart';

/// Service for managing patient data including migraine events and MRI scans
class PatientDataService {
  PatientDataService({
    required AuthService authService,
    http.Client? client,
  })  : _authService = authService,
        _client = client ?? http.Client();

  final AuthService _authService;
  final http.Client _client;

  /// Submit a migraine event to the backend
  Future<MigraineApiResponse> submitMigraineEvent(
    MigraineAttack attack,
  ) async {
    if (!_authService.isAuthenticated) {
      throw Exception('User not authenticated');
    }

    final base = await _authService.resolveApiBaseUrl();
    final uri = Uri.parse('$base${BackendConfig.summaryEndpoint}');

    final payload = attack.toApiJson();

    // Add patient ID if available
    if (_authService.patientProfile != null) {
      payload['patient_id'] = _authService.patientProfile!.userId;
    }

    final response = await _client.post(
      uri,
      headers: _authService.getAuthHeaders(),
      body: jsonEncode(payload),
    ).timeout(BackendConfig.requestTimeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'Migraine submission failed (${response.statusCode}): ${response.body}',
      );
    }

    return MigraineApiResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  /// Submit an MRI scan to the backend
  Future<MriApiResponse> submitMriScan({
    required File image,
    String? patientId,
  }) async {
    if (!_authService.isAuthenticated) {
      throw Exception('User not authenticated');
    }

    final base = await _authService.resolveApiBaseUrl();
    final uri = Uri.parse('$base${BackendConfig.mriPredictEndpoint}');

    final request = http.MultipartRequest('POST', uri);

    // Add authorization header
    request.headers.addAll({
      'Authorization': 'Bearer ${_authService.authToken}',
    });

    // Add patient ID
    final finalPatientId = patientId ?? _authService.patientProfile?.userId;
    if (finalPatientId != null && finalPatientId.isNotEmpty) {
      request.fields['patient_id'] = finalPatientId;
    }

    request.files.add(await http.MultipartFile.fromPath('file', image.path));

    final streamed = await request.send().timeout(BackendConfig.requestTimeout);
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'MRI submission failed (${response.statusCode}): ${response.body}',
      );
    }

    return MriApiResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  /// Get migraine history for the current patient
  Future<List<MigraineEvent>> getMigraineHistory({
    int? limit,
    int? skip,
  }) async {
    if (!_authService.isAuthenticated) {
      throw Exception('User not authenticated');
    }

    final patientId = _authService.patientProfile?.id;
    if (patientId == null) {
      throw Exception('Patient profile not loaded');
    }

    final base = await _authService.resolveApiBaseUrl();
    final uri = Uri.parse(
      '$base${BackendConfig.migraineEventsEndpoint}?patientId=$patientId'
      '${limit != null ? '&limit=$limit' : ''}'
      '${skip != null ? '&skip=$skip' : ''}',
    );

    final response = await _client.get(
      uri,
      headers: _authService.getAuthHeaders(),
    ).timeout(BackendConfig.requestTimeout);

    if (response.statusCode != 200) {
      throw HttpException(
        'Failed to fetch migraine history (${response.statusCode})',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final events = (data['events'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return events.map((json) => MigraineEvent.fromJson(json)).toList();
  }

  /// Get MRI scan history for the current patient
  Future<List<MriScanData>> getMriHistory({
    int? limit,
    int? skip,
  }) async {
    if (!_authService.isAuthenticated) {
      throw Exception('User not authenticated');
    }

    final patientId = _authService.patientProfile?.id;
    if (patientId == null) {
      throw Exception('Patient profile not loaded');
    }

    final base = await _authService.resolveApiBaseUrl();
    final uri = Uri.parse(
      '$base${BackendConfig.mriScansEndpoint}?patientId=$patientId'
      '${limit != null ? '&limit=$limit' : ''}'
      '${skip != null ? '&skip=$skip' : ''}',
    );

    final response = await _client.get(
      uri,
      headers: _authService.getAuthHeaders(),
    ).timeout(BackendConfig.requestTimeout);

    if (response.statusCode != 200) {
      throw HttpException(
        'Failed to fetch MRI history (${response.statusCode})',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final scans = (data['scans'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return scans.map((json) => MriScanData.fromJson(json)).toList();
  }

  /// Get medication logs for the current patient
  Future<List<MedicationLogData>> getMedicationLogs({
    int? limit,
    int? skip,
  }) async {
    if (!_authService.isAuthenticated) {
      throw Exception('User not authenticated');
    }

    final patientId = _authService.patientProfile?.id;
    if (patientId == null) {
      throw Exception('Patient profile not loaded');
    }

    final base = await _authService.resolveApiBaseUrl();
    final uri = Uri.parse(
      '$base${BackendConfig.medicationLogsEndpoint}?patientId=$patientId'
      '${limit != null ? '&limit=$limit' : ''}'
      '${skip != null ? '&skip=$skip' : ''}',
    );

    final response = await _client.get(
      uri,
      headers: _authService.getAuthHeaders(),
    ).timeout(BackendConfig.requestTimeout);

    if (response.statusCode != 200) {
      throw HttpException(
        'Failed to fetch medication logs (${response.statusCode})',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final logs = (data['logs'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return logs.map((json) => MedicationLogData.fromJson(json)).toList();
  }
}

/// MongoDB MigraineEvent model based on Prisma schema
class MigraineEvent {
  MigraineEvent({
    required this.id,
    required this.patientId,
    required this.startDatetime,
    required this.severity,
    this.duration,
    this.symptomsLog,
    this.perceivedTriggers,
    this.medicationGroupId,
    this.effectiveness,
    this.createdAt,
  });

  final String id;
  final String patientId;
  final DateTime startDatetime;
  final int severity; // 1-10 scale
  final String? duration;
  final String? symptomsLog;
  final String? perceivedTriggers;
  final String? medicationGroupId;
  final String? effectiveness;
  final DateTime? createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'patientId': patientId,
        'startDatetime': startDatetime.toIso8601String(),
        'severity': severity,
        'duration': duration,
        'symptomsLog': symptomsLog,
        'perceivedTriggers': perceivedTriggers,
        'medicationGroupId': medicationGroupId,
        'effectiveness': effectiveness,
        'createdAt': createdAt?.toIso8601String(),
      };

  static MigraineEvent fromJson(Map<String, dynamic> json) {
    return MigraineEvent(
      id: json['id'] ?? json['_id'] ?? '',
      patientId: json['patientId'] ?? '',
      startDatetime: DateTime.tryParse(json['startDatetime'] ?? '') ?? DateTime.now(),
      severity: (json['severity'] as num?)?.toInt() ?? 0,
      duration: json['duration'],
      symptomsLog: json['symptomsLog'],
      perceivedTriggers: json['perceivedTriggers'],
      medicationGroupId: json['medicationGroupId'],
      effectiveness: json['effectiveness'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }
}

/// MongoDB MriScan model based on Prisma schema
class MriScanData {
  MriScanData({
    required this.id,
    required this.patientId,
    required this.imagePath,
    required this.prediction,
    required this.confidence,
    this.createdAt,
  });

  final String id;
  final String patientId;
  final String imagePath;
  final String prediction;
  final double confidence;
  final DateTime? createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'patientId': patientId,
        'imagePath': imagePath,
        'prediction': prediction,
        'confidence': confidence,
        'createdAt': createdAt?.toIso8601String(),
      };

  static MriScanData fromJson(Map<String, dynamic> json) {
    return MriScanData(
      id: json['id'] ?? json['_id'] ?? '',
      patientId: json['patientId'] ?? '',
      imagePath: json['imagePath'] ?? '',
      prediction: json['prediction'] ?? 'Pending',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }
}

/// MongoDB MedicationLog model based on Prisma schema
class MedicationLogData {
  MedicationLogData({
    required this.id,
    required this.patientId,
    required this.medicationName,
    required this.medicationType,
    required this.datetimeTaken,
    required this.dosage,
    this.medicationGroupId,
    this.frequency,
    this.adherenceRate,
    this.createdAt,
  });

  final String id;
  final String patientId;
  final String medicationName;
  final String medicationType;
  final DateTime datetimeTaken;
  final String dosage;
  final String? medicationGroupId;
  final String? frequency;
  final double? adherenceRate;
  final DateTime? createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'patientId': patientId,
        'medicationName': medicationName,
        'medicationType': medicationType,
        'datetimeTaken': datetimeTaken.toIso8601String(),
        'dosage': dosage,
        'medicationGroupId': medicationGroupId,
        'frequency': frequency,
        'adherenceRate': adherenceRate,
        'createdAt': createdAt?.toIso8601String(),
      };

  static MedicationLogData fromJson(Map<String, dynamic> json) {
    return MedicationLogData(
      id: json['id'] ?? json['_id'] ?? '',
      patientId: json['patientId'] ?? '',
      medicationName: json['medicationName'] ?? '',
      medicationType: json['medicationType'] ?? 'RESCUE',
      datetimeTaken: DateTime.tryParse(json['datetimeTaken'] ?? '') ?? DateTime.now(),
      dosage: json['dosage'] ?? '',
      medicationGroupId: json['medicationGroupId'],
      frequency: json['frequency'],
      adherenceRate: (json['adherenceRate'] as num?)?.toDouble(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }
}

