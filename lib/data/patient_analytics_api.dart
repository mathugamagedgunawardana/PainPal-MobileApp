import 'dart:convert';

import 'package:http/http.dart' as http;

import 'backend_config.dart';

class NextAttackTypeOption {
  const NextAttackTypeOption({required this.label, required this.probability});

  final String label;
  final double probability;

  static NextAttackTypeOption? fromJson(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    final label = raw['label'] as String?;
    final prob = (raw['probability'] as num?)?.toDouble();
    if (label == null || label.isEmpty || prob == null) return null;
    return NextAttackTypeOption(label: label, probability: prob);
  }

  String get labelDisplay {
    return label
        .split('_')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }
}

/// Forecast for the next migraine attack from `GET /api/patient/analytics`.
class PatientNextAttackData {
  const PatientNextAttackData({
    required this.basedOnRecords,
    required this.predictedType,
    this.duration,
    this.frequency,
    this.intensity,
    this.symptomsLikely = const [],
    this.topTypes = const [],
    this.confidenceTier,
    this.typeConfidencePercent,
    this.usedHistoryFallback = false,
    this.modelPredictedType,
    this.displayDisclaimer,
    this.confidenceCaption,
  });

  final int basedOnRecords;
  final String predictedType;
  final double? duration;
  final double? frequency;
  final double? intensity;
  final List<NextAttackSymptom> symptomsLikely;
  final List<NextAttackTypeOption> topTypes;
  final String? confidenceTier;
  final int? typeConfidencePercent;
  final bool usedHistoryFallback;
  final String? modelPredictedType;
  final String? displayDisclaimer;
  final String? confidenceCaption;

  static PatientNextAttackData? fromJson(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    final type = raw['predictedType'] as String?;
    if (type == null || type.isEmpty) return null;
    final symRaw = raw['symptomsLikely'] as List? ?? [];
    final topRaw = raw['topTypes'] as List? ?? [];
    return PatientNextAttackData(
      basedOnRecords: (raw['basedOnRecords'] as num?)?.toInt() ?? 0,
      predictedType: type,
      duration: (raw['duration'] as num?)?.toDouble(),
      frequency: (raw['frequency'] as num?)?.toDouble(),
      intensity: (raw['intensity'] as num?)?.toDouble(),
      symptomsLikely: symRaw
          .map((e) => NextAttackSymptom.fromJson(e as Map<String, dynamic>))
          .toList(),
      topTypes: topRaw
          .map(NextAttackTypeOption.fromJson)
          .whereType<NextAttackTypeOption>()
          .toList(),
      confidenceTier: raw['confidenceTier'] as String?,
      typeConfidencePercent: (raw['typeConfidencePercent'] as num?)?.toInt(),
      usedHistoryFallback: raw['usedHistoryFallback'] as bool? ?? false,
      modelPredictedType: raw['modelPredictedType'] as String?,
      displayDisclaimer: raw['displayDisclaimer'] as String?,
      confidenceCaption: raw['confidenceCaption'] as String?,
    );
  }

  String get predictedTypeDisplay {
    if (predictedType.isEmpty) return '—';
    return predictedType
        .split('_')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }
}

class NextAttackSymptom {
  const NextAttackSymptom({required this.name, this.probability});

  final String name;
  final double? probability;

  static NextAttackSymptom fromJson(Map<String, dynamic> json) {
    return NextAttackSymptom(
      name: json['name'] as String? ?? '',
      probability: (json['probability'] as num?)?.toDouble(),
    );
  }
}

/// Response from Next.js `GET /api/patient/analytics` (MongoDB / Prisma).
class PatientAnalyticsData {
  const PatientAnalyticsData({
    required this.episodesLast30Days,
    required this.migraineDaysThisMonth,
    required this.avgSeverity,
    this.adherencePercent,
    required this.episodesByWeek,
    required this.totalEpisodes,
    required this.triggers,
    required this.severityDistribution,
    this.nextAttack,
    this.nextAttackUnavailableReason,
    this.nextAttackDisclaimer,
  });

  final int episodesLast30Days;
  final int migraineDaysThisMonth;
  final double avgSeverity;
  final int? adherencePercent;
  final List<EpisodeWeek> episodesByWeek;
  final int totalEpisodes;
  final List<TriggerCount> triggers;
  final List<SeverityBucket> severityDistribution;
  final PatientNextAttackData? nextAttack;
  final String? nextAttackUnavailableReason;
  final String? nextAttackDisclaimer;

