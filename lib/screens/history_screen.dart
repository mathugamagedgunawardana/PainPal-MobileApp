import 'dart:io';

import 'package:flutter/material.dart';

import '../data/database.dart';
import '../data/models.dart';
import '../data/report_generator.dart';
import '../widgets/app_illustrations.dart';
import '../widgets/custom_widgets.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _database = PainpalDatabase.instance;
  final _reportGenerator = ReportGenerator();

  late Future<List<MigraineAttack>> _migraineFuture;
  late Future<List<MriScan>> _mriFuture;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _migraineFuture = _database.fetchMigraineAttacks();
    _mriFuture = _database.fetchMriScans();
  }

  Future<void> _exportReport(String range) async {
    if (_exporting) return;
    setState(() => _exporting = true);
    final now = DateTime.now();
    DateTime start;
    DateTime end = now;
    String title;
    switch (range) {
      case 'weekly':
        start = now.subtract(const Duration(days: 7));
        title = 'Weekly Migraine Report';
        break;
      case 'monthly':
        start = DateTime(now.year, now.month - 1, now.day);
        title = 'Monthly Migraine Report';
        break;
      case 'custom':
        final picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: now,
          initialDateRange: DateTimeRange(
            start: now.subtract(const Duration(days: 30)),
            end: now,
          ),
        );
        if (picked == null) {
          setState(() => _exporting = false);
          return;
        }
        start = picked.start;
        end = picked.end;
        title = 'Custom Migraine Report';
        break;
      default:
        setState(() => _exporting = false);
        return;
    }
    try {
      final file = await _reportGenerator.generateReport(
        start: start,
        end: end,
        title: title,
      );
      if (!mounted) return;
      await _reportGenerator.shareReport(file);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report ready to share'),
          backgroundColor: Color(0xFFB6F36B),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
    if (mounted) setState(() => _exporting = false);
  }

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.date_range),
              title: const Text('Weekly report'),
              onTap: () {
                Navigator.pop(context);
                _exportReport('weekly');
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month),
              title: const Text('Monthly report'),
              onTap: () {
                Navigator.pop(context);
                _exportReport('monthly');
              },
            ),
            ListTile(
              leading: const Icon(Icons.tune),
              title: const Text('Custom date range'),
              onTap: () {
                Navigator.pop(context);
                _exportReport('custom');
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: _exporting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.picture_as_pdf),
            onPressed: _exporting ? null : _showExportOptions,
            tooltip: 'Export Report',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // MIGRAINE HISTORY SECTION
          SectionHeader(
            title: 'Migraine Attack History',
            subtitle: 'Review your recorded attacks',
            illustrationIcon: Icons.history,
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<MigraineAttack>>(
            future: _migraineFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        EmptyStateIllustration(
                          icon: Icons.history_rounded,
                          size: 90,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'No migraine records yet',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Start logging your attacks to see them here',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }
              final items = snapshot.data!;
              return Column(
                children: items
                    .asMap()
                    .entries
                    .map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _MigraineCard(item: item, index: index),
                      );
                    })
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 32),

          // MRI SCAN HISTORY SECTION
          SectionHeader(
            title: 'MRI Scan History',
            subtitle: 'Your uploaded brain scans',
            illustrationIcon: Icons.image_search,
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<MriScan>>(
            future: _mriFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        EmptyStateIllustration(
                          icon: Icons.photo_library_rounded,
                          size: 90,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'No MRI scans yet',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Upload your brain MRI scans to get analysis',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }
              final items = snapshot.data!;
              return Column(
                children: items
                    .asMap()
                    .entries
                    .map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _MriCard(item: item, index: index),
                      );
                    })
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _MigraineCard extends StatelessWidget {
  final MigraineAttack item;
  final int index;

  const _MigraineCard({
    Key? key,
    required this.item,
    required this.index,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timestamp = item.timestamp?.toLocal().toString().split('.').first ?? '-';
    final hasType = item.type != null && item.type!.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF171B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasType ? const Color(0xFFB6F36B) : Colors.grey.shade700,
          width: 2,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
              Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFB6F36B).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.local_hospital,
                  color: Color(0xFFB6F36B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Attack #${index + 1}',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      timestamp,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatChip(
                  label: 'Duration',
                  value: '${item.durationHours}h',
                  icon: Icons.schedule,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatChip(
                  label: 'Intensity',
                  value: '${item.intensity}/10',
                  icon: Icons.thermostat_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatChip(
                  label: 'Frequency',
                  value: '${item.frequencyPerMonth}/mo',
                  icon: Icons.repeat,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatChip(
                  label: 'Location',
                  value: item.location,
                  icon: Icons.location_on,
                ),
              ),
            ],
          ),
          if (hasType) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFB6F36B).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified, color: Color(0xFFB6F36B)),
                  const SizedBox(width: 8),
                  Text(
                    'Type: ${item.type}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFFB6F36B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MriCard extends StatelessWidget {
  final MriScan item;
  final int index;

  const _MriCard({
    Key? key,
    required this.item,
    required this.index,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timestamp = item.timestamp.toLocal().toString().split('.').first;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF171B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade700, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // IMAGE THUMBNAIL
          if (item.imagePath.isNotEmpty && File(item.imagePath).existsSync())
            Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
              ),
              child: Image.file(
                File(item.imagePath),
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              width: double.infinity,
              height: 180,
              color: Colors.grey.shade900,
              child: Center(
                child: Icon(
                  Icons.image,
                  size: 64,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          // DETAILS
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFB6F36B).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.image_search,
                        color: Color(0xFFB6F36B),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Scan #${index + 1}',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            timestamp,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: item.prediction == 'Tumor'
                          ? Colors.red.withValues(alpha: 0.1)
                          : Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  child: Row(
                    children: [
                      Icon(
                        item.prediction == 'Tumor'
                            ? Icons.warning
                            : Icons.check_circle,
                        color: item.prediction == 'Tumor'
                            ? Colors.red.shade400
                            : Colors.green.shade400,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Prediction: ${item.prediction}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Confidence: ${(item.confidence ?? 0).toStringAsFixed(1)}%',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatChip({
    Key? key,
    required this.label,
    required this.value,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: const Color(0xFFB6F36B)),
              const SizedBox(width: 4),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color(0xFFB6F36B),
            ),
          ),
        ],
      ),
    );
  }
}

