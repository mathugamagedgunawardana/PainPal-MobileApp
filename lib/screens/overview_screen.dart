import 'package:flutter/material.dart';

import '../data/database.dart';
import '../data/migraine_risk_service.dart';
import '../data/models.dart';
import '../data/storage.dart';
import '../widgets/illustrations.dart';

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({super.key});

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  final _database = PainpalDatabase.instance;
  final _riskService = MigraineRiskService();
  final _storage = SettingsStorage();
  late Future<List<MigraineAttack>> _attacksFuture;

  @override
  void initState() {
    super.initState();
    _attacksFuture = _database.fetchMigraineAttacks();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.health_and_safety,
                        size: 48,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Welcome to PainPal',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your migraine management companion',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Risk Card
              FutureBuilder<List<MigraineAttack>>(
                future: _attacksFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    );
                  }
                  
                  final attacks = snapshot.data ?? [];
                  final result = _riskService.calculateRisk(attacks);
                  
                  return _RiskCard(result: result, theme: theme);
                },
              ),
              const SizedBox(height: 24),

              Text(
                'Actions',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              _FeatureCard(
                icon: Icons.edit_note,
                title: 'Log Attack',
                description: 'Record symptoms and severity.',
              ),
              const SizedBox(height: 12),

              _FeatureCard(
                icon: Icons.image_search,
                title: 'MRI Upload',
                description: 'Analyze brain scans.',
              ),
              const SizedBox(height: 24),

              Text(
                'Getting Started',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              
              _StepCard(number: '1', title: 'Log an Attack', description: 'Start tracking patterns.'),
              const SizedBox(height: 8),
              _StepCard(number: '2', title: 'Sync MRI', description: 'Upload your latest scans.'),
            ],
          ),
        ),
      ),
    );
  }
}

class _RiskCard extends StatelessWidget {
  final MigraineRiskResult result;
  final ThemeData theme;

  const _RiskCard({required this.result, required this.theme});

  @override
  Widget build(BuildContext context) {
    final isHigh = result.isHigh;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isHigh ? Icons.warning_amber_rounded : Icons.insights,
                  color: isHigh ? Colors.orange : theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                const Text('Migraine Risk Today', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${result.score}%',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isHigh ? Colors.orange : theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            if (result.factors.isNotEmpty) ...[
              const Text('Factors:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              ...result.factors.take(2).map((f) => Text('• $f', style: const TextStyle(fontSize: 12))),
            ]
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureCard({required this.icon, required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(icon, color: theme.colorScheme.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(description),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final String number;
  final String title;
  final String description;

  const _StepCard({required this.number, required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: theme.colorScheme.secondary,
          child: Text(number, style: const TextStyle(fontSize: 12, color: Colors.white)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(description, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}
