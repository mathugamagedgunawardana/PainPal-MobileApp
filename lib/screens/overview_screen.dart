import 'package:flutter/material.dart';

import '../data/database.dart';
import '../data/migraine_risk_service.dart';
import '../data/models.dart';
import '../data/storage.dart';
import '../widgets/app_illustrations.dart';

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
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const WelcomeHeroSection(
                title: 'Welcome to PainPal',
                subtitle: 'Your migraine management companion',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
              const SizedBox(height: 20),

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
                icon: Icons.edit_note_rounded,
                title: 'Log Attack',
                description: 'Record symptoms and severity.',
              ),
              const SizedBox(height: 12),

              _FeatureCard(
                icon: Icons.image_search_rounded,
                title: 'MRI Upload',
                description: 'Analyze brain scans.',
              ),
              const SizedBox(height: 24),

              _WellnessTipCard(theme: theme),
              const SizedBox(height: 24),

              Text(
                'Getting Started',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              
              _StepCard(stepIcon: Icons.assignment_rounded, number: '1', title: 'Log an Attack', description: 'Start tracking patterns.'),
              const SizedBox(height: 10),
              _StepCard(stepIcon: Icons.photo_library_rounded, number: '2', title: 'Sync MRI', description: 'Upload your latest scans.'),
              const SizedBox(height: 24),
                  ],
                ),
              ),
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
    final riskColor = isHigh ? AppIllustrationColors.warmOrange : AppIllustrationColors.pastelBlueDark;

    return Card(
      elevation: theme.brightness == Brightness.dark ? 0 : 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: riskColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isHigh ? Icons.warning_amber_rounded : Icons.insights_rounded,
                    color: riskColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Migraine Risk Today',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '${result.score}%',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: riskColor,
              ),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (result.score / 100).clamp(0.0, 1.0),
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(riskColor),
                minHeight: 6,
              ),
            ),
            if (result.factors.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Contributing factors',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 4),
              ...result.factors.take(3).map(
                (f) => Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• ', style: TextStyle(fontSize: 12, color: riskColor)),
                      Expanded(child: Text(f, style: theme.textTheme.bodySmall)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _WellnessTipCard extends StatelessWidget {
  final ThemeData theme;

  const _WellnessTipCard({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: theme.brightness == Brightness.dark ? 0 : 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            TipCardIllustration(
              icon: Icons.nightlight_round,
              backgroundColor: AppIllustrationColors.softPurple.withValues(alpha: 0.2),
              iconColor: AppIllustrationColors.softPurple,
              size: 52,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sleep & stress tips',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Good sleep and reduced stress can help lower migraine frequency. Check Tracking for patterns.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
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
      elevation: theme.brightness == Brightness.dark ? 0 : 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            FeatureIllustrationIcon(icon: icon, size: 52),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final IconData stepIcon;
  final String number;
  final String title;
  final String description;

  const _StepCard({
    required this.stepIcon,
    required this.number,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: theme.brightness == Brightness.dark ? 0 : 1,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            StepIllustrationIcon(icon: stepIcon, size: 44),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppIllustrationColors.pastelBlueDark.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                number,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppIllustrationColors.pastelBlueDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
