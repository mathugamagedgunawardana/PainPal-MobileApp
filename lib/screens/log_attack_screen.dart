import 'package:flutter/material.dart';

import '../data/auth_models.dart';
import '../data/patient_analytics_api.dart';
import '../services/app_services.dart';

const _kSurface = Color(0xFF171B22);
const _kAccent = Color(0xFFB6F36B);
const _kBg = Color(0xFF0F1218);

/// Home tab: connects to the Next.js API (MongoDB via Prisma) for patient analytics.
class LogAttackScreen extends StatefulWidget {
  const LogAttackScreen({super.key});

  @override
  State<LogAttackScreen> createState() => _LogAttackScreenState();
}

class _LogAttackScreenState extends State<LogAttackScreen> {
  bool _booting = true;
  bool _loadingAnalytics = false;
  String? _error;
  PatientAnalyticsData? _analytics;
  String? _apiBaseDisplay;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final base = await AppServices.auth.resolveApiBaseUrl();
    if (!mounted) {
      return;
    }
    setState(() {
      _apiBaseDisplay = base;
      _booting = false;
    });
    if (AppServices.auth.isAuthenticated && AppServices.auth.currentUser?.role == UserRole.patient) {
      await _fetchAnalytics();
    }
  }

  Future<void> _fetchAnalytics() async {
    final token = AppServices.auth.authToken;
    if (token == null || token.isEmpty) {
      return;
    }

    setState(() {
      _loadingAnalytics = true;
      _error = null;
    });

    try {
      final base = await AppServices.auth.resolveApiBaseUrl();
      final data = await fetchPatientAnalytics(
        baseUrl: base,
        bearerToken: token,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _analytics = data;
        _loadingAnalytics = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadingAnalytics = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (_booting) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isPatient = AppServices.auth.currentUser?.role == UserRole.patient;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text('Painpal'),
        backgroundColor: _kSurface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
      ),
      body: RefreshIndicator(
        color: _kAccent,
        backgroundColor: _kSurface,
        onRefresh: () async {
          if (AppServices.auth.isAuthenticated && isPatient) {
            await _fetchAnalytics();
          }
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            _HeaderCard(apiBase: _apiBaseDisplay ?? '—'),
            const SizedBox(height: 16),
            if (!isPatient) ...[
              Text(
                'This overview needs a patient profile. Sign out in Settings and sign in with a patient account.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ] else if (_loadingAnalytics)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_analytics != null)
              _AnalyticsBody(data: _analytics!, theme: theme, scheme: scheme)
            else
              Text(
                'Pull to refresh to load analytics.',
                style: theme.textTheme.bodyMedium,
              ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.errorContainer.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: scheme.error.withValues(alpha: 0.5)),
                ),
                child: Text(
                  _error!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onErrorContainer,
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

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.apiBase});

  final String apiBase;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kAccent.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _kAccent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.health_and_safety, color: _kBg, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome to Painpal',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Backend: $apiBase',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
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

class _AnalyticsBody extends StatelessWidget {
  const _AnalyticsBody({
    required this.data,
    required this.theme,
    required this.scheme,
  });

  final PatientAnalyticsData data;
  final ThemeData theme;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final summary = data;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your data (last 90 days, MongoDB)',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        if (summary.nextAttack != null) ...[
          _NextAttackCard(
            data: summary.nextAttack!,
            disclaimer: summary.nextAttackDisclaimer,
            theme: theme,
            scheme: scheme,
          ),
          const SizedBox(height: 12),
        ] else if (summary.nextAttackUnavailableReason != null &&
            summary.nextAttackUnavailableReason!.trim().isNotEmpty) ...[
          _NextAttackUnavailableCard(
            message: summary.nextAttackUnavailableReason!,
            theme: theme,
            scheme: scheme,
          ),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            Expanded(
              child: _StatTile(
                label: 'Episodes (30d)',
                value: '${summary.episodesLast30Days}',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatTile(
                label: 'Migraine days (month)',
                value: '${summary.migraineDaysThisMonth}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                label: 'Avg severity',
                value: summary.avgSeverity.toStringAsFixed(1),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatTile(
                label: 'Total events (90d)',
                value: '${summary.totalEpisodes}',
              ),
            ),
          ],
        ),
        if (summary.adherencePercent != null) ...[
          const SizedBox(height: 8),
          _StatTile(
            label: 'Adherence (approx.)',
            value: '${summary.adherencePercent}%',
          ),
        ],
        if (summary.triggers.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            'Top triggers',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          ...summary.triggers.take(5).map(
                (t) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(t.name)),
                      Text(
                        '${t.count}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: _kAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
        const SizedBox(height: 8),
        Text(
          'Log new attacks from the Log attack tab; data syncs to the server when you submit from the form.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _NextAttackUnavailableCard extends StatelessWidget {
  const _NextAttackUnavailableCard({
    required this.message,
    required this.theme,
    required this.scheme,
  });

  final String message;
  final ThemeData theme;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D24),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade700),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Next attack forecast',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _NextAttackCard extends StatelessWidget {
  const _NextAttackCard({
    required this.data,
    required this.theme,
    required this.scheme,
    this.disclaimer,
  });

  final PatientNextAttackData data;
  final ThemeData theme;
  final ColorScheme scheme;
  final String? disclaimer;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2419),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade700.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.upcoming_outlined, color: Colors.amber.shade300, size: 22),
              const SizedBox(width: 8),
              Text(
                'Next attack (forecast)',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.amber.shade100,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'From your last ${data.basedOnRecords} logged episode${data.basedOnRecords == 1 ? '' : 's'}. '
            'For planning only—not medical advice.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            data.predictedTypeDisplay,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
            ),
          ),
          if (data.duration != null ||
              data.frequency != null ||
              data.intensity != null) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                if (data.duration != null)
                  Text(
                    'Est. duration ${data.duration!.toStringAsFixed(1)} h',
                    style: theme.textTheme.bodySmall?.copyWith(color: _kAccent),
                  ),
                if (data.frequency != null)
                  Text(
                    'Frequency ${data.frequency!.toStringAsFixed(1)}',
                    style: theme.textTheme.bodySmall?.copyWith(color: _kAccent),
                  ),
                if (data.intensity != null)
                  Text(
                    'Intensity ${data.intensity!.toStringAsFixed(1)}',
                    style: theme.textTheme.bodySmall?.copyWith(color: _kAccent),
                  ),
              ],
            ),
          ],
          if (data.symptomsLikely.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Likely symptoms',
              style: theme.textTheme.labelMedium?.copyWith(
                color: Colors.amber.shade200,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: data.symptomsLikely.take(10).map((s) {
                final pct = s.probability != null
                    ? ' (${(s.probability! * 100).round()}%)'
                    : '';
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _kSurface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _kAccent.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    '${s.name}$pct',
                    style: theme.textTheme.bodySmall,
                  ),
                );
              }).toList(),
            ),
          ],
          if (disclaimer != null && disclaimer!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              disclaimer!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kAccent.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
