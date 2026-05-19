import 'package:flutter/material.dart';

import '../data/auth_models.dart';
import '../data/patient_analytics_api.dart';
import '../services/app_services.dart';
import '../services/attack_timer_service.dart';
import '../widgets/patient_overview_cards.dart';
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

  String _formatSnapshotError(
    Object e,
    String apiBase, {
    String? configuredBase,
  }) {
    final s = e.toString();
    if (s.contains('SocketException') ||
        s.contains('ClientException') ||
        s.contains('Failed host lookup') ||
        s.contains('Connection refused') ||
        s.contains('Network is unreachable')) {
      final configured = configuredBase?.trim();
      final hostHint = (configured != null &&
              configured.isNotEmpty &&
              configured != apiBase)
          ? '\n(.env uses $configured; on Android emulator that becomes $apiBase to reach your PC.)'
          : '';
      final adbHint = apiBase.contains('127.0.0.1') || apiBase.contains('localhost')
          ? '\nFor local dev: run `adb reverse tcp:3000 tcp:3000` and start Next.js (`cd client && npm run dev`).'
          : '';
      return "Couldn't reach the API at $apiBase.$hostHint$adbHint\n"
          'On a physical phone, use your computer\'s LAN IP (not localhost), e.g. '
          'http://192.168.1.10:3000 — then pull to refresh.';
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

    final configured = await AppServices.auth.resolveConfiguredApiBaseUrl();
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
            _error = _formatSnapshotError(e2, base, configuredBase: configured);
          });
          return;
        }
      }
      if (!mounted) return;
      setState(() {
        _loadingAnalytics = false;
        _error = _formatSnapshotError(e, base, configuredBase: configured);
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
                      borderRadius: BorderRadius.circular(22),
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
    return OverviewSectionCard(
      backgroundColor: _kSurface,
      borderColor: _kAccent.withValues(alpha: 0.25),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _kAccent,
              borderRadius: BorderRadius.circular(16),
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
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your health snapshot',
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
    if (data.nextAttack != null) {
      return _NextAttackCard(
        data: data.nextAttack!,
        disclaimer: data.nextAttackDisclaimer,
        theme: theme,
        scheme: scheme,
      );
    }
    if (data.nextAttackUnavailableReason != null &&
        data.nextAttackUnavailableReason!.trim().isNotEmpty) {
      return _NextAttackUnavailableCard(
        message: data.nextAttackUnavailableReason!,
        theme: theme,
        scheme: scheme,
      );
    }
    return OverviewSectionCard(
      title: 'Forecast',
      titleIcon: Icons.bolt_rounded,
      titleColor: Colors.amber.shade200,
      subtitle: 'Log a few attacks to unlock your next-migraine forecast.',
      backgroundColor: const Color(0xFF1A1D24),
      borderColor: Colors.grey.shade700,
      child: const SizedBox.shrink(),
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
    final metrics = <Widget>[
      HealthMetricCard(
        label: 'Attacks (30 days)',
        value: '${summary.episodesLast30Days}',
        icon: Icons.calendar_month_outlined,
        highlighted: true,
      ),
      HealthMetricCard(
        label: 'Migraine days (month)',
        value: '${summary.migraineDaysThisMonth}',
        icon: Icons.event_busy_outlined,
      ),
      HealthMetricCard(
        label: 'Avg pain (1–10)',
        value: summary.avgSeverity.toStringAsFixed(1),
        icon: Icons.speed_outlined,
      ),
      HealthMetricCard(
        label: 'Total logged (90d)',
        value: '${summary.totalEpisodes}',
        icon: Icons.insights_outlined,
      ),
    ];
    if (summary.adherencePercent != null) {
      metrics.add(
        HealthMetricCard(
          label: 'Med habit',
          value: '${summary.adherencePercent}%',
          icon: Icons.medication_outlined,
          subtitle: 'approx.',
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OverviewSectionCard(
          title: 'Your patterns',
          titleIcon: Icons.grid_view_rounded,
          subtitle: 'Last ~90 days of your logs',
          child: HealthMetricGrid(children: metrics),
        ),
        if (summary.triggers.isNotEmpty) ...[
          const SizedBox(height: 12),
          OverviewSectionCard(
            title: 'Common triggers',
            titleIcon: Icons.warning_amber_rounded,
            child: Column(
              children: summary.triggers
                  .take(3)
                  .map(
                    (t) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: TriggerChipCard(name: t.name, count: t.count),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
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
    return OverviewSectionCard(
      title: 'Forecast unavailable',
      titleIcon: Icons.info_outline_rounded,
      titleColor: scheme.onSurfaceVariant,
      subtitle: message,
      backgroundColor: const Color(0xFF1A1D24),
      borderColor: Colors.grey.shade700,
      child: const SizedBox.shrink(),
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
    final basedOn = data.basedOnRecords > 0
        ? 'Based on ${data.basedOnRecords} logged attack${data.basedOnRecords == 1 ? '' : 's'}. '
        : '';
    final subtitle = '${basedOn}Awareness only—not a diagnosis or treatment plan.';

    final metricTiles = <Widget>[];
    if (data.duration != null) {
      metricTiles.add(
        HealthMetricCard(
          label: 'Typical length',
          value: '${data.duration!.toStringAsFixed(1)} h',
          icon: Icons.schedule_outlined,
          highlighted: true,
        ),
      );
    }
    if (data.frequency != null) {
      metricTiles.add(
        HealthMetricCard(
          label: 'Episodes / month',
          value: '${data.frequency!.round()}',
          icon: Icons.repeat_outlined,
        ),
      );
    }
    if (data.intensity != null) {
      metricTiles.add(
        HealthMetricCard(
          label: 'Pain (1–10 est.)',
          value: data.intensity!.toStringAsFixed(1),
          icon: Icons.favorite_border_rounded,
        ),
      );
    }

    final symptoms = data.symptomsLikely.take(4).map((s) {
      final pct = s.probability != null
          ? '${(s.probability! * 100).round()}%'
          : null;
      return (name: s.name, percentLabel: pct);
    }).toList();

    return OverviewSectionCard(
      title: 'Forecast',
      titleIcon: Icons.bolt_rounded,
      titleColor: Colors.amber.shade200,
      subtitle: subtitle,
      backgroundColor: const Color(0xFF2A2419),
      borderColor: Colors.amber.shade700.withValues(alpha: 0.45),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: _kBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amber.shade800.withValues(alpha: 0.35)),
            ),
            child: Text(
              data.predictedTypeDisplay,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
            ),
          ),
          if (metricTiles.isNotEmpty) ...[
            const SizedBox(height: 12),
            HealthMetricGrid(children: metricTiles),
          ],
          if (symptoms.isNotEmpty) ...[
            const SizedBox(height: 12),
            SymptomLikelihoodCard(
              title: 'Likely symptoms',
              symptoms: symptoms,
            ),
          ],
          if (disclaimer != null && disclaimer!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              disclaimer!.trim(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
