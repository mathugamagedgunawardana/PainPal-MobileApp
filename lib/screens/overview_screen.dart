import 'package:flutter/material.dart';

import '../data/database.dart';
import '../data/migraine_risk_service.dart';
import '../data/models.dart';
import '../data/notification_service.dart';
import '../data/storage.dart';

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
  bool _riskAlertShown = false;

  @override
  void initState() {
    super.initState();
    _attacksFuture = _database.fetchMigraineAttacks();
  }

  Future<void> _maybeShowRiskNotification(MigraineRiskResult result) async {
    if (!result.isHigh || _riskAlertShown) return;
    final enabled = await _storage.getNotificationsRisk();
    if (!enabled) return;
    _riskAlertShown = true;
    await NotificationService.instance.showRiskAlert();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.health_and_safety,
                          size: 40,
                          color: isDark ? Colors.black : Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Welcome to Painpal',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your migraine management companion',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark ? Colors.grey : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Migraine Risk Forecast Card
              FutureBuilder<List<MigraineAttack>>(
                future: _attacksFuture,
                builder: (context, snapshot) {
                  MigraineRiskResult result;
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    result = _riskService.calculateRisk([]);
                  } else {
                    result = _riskService.calculateRisk(snapshot.data!);
                    _maybeShowRiskNotification(result);
                  }
                  return _RiskCard(result: result, theme: theme);
                },
              ),
              const SizedBox(height: 32),

              // Features Section
              Text(
                'Features',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Feature 1
              _FeatureCard(
                icon: Icons.edit_note,
                title: 'Log Migraine Attacks',
                description: 'Record details of your migraine attacks including symptoms, duration, and severity.',
              ),
              const SizedBox(height: 12),

              // Feature 2
              _FeatureCard(
                icon: Icons.image_search,
                title: 'MRI Upload',
                description: 'Upload and analyze MRI images to better understand your condition.',
              ),
              const SizedBox(height: 12),

              // Feature 3
              _FeatureCard(
                icon: Icons.history,
                title: 'View History',
                description: 'Track patterns and trends in your migraine history over time.',
              ),
              const SizedBox(height: 12),

              // Feature 4
              _FeatureCard(
                icon: Icons.settings,
                title: 'Settings',
                description: 'Customize your preferences and notification settings.',
              ),
              const SizedBox(height: 40),

              // Quick Start Section
              Text(
                'Quick Start',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              _StepCard(
                number: '1',
                title: 'Log Your First Attack',
                description: 'Go to the "Log Attack" tab to record your first migraine.',
              ),
              const SizedBox(height: 12),

              _StepCard(
                number: '2',
                title: 'Upload MRI Images',
                description: 'Use the "MRI Upload" tab to add medical imaging.',
              ),
              const SizedBox(height: 12),

              _StepCard(
                number: '3',
                title: 'Monitor Progress',
                description: 'Check the "History" tab to see patterns and improvements.',
              ),
              const SizedBox(height: 40),
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
    final isDark = theme.brightness == Brightness.dark;
    final isHigh = result.isHigh;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHigh
            ? Colors.orange.withValues(alpha: isDark ? 0.25 : 0.15)
            : theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHigh ? Colors.orange : (isDark ? const Color(0xFF2A2E35) : Colors.grey.shade300),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isHigh ? Icons.warning_amber_rounded : Icons.insights,
                color: isHigh ? Colors.orange : theme.colorScheme.primary,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Migraine Risk Today',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
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
          Text(
            'Contributing factors:',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          ...result.factors.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ', style: theme.textTheme.bodyMedium),
                    Expanded(child: Text(f, style: theme.textTheme.bodySmall)),
                  ],
                ),
              )),
          if (isHigh) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Consider hydration, rest, and avoiding known triggers.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.amber.shade800,
                      ),
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

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? const Color(0xFF2A2E35)
              : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Icon(
                icon,
                color: theme.colorScheme.primary,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? Colors.grey : Colors.grey.shade700,
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

class _StepCard extends StatelessWidget {
  final String number;
  final String title;
  final String description;

  const _StepCard({
    required this.number,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? const Color(0xFF2A2E35)
              : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.black : Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? Colors.grey : Colors.grey.shade700,
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

