import 'package:flutter/material.dart';

import '../data/auth_models.dart';
import '../data/patient_analytics_api.dart';
import '../services/app_services.dart';
import '../services/attack_timer_service.dart';
import 'migraine_form_screen.dart';

const _kSurface = Color(0xFF171B22);
const _kAccent = Color(0xFFB6F36B);
const _kBg = Color(0xFF0F1218);

/// Home tab: quick snapshot and logging entry for patients.
class LogAttackScreen extends StatefulWidget {
  const LogAttackScreen({super.key, this.embedInShell = false});

  /// When true, [HomeScreen] provides the shell header; hide local [AppBar].
  final bool embedInShell;

  @override
  State<LogAttackScreen> createState() => _LogAttackScreenState();
}

class _LogAttackScreenState extends State<LogAttackScreen> {
  bool _loadingAnalytics = false;
  String? _error;
  PatientAnalyticsData? _analytics;

  String _formatSnapshotError(Object e, String apiBase) {
    final s = e.toString();
    if (s.contains('SocketException') ||
        s.contains('ClientException') ||
        s.contains('Failed host lookup') ||
        s.contains('Connection refused') ||
        s.contains('Network is unreachable')) {
      return "Couldn't reach the API at $apiBase.\n"
          'On a real phone, use your computer\'s LAN IP in Settings (not localhost). '
          'Example: http://192.168.1.10:3000 — then pull to refresh.';
    }
    if (s.contains('Not authorized') ||
        s.contains('401') ||
        s.contains('Token refresh failed')) {
      return "Couldn't verify your session. Pull down to retry, or open Settings → "
          'sign out and sign in again.';
    }
    if (s.contains('403') || s.contains('Insufficient permissions')) {
      return 'This account cannot load the patient overview. Sign in with a patient account.';
    }
    if (s.contains('404') ||
        s.contains('Patient profile not found')) {
      return 'No patient profile found for this account. Use a seeded patient user or register as patient.';
    }
    if (s.contains('TimeoutException') || s.contains('timed out')) {
      return 'Request timed out. Check that the Next.js server is running and the API URL is correct.';
    }
    final short = s.length > 180 ? '${s.substring(0, 180)}…' : s;
    return "Couldn't load your snapshot.\n$short\nPull down to retry.";
  }

  @override
  void initState() {
    super.initState();
    if (AppServices.auth.isAuthenticated &&
        AppServices.auth.currentUser?.role == UserRole.patient) {
      _fetchAnalytics();
    }
  }

  Future<void> _fetchAnalytics() async {
    final token = AppServices.auth.authToken;
    if (token == null || token.isEmpty) {
      return;
    }

    if (!mounted) return;
    setState(() {
      _loadingAnalytics = true;
      _error = null;
    });

    final base = await AppServices.auth.resolveApiBaseUrl();

    Future<void> loadOnce() async {
      final t = AppServices.auth.authToken;
      if (t == null || t.isEmpty) {
        throw Exception('Not signed in');
      }
      final data = await fetchPatientAnalytics(
        baseUrl: base,
        bearerToken: t,
      );
      if (!mounted) return;
      setState(() {
        _analytics = data;
        _loadingAnalytics = false;
        _error = null;
      });
    }

    try {
      await loadOnce();
    } catch (e) {
      final msg = e.toString();
      final unauthorized =
          msg.contains('Not authorized') || msg.contains('401');
      if (unauthorized) {
        try {
          await AppServices.auth.refreshToken();
          await loadOnce();
          return;
        } catch (e2) {
          if (!mounted) return;
          setState(() {
            _loadingAnalytics = false;
            _error = _formatSnapshotError(e2, base);
          });
          return;
        }
      }
      if (!mounted) return;
      setState(() {
        _loadingAnalytics = false;
        _error = _formatSnapshotError(e, base);
      });
    }
  }

  void _onStartAttackTimer() {
    AppServices.attackTimer.start();
  }

  void _onCancelAttackTimer() {
    AppServices.attackTimer.cancel();
  }

