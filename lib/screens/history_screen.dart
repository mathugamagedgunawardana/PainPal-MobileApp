import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/auth_models.dart';
import '../data/database.dart';
import '../data/models.dart';
import '../data/patient_remote_api.dart';
import '../services/app_services.dart';
import '../theme/painpal_app_colors.dart';
import '../widgets/custom_widgets.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, this.embedInShell = false});

  /// When true, [HomeScreen] provides the shell header; hide local [AppBar].
  final bool embedInShell;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

enum _MigraineViewMode { list, calendar }

class _HistoryScreenState extends State<HistoryScreen> {
  final _database = PainpalDatabase.instance;

  late Future<List<MigraineAttack>> _migraineFuture;

  _MigraineViewMode _migraineViewMode = _MigraineViewMode.calendar;
  DateTime _calendarMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _migraineFuture = _loadMigrainesMerged();
  }

  Future<List<MigraineAttack>> _loadMigrainesMerged() async {
    final local = await _database.fetchMigraineAttacks();
    final auth = AppServices.auth;
    if (!auth.isAuthenticated || auth.currentUser?.role != UserRole.patient) {
      return local;
    }
    try {
      final base = await auth.resolveApiBaseUrl();
      final token = auth.authToken;
      if (token == null || token.isEmpty) {
        return local;
      }
      final remote = await fetchPatientMigraineEvents(
        baseUrl: base,
        bearerToken: token,
      );
      final remoteIds = remote.map((e) => e.attackId).whereType<String>().toSet();
      final localOnly = local.where((l) {
        final id = l.attackId;
        if (id == null) {
          return true;
        }
        return !remoteIds.contains(id);
      });
      return [...remote, ...localOnly];
    } catch (_) {
      return local;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pp = context.pp;

    return Scaffold(
      backgroundColor: pp.bgTertiary,
      appBar: widget.embedInShell
          ? null
          : AppBar(
              title: const Text('📅 Attack history'),
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.embedInShell)
            Material(
              color: pp.bgCard,
              child: Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                  onPressed: () {
                    setState(() {
                      _reload();
                    });
                  },
                ),
              ),
            ),
          Expanded(
            child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // MIGRAINE HISTORY SECTION
          SectionHeader(
            title: 'Attack history 📅',
            subtitle: 'Your recorded attacks',
            illustrationIcon: Icons.history,
          ),
          const SizedBox(height: 12),
          SegmentedButton<_MigraineViewMode>(
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: pp.accentPrimary,
              selectedForegroundColor: pp.textOnAccent,
              backgroundColor: pp.bgSecondary,
              side: BorderSide(color: pp.borderDefault),
            ),
            segments: const [
              ButtonSegment(
                value: _MigraineViewMode.calendar,
                label: Text('Calendar'),
                icon: Icon(Icons.calendar_month, size: 18),
              ),
              ButtonSegment(
                value: _MigraineViewMode.list,
                label: Text('List'),
                icon: Icon(Icons.view_list, size: 18),
              ),
            ],
            selected: {_migraineViewMode},
            onSelectionChanged: (s) {
              setState(() => _migraineViewMode = s.first);
            },
          ),
          const SizedBox(height: 16),
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
                      Icon(Icons.inbox, size: 64, color: pp.textTertiary),
                      const SizedBox(height: 16),
                      Text(
                        'No migraine records yet',
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start logging your attacks to see them here',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: pp.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }
              final items = List<MigraineAttack>.from(snapshot.data!);
              items.sort((a, b) {
                final ta = a.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
                final tb = b.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
                return tb.compareTo(ta);
              });
              if (_migraineViewMode == _MigraineViewMode.calendar) {
                return _AttackHistoryCalendar(
                  month: _calendarMonth,
                  attacks: items,
                  onMonthChanged: (d) => setState(() => _calendarMonth = d),
                );
              }
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
          const SizedBox(height: 20),
        ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Month grid: dots on days with attacks; tap a day to see details.
class _AttackHistoryCalendar extends StatelessWidget {
  const _AttackHistoryCalendar({
    required this.month,
    required this.attacks,
    required this.onMonthChanged,
  });

  final DateTime month;
  final List<MigraineAttack> attacks;
  final ValueChanged<DateTime> onMonthChanged;

  static int _leadingBlankDays(DateTime firstOfMonth) {
    // Sunday-first columns: Dart uses Mon=1 … Sun=7.
    return firstOfMonth.weekday % 7;
  }

  Map<DateTime, int> _attackCountByDay() {
    final map = <DateTime, int>{};
    for (final a in attacks) {
      final t = a.timestamp;
      if (t == null) {
        continue;
      }
      final d = DateTime(t.year, t.month, t.day);
      map[d] = (map[d] ?? 0) + 1;
    }
    return map;
  }

  void _openDaySheet(BuildContext context, DateTime day) {
    final dayOnly = DateTime(day.year, day.month, day.day);
    final entries = <({int index, MigraineAttack attack})>[];
    for (var i = 0; i < attacks.length; i++) {
      final t = attacks[i].timestamp;
      if (t == null) {
        continue;
      }
      final d = DateTime(t.year, t.month, t.day);
      if (d == dayOnly) {
        entries.add((index: i, attack: attacks[i]));
      }
    }
    entries.sort((a, b) {
      final ta = a.attack.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
      final tb = b.attack.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
      return tb.compareTo(ta);
    });

    final theme = Theme.of(context);
    final pp = context.pp;
    final title = DateFormat.yMMMEd().format(dayOnly);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: pp.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(PainpalRadii.xl)),
      ),
      builder: (ctx) {
        final maxH = MediaQuery.sizeOf(ctx).height * 0.58;
        if (entries.isEmpty) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No attacks on this day',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return SafeArea(
          child: SizedBox(
            height: maxH,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 4, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Text(
                    '${entries.length} attack${entries.length == 1 ? '' : 's'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: entries.length,
                    itemBuilder: (context, i) {
                      final e = entries[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _MigraineCard(
                          item: e.attack,
                          index: e.index,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pp = context.pp;
    final y = month.year;
    final m = month.month;
    final first = DateTime(y, m);
    final daysInMonth = DateTime(y, m + 1, 0).day;
    final leading = _leadingBlankDays(first);
    final counts = _attackCountByDay();
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final monthTitle = DateFormat.yMMMM().format(first);
    final hasUndated = attacks.any((a) => a.timestamp == null);

    var cellCount = leading + daysInMonth;
    while (cellCount % 7 != 0) {
      cellCount++;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () {
                final prev = DateTime(y, m - 1);
                onMonthChanged(DateTime(prev.year, prev.month));
              },
              icon: const Icon(Icons.chevron_left),
              color: pp.accentPrimary,
            ),
            Expanded(
              child: Text(
                monthTitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                final next = DateTime(y, m + 1);
                onMonthChanged(DateTime(next.year, next.month));
              },
              icon: const Icon(Icons.chevron_right),
              color: pp.accentPrimary,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa']
              .map(
                (d) => Expanded(
                  child: Center(
                    child: Text(
                      d,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 6),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            childAspectRatio: 1.1,
          ),
          itemCount: cellCount,
          itemBuilder: (context, i) {
            final dayNum = i - leading + 1;
            if (i < leading || dayNum < 1 || dayNum > daysInMonth) {
              return const SizedBox.shrink();
            }
            final date = DateTime(y, m, dayNum);
            final n = counts[date] ?? 0;
            final isToday = date == todayOnly;

            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _openDaySheet(context, date),
                borderRadius: BorderRadius.circular(8),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: pp.bgCard,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isToday
                          ? pp.accentPrimary
                          : (n > 0
                              ? pp.accentPrimary.withValues(alpha: 0.45)
                              : pp.borderDefault),
                      width: isToday ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$dayNum',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: n > 0 ? pp.textPrimary : pp.textTertiary,
                        ),
                      ),
                      if (n > 0) ...[
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: pp.accentPrimary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$n',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: pp.textOnAccent,
                              fontWeight: FontWeight.w800,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        if (hasUndated) ...[
          const SizedBox(height: 12),
          Text(
            'Entries without a date only appear in List view.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ],
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
    final pp = context.pp;
    final timestamp = item.timestamp?.toLocal().toString().split('.').first ?? '-';
    final hasType = item.type != null && item.type!.isNotEmpty;
    final intensityTone = item.intensity > 7
        ? pp.accentDanger
        : (item.intensity >= 4 ? pp.accentWarning : pp.accentSuccess);

    return Container(
      decoration: BoxDecoration(
        color: pp.bgCard,
        borderRadius: BorderRadius.circular(PainpalRadii.lg),
        border: Border.all(
          color: hasType ? pp.accentPrimary : pp.borderDefault,
          width: hasType ? 2 : 1,
        ),
        boxShadow: pp.shadowCard,
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
                  color: pp.accentPrimaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.local_hospital,
                  color: pp.accentPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🧠 Attack #${index + 1}',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: pp.textPrimary,
                      ),
                    ),
                    Text(
                      timestamp,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: pp.textTertiary,
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
                  label: '⏱️ Duration',
                  value: '${item.durationHours}h',
                  icon: Icons.schedule,
                  valueColor: pp.accentPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatChip(
                  label: '🔥 Intensity',
                  value: '${item.intensity}/10',
                  icon: Icons.thermostat_outlined,
                  valueColor: intensityTone,
                  valueBackground: intensityTone.withValues(alpha: 0.12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatChip(
                  label: '📅 Frequency',
                  value: '${item.frequencyPerMonth}/mo',
                  icon: Icons.repeat,
                  valueColor: pp.accentPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatChip(
                  label: '📍 Location',
                  value: item.location,
                  icon: Icons.location_on,
                  valueColor: pp.accentPrimary,
                ),
              ),
            ],
          ),
          if (hasType) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: pp.accentPrimaryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.verified, color: pp.accentPrimary),
                  const SizedBox(width: 8),
                  Text(
                    'Type: ${item.type}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: pp.accentPrimary,
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

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color valueColor;
  final Color? valueBackground;

  const _StatChip({
    Key? key,
    required this.label,
    required this.value,
    required this.icon,
    required this.valueColor,
    this.valueBackground,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pp = context.pp;
    return Container(
      decoration: BoxDecoration(
        color: pp.bgSecondary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: pp.borderDefault),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: pp.textTertiary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: pp.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: valueBackground ?? Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: valueColor,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