  static PatientAnalyticsData fromJson(Map<String, dynamic> json) {
    final summary = json['summary'] as Map<String, dynamic>? ?? {};
    final weekRaw = json['episodesByWeek'] as List? ?? [];
    final trigRaw = json['triggers'] as List? ?? [];
    final sevRaw = json['severityDistribution'] as List? ?? [];

    return PatientAnalyticsData(
      episodesLast30Days: (summary['episodesLast30Days'] as num?)?.toInt() ?? 0,
      migraineDaysThisMonth: (summary['migraineDaysThisMonth'] as num?)?.toInt() ?? 0,
      avgSeverity: (summary['avgSeverity'] as num?)?.toDouble() ?? 0,
      adherencePercent: (summary['adherencePercent'] as num?)?.toInt(),
      episodesByWeek: weekRaw
          .map((e) => EpisodeWeek.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalEpisodes: (json['totalEpisodes'] as num?)?.toInt() ?? 0,
      triggers: trigRaw
          .map((e) => TriggerCount.fromJson(e as Map<String, dynamic>))
          .toList(),
      severityDistribution: sevRaw
          .map((e) => SeverityBucket.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextAttack: PatientNextAttackData.fromJson(json['nextAttack']),
      nextAttackUnavailableReason: json['nextAttackUnavailableReason'] as String?,
      nextAttackDisclaimer: json['nextAttackDisclaimer'] as String?,
    );
  }
}

class SeverityBucket {
  const SeverityBucket({required this.level, required this.count});

  final int level;
  final int count;

  static SeverityBucket fromJson(Map<String, dynamic> json) {
    return SeverityBucket(
      level: (json['level'] as num?)?.toInt() ?? 0,
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

class EpisodeWeek {
  const EpisodeWeek({required this.label, required this.count, this.fullLabel});

  final String label;
  final int count;
  final String? fullLabel;

  static EpisodeWeek fromJson(Map<String, dynamic> json) {
    return EpisodeWeek(
      label: json['label'] as String? ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
      fullLabel: json['fullLabel'] as String?,
    );
  }
}

class TriggerCount {
  const TriggerCount({required this.name, required this.count});

  final String name;
  final int count;

  static TriggerCount fromJson(Map<String, dynamic> json) {
    return TriggerCount(
      name: json['name'] as String? ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Narrative summary from `GET /api/patient/ai-summary` (optional companion to analytics).
class PatientAiSummaryPayload {
  const PatientAiSummaryPayload({
    required this.structuredSummaryText,
    required this.treatmentOutcomeAnalysis,
    this.generatedDate,
  });

  final String structuredSummaryText;
  final String treatmentOutcomeAnalysis;
  final String? generatedDate;

  String get combinedParagraphs => [
        if (structuredSummaryText.trim().isNotEmpty) structuredSummaryText.trim(),
        if (treatmentOutcomeAnalysis.trim().isNotEmpty) treatmentOutcomeAnalysis.trim(),
      ].join('\n\n');

  static PatientAiSummaryPayload? fromSummaryJson(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    final s = raw['structuredSummaryText'] as String? ?? '';
    final t = raw['treatmentOutcomeAnalysis'] as String? ?? '';
    if (s.trim().isEmpty && t.trim().isEmpty) return null;
    return PatientAiSummaryPayload(
      structuredSummaryText: s,
      treatmentOutcomeAnalysis: t,
      generatedDate: raw['generatedDate'] as String?,
    );
  }
}

/// Fetches the latest stored AI summary (GET).
Future<PatientAiSummaryPayload?> fetchPatientAiSummary({
  required String baseUrl,
  required String bearerToken,
  http.Client? client,
}) async {
  final c = client ?? http.Client();
  final root = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
  final uri = Uri.parse('$root${BackendConfig.patientAiSummaryEndpoint}');

  final response = await c
      .get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $bearerToken',
        },
      )
      .timeout(BackendConfig.requestTimeout);

  if (response.statusCode == 401 || response.statusCode == 403) {
    throw Exception(
      'Not authorized for patient AI summary (${response.statusCode}).',
    );
  }
  if (response.statusCode != 200) {
    throw Exception(
      'AI summary request failed (${response.statusCode}): ${response.body}',
    );
  }

  final map = jsonDecode(response.body) as Map<String, dynamic>;
  return PatientAiSummaryPayload.fromSummaryJson(map['summary']);
}

/// Fetches analytics stored in MongoDB through the Next.js API.
Future<PatientAnalyticsData> fetchPatientAnalytics({
  required String baseUrl,
  required String bearerToken,
  http.Client? client,
}) async {
  final c = client ?? http.Client();
  final root = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
  final uri = Uri.parse('$root${BackendConfig.patientAnalyticsEndpoint}');

  final response = await c
      .get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $bearerToken',
        },
      )
      .timeout(BackendConfig.requestTimeout);

  if (response.statusCode == 401 || response.statusCode == 403) {
    throw Exception(
      'Not authorized for patient analytics (${response.statusCode}). '
      'Use a PATIENT account with a PatientProfile in MongoDB.',
    );
  }
  if (response.statusCode != 200) {
    throw Exception(
      'Analytics request failed (${response.statusCode}): ${response.body}',
    );
  }

  final map = jsonDecode(response.body) as Map<String, dynamic>;
  return PatientAnalyticsData.fromJson(map);
}
