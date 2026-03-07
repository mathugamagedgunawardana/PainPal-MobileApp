import 'database.dart';
import 'models.dart';
import 'storage.dart';

/// Builds a text summary of the patient's recorded data for the AI chat context.
/// Uses local SQLite data; optionally filters by patient ID from settings.
class PatientChatContext {
  PatientChatContext({
    required PainpalDatabase database,
    required SettingsStorage storage,
  })  : _database = database,
        _storage = storage;

  final PainpalDatabase _database;
  final SettingsStorage _storage;

  static const int _maxAttacks = 20;
  static const int _maxMriScans = 10;

  /// Builds a plain-text summary of this patient's migraine attacks and MRI scans
  /// for inclusion in the AI prompt. Returns empty string if no data.
  Future<String> buildContext() async {
    final patientId = await _storage.readPatientId();
    final attacks = await _database.fetchMigraineAttacks();
    final scans = await _database.fetchMriScans();

    final filteredAttacks = _filterByPatientId(attacks, patientId);
    final filteredScans = _filterByPatientIdScans(scans, patientId);

    final recentAttacks = filteredAttacks.take(_maxAttacks).toList();
    final recentScans = filteredScans.take(_maxMriScans).toList();

    final parts = <String>[];

    if (recentAttacks.isNotEmpty) {
      parts.add(_formatAttacks(recentAttacks));
    }
    if (recentScans.isNotEmpty) {
      parts.add(_formatMriScans(recentScans));
    }

    if (parts.isEmpty) {
      return '';
    }
    return parts.join('\n\n');
  }

  List<MigraineAttack> _filterByPatientId(
    List<MigraineAttack> list,
    String? patientId,
  ) {
    if (patientId == null || patientId.isEmpty) {
      return list;
    }
    return list
        .where((a) =>
            a.patientId == null ||
            a.patientId!.isEmpty ||
            a.patientId == patientId)
        .toList();
  }

  List<MriScan> _filterByPatientIdScans(List<MriScan> list, String? patientId) {
    if (patientId == null || patientId.isEmpty) {
      return list;
    }
    return list
        .where((s) =>
            s.patientId == null ||
            s.patientId!.isEmpty ||
            s.patientId == patientId)
        .toList();
  }

  String _formatAttacks(List<MigraineAttack> attacks) {
    final lines = <String>['Migraine attacks (most recent first):'];
    for (var i = 0; i < attacks.length; i++) {
      final a = attacks[i];
      final date = a.timestamp != null
          ? a.timestamp!.toIso8601String().split('T').first
          : 'no date';
      final symptoms = <String>[];
      if (a.nausea == 1) symptoms.add('nausea');
      if (a.vomit == 1) symptoms.add('vomit');
      if (a.photophobia == 1) symptoms.add('photophobia');
      if (a.phonophobia == 1) symptoms.add('phonophobia');
      if (a.visual == 1) symptoms.add('visual disturbances');
      if (a.vertigo == 1) symptoms.add('vertigo');
      final symptomStr =
          symptoms.isEmpty ? 'none listed' : symptoms.join(', ');
      lines.add(
        '${i + 1}. $date: intensity ${a.intensity}/10, duration ${a.durationHours}h, '
        'location ${a.location}, character ${a.character}. '
        'Symptoms: $symptomStr. '
        '${a.type != null && a.type!.isNotEmpty ? "Type: ${a.type}." : ""} '
        '${a.summary != null && a.summary!.isNotEmpty ? "Summary: ${a.summary}" : ""}',
      );
    }
    return lines.join('\n');
  }

  String _formatMriScans(List<MriScan> scans) {
    final lines = <String>['MRI scan results (most recent first):'];
    for (var i = 0; i < scans.length; i++) {
      final s = scans[i];
      final date = s.timestamp.toIso8601String().split('T').first;
      final conf = s.confidence != null ? (s.confidence! * 100).round() : null;
      lines.add(
        '${i + 1}. $date: prediction ${s.prediction}'
        '${conf != null ? ", confidence $conf%" : ""}.',
      );
    }
    return lines.join('\n');
  }
}
