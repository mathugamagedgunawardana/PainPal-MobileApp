import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import 'database.dart';
import 'models.dart';

/// Generates PDF reports for migraine history (weekly, monthly, custom).
class ReportGenerator {
  ReportGenerator({PainpalDatabase? database})
      : _database = database ?? PainpalDatabase.instance;

  final PainpalDatabase _database;

  Future<File> generateReport({
    required DateTime start,
    required DateTime end,
    required String title,
  }) async {
    final attacks = await _database.fetchMigraineAttacks();
    final inRange = attacks.where((a) {
      final t = a.timestamp;
      if (t == null) return false;
      return !t.isBefore(start) && !t.isAfter(end.add(const Duration(days: 1)));
    }).toList();

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'Period: ${DateFormat('MMM d, y').format(start)} – ${DateFormat('MMM d, y').format(end)}',
            style: const pw.TextStyle(fontSize: 12),
          ),
          pw.SizedBox(height: 16),
          _section('Summary', [
            pw.Text('Total attacks: ${inRange.length}'),
            if (inRange.isNotEmpty) ...[
              pw.Text(
                'Average intensity: ${(inRange.map((a) => a.intensity).reduce((a, b) => a + b) / inRange.length).toStringAsFixed(1)}/10',
              ),
              pw.Text(
                'Average duration: ${(inRange.map((a) => a.durationHours).reduce((a, b) => a + b) / inRange.length).toStringAsFixed(1)} hours',
              ),
            ],
          ]),
          _section('Trigger frequency', _triggerList(inRange)),
          _section('Medication usage', _medicationList(inRange)),
          _section('Symptom trends', _symptomList(inRange)),
          if (inRange.isNotEmpty)
            _section('Attacks', inRange.map((a) => _attackLine(a)).toList()),
        ],
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final name = 'PainPal_Report_${DateFormat('yyyyMMdd').format(start)}_${DateFormat('yyyyMMdd').format(end)}.pdf';
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  pw.Widget _section(String title, List<pw.Widget> children) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 16),
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        ...children,
      ],
    );
  }

  List<pw.Widget> _triggerList(List<MigraineAttack> attacks) {
    final map = <String, int>{};
    for (final a in attacks) {
      for (final t in a.triggers) {
        if (t.isNotEmpty) map[t] = (map[t] ?? 0) + 1;
      }
    }
    if (map.isEmpty) return [pw.Text('No trigger data')];
    final sorted = map.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(15).map((e) => pw.Text('• ${e.key}: ${e.value}')).toList();
  }

  List<pw.Widget> _medicationList(List<MigraineAttack> attacks) {
    final map = <String, List<int>>{};
    for (final a in attacks) {
      for (final m in a.medications) {
        if (m.name.isEmpty) continue;
        map.putIfAbsent(m.name, () => []);
        map[m.name]!.add(m.effectiveness);
      }
    }
    if (map.isEmpty) return [pw.Text('No medication data')];
    return map.entries.map((e) {
      final avg = e.value.isEmpty ? 0.0 : e.value.reduce((a, b) => a + b) / e.value.length;
      return pw.Text('• ${e.key}: used ${e.value.length}x, avg effectiveness ${avg.toStringAsFixed(1)}/5');
    }).toList();
  }

  List<pw.Widget> _symptomList(List<MigraineAttack> attacks) {
    final map = <String, int>{};
    for (final a in attacks) {
      if (a.nausea == 1) map['Nausea'] = (map['Nausea'] ?? 0) + 1;
      if (a.photophobia == 1) map['Photophobia'] = (map['Photophobia'] ?? 0) + 1;
      if (a.phonophobia == 1) map['Phonophobia'] = (map['Phonophobia'] ?? 0) + 1;
      if (a.vertigo == 1) map['Vertigo'] = (map['Vertigo'] ?? 0) + 1;
    }
    if (map.isEmpty) return [pw.Text('No symptom data')];
    final sorted = map.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.map((e) => pw.Text('• ${e.key}: ${e.value} attacks')).toList();
  }

  pw.Widget _attackLine(MigraineAttack a) {
    final date = a.timestamp != null ? DateFormat('MMM d, y').format(a.timestamp!) : '-';
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Text(
        '$date – Intensity ${a.intensity}/10, ${a.durationHours}h, ${a.location}'
        '${a.triggers.isNotEmpty ? ", triggers: ${a.triggers.join(", ")}" : ""}',
        style: const pw.TextStyle(fontSize: 10),
      ),
    );
  }

  /// Share the report file via platform share sheet.
  Future<void> shareReport(File file) async {
    await Share.shareXFiles([XFile(file.path)], text: 'PainPal Migraine Report');
  }
}
