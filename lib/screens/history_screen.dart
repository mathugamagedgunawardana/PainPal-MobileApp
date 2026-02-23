import 'dart:io';

import 'package:flutter/material.dart';

import '../data/database.dart';
import '../data/models.dart';
import '../widgets/custom_widgets.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _database = PainpalDatabase.instance;

  late Future<List<MigraineAttack>> _migraineFuture;
  late Future<List<MriScan>> _mriFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _migraineFuture = _database.fetchMigraineAttacks();
    _mriFuture = _database.fetchMriScans();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        elevation: 0,
        backgroundColor: const Color(0xFF171B22),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _reload();
              });
            },
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
                  child: Column(
                    children: [
                      Icon(Icons.inbox, size: 64, color: Colors.grey.shade600),
                      const SizedBox(height: 16),
                      Text(
                        'No migraine records yet',
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start logging your attacks to see them here',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
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
                  child: Column(
                    children: [
                      Icon(Icons.image, size: 64, color: Colors.grey.shade600),
                      const SizedBox(height: 16),
                      Text(
                        'No MRI scans yet',
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Upload your brain MRI scans to get analysis',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
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
                        color: const Color(0xFFB6F36B).withOpacity(0.2),
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

