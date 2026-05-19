import 'package:intl/intl.dart';

import '../data/auth_models.dart';
import '../data/database.dart';
import '../data/models.dart';
import '../data/patient_analytics_api.dart';
import '../data/patient_full_ai_context_api.dart';
import '../data/patient_remote_api.dart';
import '../data/storage.dart';
import '../services/app_services.dart';

/// Builds a text block for Gemini [systemInstruction] from clinic DB export + local DB.
class PatientAiContextBuilder {
  static const int _maxChars = 100000;

  static Future<String?> build() async {
    final auth = AppServices.auth;
    if (!auth.isAuthenticated || auth.currentUser?.role != UserRole.patient) {
      return null;
    }

    final allowHealthInAi = await SettingsStorage().readAiUseHealthData();
    if (!allowHealthInAi) {
      return 'The patient has turned off sharing detailed health records with the AI assistant '
          'in Settings. Provide general migraine education, coping strategies, and lifestyle '
          'guidance only. Do not claim to see their attack log, MRI results, medications, or '
          'clinic analytics. If they ask about their own data, explain they can turn sharing '
          'back on under Settings → Privacy.';
    }

    final lines = <String>[];
    final token = auth.authToken;
    var usedServerExport = false;

    if (token != null && token.isNotEmpty) {
      try {
        final base = await auth.resolveApiBaseUrl();
        final export = await fetchPatientAiContextExport(
          baseUrl: base,
          bearerToken: token,
        );
        if (export != null && export.isNotEmpty) {
          lines.add(
            '=== Clinic database export (patient-scoped; medications, attacks, appointments, '
            'MRI metadata, doctor summaries, insights, clinical notes, communications, chat) ===',
          );
          lines.add(export);
          usedServerExport = true;
        }
      } catch (_) {
        // fall through to legacy enrichment
      }
    }

    if (!usedServerExport) {
      final p = auth.patientProfile;
      if (p != null) {
        lines.add('Patient display name: ${p.name}');
        lines.add('Date of birth: ${DateFormat.yMMMMd().format(p.dateOfBirth.toLocal())}');
        if (p.condition != null && p.condition!.trim().isNotEmpty) {
          lines.add('Recorded condition: ${p.condition!.trim()}');
        }
        if (p.phone != null && p.phone!.trim().isNotEmpty) {
          lines.add('Phone on file: ${p.phone}');
        }
      }

      final db = PainpalDatabase.instance;
      final localAttacks = await db.fetchMigraineAttacks();
      localAttacks.sort((a, b) {
        final ta = a.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
        final tb = b.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
        return tb.compareTo(ta);
      });

      final merged = List<MigraineAttack>.from(localAttacks);
      if (token != null && token.isNotEmpty) {
        try {
          final base = await auth.resolveApiBaseUrl();
          final remote = await fetchPatientMigraineEvents(
            baseUrl: base,
            bearerToken: token,
          );
          final ids = remote.map((e) => e.attackId).whereType<String>().toSet();
          final onlyLocal = localAttacks.where((l) {
            final id = l.attackId;
            if (id == null) {
              return true;
            }
            return !ids.contains(id);
          });
          merged
            ..clear()
            ..addAll(remote)
            ..addAll(onlyLocal);
          merged.sort((a, b) {
            final ta = a.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
            final tb = b.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
            return tb.compareTo(ta);
          });
        } catch (_) {
          // keep local only
        }
      }

      lines.add('--- Recent migraine logs (newest first; intensity 1–10) ---');
      if (merged.isEmpty) {
        lines.add('No logged attacks in local + synced records.');
      } else {
        final n = merged.length > 12 ? 12 : merged.length;
        for (var i = 0; i < n; i++) {
          final a = merged[i];
          final ts = a.timestamp != null
              ? DateFormat.yMMMd().add_jm().format(a.timestamp!.toLocal())
              : 'unknown date';
          lines.add(
            '- $ts: intensity ${a.intensity}, duration ${a.durationHours}h, location ${a.location}, character ${a.character}',
          );
        }
        if (merged.length > n) {
          lines.add('(${merged.length - n} older entries omitted)');
        }
      }

      if (token != null && token.isNotEmpty) {
        try {
          final base = await auth.resolveApiBaseUrl();
          final analytics = await fetchPatientAnalytics(
            baseUrl: base,
            bearerToken: token,
          );
          lines.add('--- Clinic analytics snapshot ---');
          lines.add(
            'Episodes last 30 days: ${analytics.episodesLast30Days}; avg severity: ${analytics.avgSeverity.toStringAsFixed(1)}; total episodes in window: ${analytics.totalEpisodes}',
          );
          final na = analytics.nextAttack;
          if (na != null) {
            lines.add(
              'Forecast hint: ${na.predictedTypeDisplay} (based on ${na.basedOnRecords} records)',
            );
          }
          final summary = await fetchPatientAiSummary(
            baseUrl: base,
            bearerToken: token,
          );
          if (summary != null && summary.combinedParagraphs.isNotEmpty) {
            final clip = summary.combinedParagraphs.length > 1800
                ? '${summary.combinedParagraphs.substring(0, 1800)}…'
                : summary.combinedParagraphs;
            lines.add('--- Clinic AI summary (excerpt) ---');
            lines.add(clip);
          }
        } catch (_) {
          lines.add('(Remote analytics summary unavailable.)');
        }
      }
    }

    final db = PainpalDatabase.instance;
    final mris = await db.fetchMriScans();
    lines.add('--- On-device MRI analyses (SQLite; may overlap server patientMriScans) ---');
    if (mris.isEmpty) {
      lines.add('None stored on device.');
    } else {
      for (var i = 0; i < mris.length && i < 24; i++) {
        final m = mris[i];
        final ts = DateFormat.yMMMd().format(m.timestamp.toLocal());
        lines.add(
          '- $ts: prediction ${m.prediction}, confidence ${m.confidence?.toStringAsFixed(0) ?? '—'}%',
        );
      }
      if (mris.length > 24) {
        lines.add('(${mris.length - 24} more on device)');
      }
    }

    var text = lines.join('\n');
    if (text.length > _maxChars) {
      text = '${text.substring(0, _maxChars)}\n…(truncated)';
    }
    return text;
  }
}