  void _onStopAttackTimerAndLog() {
    final r = AppServices.attackTimer.consumeStopForLog();
    if (r == null) {
      return;
    }
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => MigraineFormScreen(
          initialDurationHours: r.durationHours,
          attackStartedAt: r.startedAt,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final isPatient = AppServices.auth.currentUser?.role == UserRole.patient;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: widget.embedInShell
          ? null
          : AppBar(
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
            _HeaderCard(),
            const SizedBox(height: 16),
            if (isPatient) ...[
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => const MigraineFormScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.edit_note),
                label: const Text('Log an attack'),
                style: FilledButton.styleFrom(
                  backgroundColor: _kAccent,
                  foregroundColor: _kBg,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 10),
              ListenableBuilder(
                listenable: AppServices.attackTimer,
                builder: (context, _) {
                  final running = AppServices.attackTimer.isRunning;
                  if (!running) {
                    return OutlinedButton.icon(
                      onPressed: _onStartAttackTimer,
                      icon: const Icon(Icons.timer_outlined),
                      label: const Text('Pain started — start timer'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _kAccent,
                        side: BorderSide(
                          color: _kAccent.withValues(alpha: 0.45),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    );
                  }
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _kSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _kAccent.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Attack timer',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: _kAccent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          AttackTimerService.formatElapsed(
                            AppServices.attackTimer.elapsed,
                          ),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Stop when the attack eases or ends, then finish the log. '
                          'You can also use the timer button above chat.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: _onStopAttackTimerAndLog,
                                icon: const Icon(Icons.stop_circle_outlined),
                                label: const Text('Stop & log attack'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: _kAccent,
                                  foregroundColor: _kBg,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: _onCancelAttackTimer,
                              child: const Text('Cancel'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
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
            else if (_analytics != null) ...[
              _NextAttackOverviewSection(
                data: _analytics!,
                theme: theme,
                scheme: scheme,
              ),
              const SizedBox(height: 16),
              _AnalyticsBody(data: _analytics!, theme: theme, scheme: scheme),
            ] else
              Text(
                'Pull down to refresh your snapshot.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
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
  const _HeaderCard();

  String _greetingLine() {
    final name = AppServices.auth.patientProfile?.name.trim();
    if (name != null && name.isNotEmpty) {
      final first = name.split(RegExp(r'\s+')).first;
      return 'Hi, $first';
    }
    return 'Welcome';
  }

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
                  _greetingLine(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'A simple snapshot of how you\'ve been doing lately.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.35,
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

/// Next-attack forecast shown at the top of the home overview (below primary actions).
class _NextAttackOverviewSection extends StatelessWidget {
  const _NextAttackOverviewSection({
    required this.data,
    required this.theme,
    required this.scheme,
  });

  final PatientAnalyticsData data;
  final ThemeData theme;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Next migraine attack',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Model forecast from your recent logs—not a diagnosis.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 10),
        if (data.nextAttack != null)
          _NextAttackCard(
            data: data.nextAttack!,
            disclaimer: data.nextAttackDisclaimer,
            theme: theme,
            scheme: scheme,
          )
        else if (data.nextAttackUnavailableReason != null &&
            data.nextAttackUnavailableReason!.trim().isNotEmpty)
          _NextAttackUnavailableCard(
            message: data.nextAttackUnavailableReason!,
            theme: theme,
            scheme: scheme,
          )
        else
          Text(
            'Log a few attacks to see a forecast for your next migraine.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
      ],
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
          'Your patterns',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Based on roughly the last three months of logs you\'ve saved.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kAccent.withValues(alpha: 0.15)),
          ),
          child: Column(
            children: [
              _StatRow(
                label: 'Attacks in the last 30 days',
                value: '${summary.episodesLast30Days}',
                theme: theme,
                scheme: scheme,
              ),
              Divider(height: 20, color: scheme.outline.withValues(alpha: 0.25)),
              _StatRow(
                label: 'Days with migraine this month',
                value: '${summary.migraineDaysThisMonth}',
                theme: theme,
                scheme: scheme,
              ),
              Divider(height: 20, color: scheme.outline.withValues(alpha: 0.25)),
              _StatRow(
                label: 'Average pain level (1–10)',
                value: summary.avgSeverity.toStringAsFixed(1),
                theme: theme,
                scheme: scheme,
              ),
              Divider(height: 20, color: scheme.outline.withValues(alpha: 0.25)),
              _StatRow(
                label: 'Total attacks logged (90 days)',
                value: '${summary.totalEpisodes}',
                theme: theme,
                scheme: scheme,
              ),
              if (summary.adherencePercent != null) ...[
                Divider(height: 20, color: scheme.outline.withValues(alpha: 0.25)),
                _StatRow(
                  label: 'Medication habit (approx.)',
                  value: '${summary.adherencePercent}%',
                  theme: theme,
                  scheme: scheme,
                ),
              ],
            ],
          ),
        ),
        if (summary.triggers.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            'Triggers you\'ve noted often',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          ...summary.triggers.take(3).map(
                (t) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(t.name)),
                      Text(
                        '${t.count}×',
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
      ],
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    required this.value,
    required this.theme,
  });

  final String label;
  final String value;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _kBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kAccent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: _kAccent,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
    required this.theme,
    required this.scheme,
  });

  final String label;
  final String value;
  final ThemeData theme;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
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
          Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 20, color: scheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Forecast unavailable',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ],
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
              Icon(Icons.bolt_rounded, color: Colors.amber.shade300, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Forecast',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.amber.shade100,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'For your awareness only—not a diagnosis or treatment plan.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          if (data.basedOnRecords > 0) ...[
            const SizedBox(height: 6),
            Text(
              'Based on ${data.basedOnRecords} logged attack${data.basedOnRecords == 1 ? '' : 's'} in your history.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.amber.shade200.withValues(alpha: 0.9),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            data.predictedTypeDisplay,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
            ),
          ),
          if (data.duration != null ||
              data.frequency != null ||
              data.intensity != null) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                if (data.duration != null)
                  _MetricChip(
                    label: 'Typical length',
                    value: '${data.duration!.toStringAsFixed(1)} h',
                    theme: theme,
                  ),
                if (data.frequency != null)
                  _MetricChip(
                    label: 'Episodes / month (est.)',
                    value: '${data.frequency!.round()}',
                    theme: theme,
                  ),
                if (data.intensity != null)
                  _MetricChip(
                    label: 'Pain (1–10 est.)',
                    value: '${data.intensity!.toStringAsFixed(1)}/10',
                    theme: theme,
                  ),
              ],
            ),
          ],
          if (data.symptomsLikely.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'Symptoms that often show up with your attacks',
              style: theme.textTheme.labelLarge?.copyWith(
                color: Colors.amber.shade200,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: data.symptomsLikely.take(4).map((s) {
                final pct = s.probability != null
                    ? ' ${(s.probability! * 100).round()}%'
                    : '';
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _kSurface,
                    borderRadius: BorderRadius.circular(20),
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
          if (disclaimer != null && disclaimer!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              disclaimer!.trim(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.35,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
