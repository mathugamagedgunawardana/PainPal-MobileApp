import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/api_client.dart';
import '../data/database.dart';
import '../data/models.dart';
import '../data/storage.dart';
import '../widgets/custom_widgets.dart';

/// Comprehensive migraine tracking screen with statistics, trends, and insights
/// Now includes inline migraine attack logging
class TrackingScreen extends StatefulWidget {
  final VoidCallback? onNavigateToLogAttack;

  const TrackingScreen({super.key, this.onNavigateToLogAttack});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final _database = PainpalDatabase.instance;
  final _storage = SettingsStorage();
  late Future<List<MigraineAttack>> _attacksFuture;

  // Date range selection
  DateRange _selectedRange = DateRange.lastMonth;
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  // Form state
  bool _showForm = false;
  final _formKey = GlobalKey<FormState>();
  final _durationController = TextEditingController();
  final _frequencyController = TextEditingController();
  final _intensityController = TextEditingController();
  final _ageController = TextEditingController();
  final _attackIdController = TextEditingController();

  String _location = 'Unilateral';
  String _character = 'Throbbing';
  String _dpf = 'Pattern1';

  int _nausea = 0;
  int _vomit = 0;
  int _phonophobia = 0;
  int _photophobia = 0;
  int _visual = 0;
  int _sensory = 0;
  int _dysphasia = 0;
  int _dysarthria = 0;
  int _vertigo = 0;
  int _tinnitus = 0;
  int _hypoacusis = 0;
  int _diplopia = 0;
  int _defect = 0;
  int _ataxia = 0;
  int _conscience = 0;
  int _paresthesia = 0;

  bool _submitting = false;
  MigraineApiResponse? _response;

  @override
  void initState() {
    super.initState();
    _reload();
    _loadDraft();
  }

  void _reload() {
    setState(() {
      _attacksFuture = _database.fetchMigraineAttacks();
    });
  }

  Future<void> _loadDraft() async {
    final draftJson = await _storage.readDraftAttack();
    final draft = MigraineAttack.fromDraftJson(draftJson);
    if (draft == null) {
      return;
    }

    _durationController.text = draft.durationHours.toString();
    _frequencyController.text = draft.frequencyPerMonth.toString();
    _intensityController.text = draft.intensity.toString();
    _ageController.text = draft.age?.toString() ?? '';
    _attackIdController.text = draft.attackId ?? '';
    _location = draft.location;
    _character = draft.character;
    _dpf = draft.dpf;
    _nausea = draft.nausea;
    _vomit = draft.vomit;
    _phonophobia = draft.phonophobia;
    _photophobia = draft.photophobia;
    _visual = draft.visual;
    _sensory = draft.sensory;
    _dysphasia = draft.dysphasia;
    _dysarthria = draft.dysarthria;
    _vertigo = draft.vertigo;
    _tinnitus = draft.tinnitus;
    _hypoacusis = draft.hypoacusis;
    _diplopia = draft.diplopia;
    _defect = draft.defect;
    _ataxia = draft.ataxia;
    _conscience = draft.conscience;
    _paresthesia = draft.paresthesia;

    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _durationController.dispose();
    _frequencyController.dispose();
    _intensityController.dispose();
    _ageController.dispose();
    _attackIdController.dispose();
    super.dispose();
  }

  Future<void> _saveDraft() async {
    final attack = _buildAttack(draftOnly: true);
    await _storage.saveDraftAttack(attack.toDraftJson());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Draft saved locally')),
    );
  }

  MigraineAttack _buildAttack({required bool draftOnly}) {
    return MigraineAttack(
      durationHours: int.tryParse(_durationController.text) ?? 0,
      frequencyPerMonth: int.tryParse(_frequencyController.text) ?? 0,
      location: _location,
      character: _character,
      intensity: int.tryParse(_intensityController.text) ?? 0,
      nausea: _nausea,
      vomit: _vomit,
      phonophobia: _phonophobia,
      photophobia: _photophobia,
      visual: _visual,
      sensory: _sensory,
      dysphasia: _dysphasia,
      dysarthria: _dysarthria,
      vertigo: _vertigo,
      tinnitus: _tinnitus,
      hypoacusis: _hypoacusis,
      diplopia: _diplopia,
      defect: _defect,
      ataxia: _ataxia,
      conscience: _conscience,
      paresthesia: _paresthesia,
      dpf: _dpf,
      patientId: null,
      attackId: _attackIdController.text.trim().isEmpty
          ? null
          : _attackIdController.text.trim(),
      age: int.tryParse(_ageController.text),
      timestamp: DateTime.now(),
      summary: draftOnly ? null : _response?.summary,
      type: draftOnly ? null : _response?.predictedType,
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _submitting = true;
      _response = null;
    });

    try {
      final baseUrl = await _storage.readBaseUrl();
      if (baseUrl == null || baseUrl.isEmpty) {
        throw Exception('API base URL is missing. Set it in Settings.');
      }
      final patientId = await _storage.readPatientId();

      final attack = _buildAttack(draftOnly: false);
      final api = ApiClient(baseUrl: baseUrl);
      final result = await api.submitMigraineAttack(
        attack.copyWith(patientId: patientId),
      );

      final saved = MigraineAttack(
        durationHours: attack.durationHours,
        frequencyPerMonth: attack.frequencyPerMonth,
        location: attack.location,
        character: attack.character,
        intensity: attack.intensity,
        nausea: attack.nausea,
        vomit: attack.vomit,
        phonophobia: attack.phonophobia,
        photophobia: attack.photophobia,
        visual: attack.visual,
        sensory: attack.sensory,
        dysphasia: attack.dysphasia,
        dysarthria: attack.dysarthria,
        vertigo: attack.vertigo,
        tinnitus: attack.tinnitus,
        hypoacusis: attack.hypoacusis,
        diplopia: attack.diplopia,
        defect: attack.defect,
        ataxia: attack.ataxia,
        conscience: attack.conscience,
        paresthesia: attack.paresthesia,
        dpf: attack.dpf,
        type: result.predictedType,
        patientId: patientId,
        attackId: attack.attackId,
        age: attack.age,
        timestamp: DateTime.now(),
        summary: result.summary,
      );

      await _database.insertMigraineAttack(saved);
      await _storage.clearDraftAttack();

      if (!mounted) return;

      setState(() {
        _response = result;
        _showForm = false; // Hide form after successful submission
      });

      _reload(); // Refresh the tracking data

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Attack logged successfully!'),
            ],
          ),
          backgroundColor: Color(0xFFB6F36B),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _submitting = false;
      });
    }
  }

  List<MigraineAttack> _filterByDateRange(List<MigraineAttack> attacks) {
    final now = DateTime.now();
    DateTime startDate;

    switch (_selectedRange) {
      case DateRange.lastWeek:
        startDate = now.subtract(const Duration(days: 7));
        break;
      case DateRange.lastMonth:
        startDate = DateTime(now.year, now.month - 1, now.day);
        break;
      case DateRange.last3Months:
        startDate = DateTime(now.year, now.month - 3, now.day);
        break;
      case DateRange.last6Months:
        startDate = DateTime(now.year, now.month - 6, now.day);
        break;
      case DateRange.lastYear:
        startDate = DateTime(now.year - 1, now.month, now.day);
        break;
      case DateRange.custom:
        if (_customStartDate == null || _customEndDate == null) {
          return attacks;
        }
        return attacks.where((attack) {
          final timestamp = attack.timestamp;
          if (timestamp == null) return false;
          return timestamp.isAfter(_customStartDate!) &&
              timestamp.isBefore(_customEndDate!.add(const Duration(days: 1)));
        }).toList();
      case DateRange.allTime:
        return attacks;
    }

    return attacks.where((attack) {
      final timestamp = attack.timestamp;
      if (timestamp == null) return false;
      return timestamp.isAfter(startDate);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: FutureBuilder<List<MigraineAttack>>(
        future: _attacksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState(theme);
          }

          final allAttacks = snapshot.data!;
          final filteredAttacks = _filterByDateRange(allAttacks);
          final stats = _calculateStatistics(filteredAttacks);

          return RefreshIndicator(
            onRefresh: () async {
              _reload();
            },
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Date Range Selector
                _buildDateRangeSelector(),
                const SizedBox(height: 20),

                // Quick Stats Overview
                _buildQuickStats(stats, theme),
                const SizedBox(height: 24),

                // Attack Frequency Chart
                _buildFrequencySection(filteredAttacks, theme),
                const SizedBox(height: 24),

                // Intensity Analysis
                _buildIntensitySection(filteredAttacks, theme),
                const SizedBox(height: 24),

                // Trigger Analysis
                _buildTriggerSection(filteredAttacks, theme),
                const SizedBox(height: 24),

                // Symptom Patterns
                _buildSymptomSection(filteredAttacks, theme),
                const SizedBox(height: 24),

                // Migraine Type Distribution
                _buildTypeDistribution(filteredAttacks, theme),
                const SizedBox(height: 24),

                // Recent Attacks Timeline
                _buildRecentTimeline(filteredAttacks, theme),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    if (_showForm) {
      // Show the logging form
      return _buildLoggingForm(theme);
    }

    // Show empty state with button
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 80,
              color: Colors.grey.shade600,
            ),
            const SizedBox(height: 24),
            Text(
              'No Tracking Data Yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Start logging your migraine attacks to see detailed statistics, patterns, and insights here.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.brightness == Brightness.dark
                    ? Colors.grey.shade400
                    : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _showForm = true;
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('Log Your First Attack'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeSelector() {
    return Card(
      color: const Color(0xFF171B22),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 20, color: Color(0xFFB6F36B)),
                const SizedBox(width: 8),
                const Text(
                  'Time Period',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: DateRange.values.map((range) {
                final isSelected = _selectedRange == range;
                return ChoiceChip(
                  label: Text(_getDateRangeLabel(range)),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedRange = range;
                        if (range == DateRange.custom) {
                          _showCustomDatePicker();
                        }
                      });
                    }
                  },
                  selectedColor: const Color(0xFFB6F36B),
                  backgroundColor: const Color(0xFF0F1218),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.black : Colors.white,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
            if (_selectedRange == DateRange.custom &&
                _customStartDate != null &&
                _customEndDate != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  '${DateFormat('MMM d, y').format(_customStartDate!)} - ${DateFormat('MMM d, y').format(_customEndDate!)}',
                  style: TextStyle(color: Colors.grey.shade400),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(TrackingStats stats, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Overview',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Attacks',
                '${stats.totalAttacks}',
                Icons.event,
                Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Avg Duration',
                '${stats.avgDuration.toStringAsFixed(1)}h',
                Icons.timer,
                Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Avg Intensity',
                '${stats.avgIntensity.toStringAsFixed(1)}/10',
                Icons.trending_up,
                Colors.purple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Frequency',
                '${stats.attacksPerMonth.toStringAsFixed(1)}/mo',
                Icons.calendar_month,
                Colors.blue,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF171B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrequencySection(List<MigraineAttack> attacks, ThemeData theme) {
    final frequencyData = _calculateFrequencyData(attacks);

    return Card(
      color: const Color(0xFF171B22),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bar_chart, color: Color(0xFFB6F36B), size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Attack Frequency',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (frequencyData.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'No data available for selected period',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              _buildFrequencyChart(frequencyData),
          ],
        ),
      ),
    );
  }

  Widget _buildFrequencyChart(Map<String, int> data) {
    final maxValue = data.values.isEmpty ? 1 : data.values.reduce((a, b) => a > b ? a : b);

    return Column(
      children: data.entries.map((entry) {
        final percentage = maxValue > 0 ? (entry.value / maxValue) : 0.0;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    entry.key,
                    style: const TextStyle(color: Colors.white),
                  ),
                  Text(
                    '${entry.value}',
                    style: const TextStyle(
                      color: Color(0xFFB6F36B),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percentage,
                  backgroundColor: Colors.grey.shade800,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFB6F36B)),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildIntensitySection(List<MigraineAttack> attacks, ThemeData theme) {
    final intensityDist = _calculateIntensityDistribution(attacks);

    return Card(
      color: const Color(0xFF171B22),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.speed, color: Colors.orange, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Pain Intensity Distribution',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildIntensityChart(intensityDist),
          ],
        ),
      ),
    );
  }

  Widget _buildIntensityChart(Map<String, int> distribution) {
    final total = distribution.values.fold(0, (sum, count) => sum + count);

    if (total == 0) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'No intensity data available',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      children: distribution.entries.map((entry) {
        final percentage = (entry.value / total * 100);
        final color = _getIntensityColor(entry.key);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              SizedBox(
                width: 80,
                child: Text(
                  entry.key,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: percentage / 100,
                      child: Container(
                        height: 32,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '${entry.value} (${percentage.toStringAsFixed(0)}%)',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTriggerSection(List<MigraineAttack> attacks, ThemeData theme) {
    final triggerStats = _calculateTriggerStats(attacks);

    return Card(
      color: const Color(0xFF171B22),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber, color: Colors.yellow, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Common Trigger Patterns',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Location and character patterns in your attacks',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            ),
            const SizedBox(height: 16),
            _buildTriggerList(triggerStats),
          ],
        ),
      ),
    );
  }

  Widget _buildTriggerList(Map<String, dynamic> stats) {
    return Column(
      children: [
        if (stats['topLocation'] != null)
          _buildTriggerItem(
            'Most Common Location',
            stats['topLocation']['name'],
            '${stats['topLocation']['count']} attacks (${stats['topLocation']['percentage'].toStringAsFixed(0)}%)',
            Icons.location_on,
            Colors.red,
          ),
        const SizedBox(height: 12),
        if (stats['topCharacter'] != null)
          _buildTriggerItem(
            'Most Common Type',
            stats['topCharacter']['name'],
            '${stats['topCharacter']['count']} attacks (${stats['topCharacter']['percentage'].toStringAsFixed(0)}%)',
            Icons.flash_on,
            Colors.orange,
          ),
      ],
    );
  }

  Widget _buildTriggerItem(
    String label,
    String value,
    String subtext,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1218),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtext,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSymptomSection(List<MigraineAttack> attacks, ThemeData theme) {
    final symptomStats = _calculateSymptomStats(attacks);

    return Card(
      color: const Color(0xFF171B22),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.medical_services, color: Colors.blue, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Most Common Symptoms',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (symptomStats.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'No symptom data available',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: symptomStats.entries.take(10).map((entry) {
                  return Chip(
                    avatar: CircleAvatar(
                      backgroundColor: const Color(0xFFB6F36B),
                      child: Text(
                        '${entry.value}',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    label: Text(entry.key),
                    backgroundColor: const Color(0xFF0F1218),
                    labelStyle: const TextStyle(color: Colors.white),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeDistribution(List<MigraineAttack> attacks, ThemeData theme) {
    final typeStats = _calculateTypeDistribution(attacks);

    if (typeStats.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      color: const Color(0xFF171B22),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.category, color: Colors.purple, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Migraine Type Classification',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'AI-predicted classifications',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            ),
            const SizedBox(height: 16),
            ...typeStats.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        entry.key,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: entry.value['percentage'] / 100,
                                backgroundColor: Colors.grey.shade800,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFFB6F36B),
                                ),
                                minHeight: 8,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 60,
                            child: Text(
                              '${entry.value['count']} (${entry.value['percentage'].toStringAsFixed(0)}%)',
                              style: const TextStyle(
                                color: Color(0xFFB6F36B),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTimeline(List<MigraineAttack> attacks, ThemeData theme) {
    final recentAttacks = attacks.take(5).toList();

    if (recentAttacks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      color: const Color(0xFF171B22),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.timeline, color: Color(0xFFB6F36B), size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Recent Attacks',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...recentAttacks.map((attack) {
              return _buildTimelineItem(attack);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(MigraineAttack attack) {
    final timestamp = attack.timestamp;
    final dateStr = timestamp != null
        ? DateFormat('MMM d, y \'at\' h:mm a').format(timestamp.toLocal())
        : 'Unknown date';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _getIntensityColor('Moderate'),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
              Container(
                width: 2,
                height: 40,
                color: Colors.grey.shade700,
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1218),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dateStr,
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildInfoBadge('${attack.durationHours}h', Icons.timer),
                      const SizedBox(width: 8),
                      _buildInfoBadge('${attack.intensity}/10', Icons.speed),
                      const SizedBox(width: 8),
                      _buildInfoBadge(attack.location, Icons.location_on),
                    ],
                  ),
                  if (attack.type != null && attack.type!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFB6F36B).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        attack.type!,
                        style: const TextStyle(
                          color: Color(0xFFB6F36B),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBadge(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: Colors.grey.shade400),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  // Logging Form Widget
  Widget _buildLoggingForm(ThemeData theme) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header with back button
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _showForm = false;
                  });
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Log Migraine Attack',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ATTACK PATTERN SECTION
          SectionHeader(
            title: 'When did the attack happen?',
            subtitle: 'Help us understand your migraine pattern',
            illustrationIcon: Icons.schedule,
          ),
          const SizedBox(height: 8),
          _largeNumberField(
            controller: _durationController,
            label: 'Duration',
            unit: 'hours',
            description: 'How long did your attack last?',
          ),
          const SizedBox(height: 16),
          _largeNumberField(
            controller: _frequencyController,
            label: 'Frequency',
            unit: 'per month',
            description: 'How often do you experience migraines?',
          ),
          const SizedBox(height: 16),
          CustomDropdown(
            label: 'Location',
            value: _location,
            options: const ['Unilateral', 'Bilateral'],
            onChanged: (value) {
              setState(() {
                _location = value;
              });
            },
            description: 'Is the pain on one side or both sides?',
          ),
          const SizedBox(height: 16),
          CustomDropdown(
            label: 'DPF Pattern',
            value: _dpf,
            options: const ['Pattern1', 'Pattern2', 'Pattern3'],
            onChanged: (value) {
              setState(() {
                _dpf = value;
              });
            },
          ),

          // PAIN DESCRIPTION SECTION
          const SizedBox(height: 24),
          SectionHeader(
            title: 'Describe the pain',
            subtitle: 'Help us understand your symptoms better',
            illustrationIcon: Icons.sentiment_dissatisfied,
          ),
          const SizedBox(height: 8),
          CustomDropdown(
            label: 'How does it feel?',
            value: _character,
            options: const ['Throbbing', 'Pressure'],
            onChanged: (value) {
              setState(() {
                _character = value;
              });
            },
            description: 'Pulsing/throbbing or constant pressure?',
          ),
          const SizedBox(height: 16),
          IntensitySlider(
            value: int.tryParse(_intensityController.text) ?? 5,
            onChanged: (value) {
              setState(() {
                _intensityController.text = value.toString();
              });
            },
            label: 'Pain Intensity',
            description: 'Rate your pain level',
          ),

          // ASSOCIATED SYMPTOMS SECTION
          const SizedBox(height: 24),
          SectionHeader(
            title: 'Associated symptoms',
            subtitle: 'Select any symptoms you experienced',
            illustrationIcon: Icons.health_and_safety,
          ),
          const SizedBox(height: 8),
          SymptomToggle(
            label: 'Nausea',
            description: 'Do you feel nauseous?',
            value: _nausea == 1,
            onChanged: (value) {
              setState(() {
                _nausea = value ? 1 : 0;
              });
            },
          ),
          SymptomToggle(
            label: 'Vomit',
            description: 'Do you feel like you might vomit?',
            value: _vomit == 1,
            onChanged: (value) {
              setState(() {
                _vomit = value ? 1 : 0;
              });
            },
          ),
          SymptomToggle(
            label: 'Sound Sensitivity',
            description: 'Do loud sounds feel uncomfortable?',
            value: _phonophobia == 1,
            onChanged: (value) {
              setState(() {
                _phonophobia = value ? 1 : 0;
              });
            },
          ),
          SymptomToggle(
            label: 'Light Sensitivity',
            description: 'Is bright light painful?',
            value: _photophobia == 1,
            onChanged: (value) {
              setState(() {
                _photophobia = value ? 1 : 0;
              });
            },
          ),
          SymptomToggle(
            label: 'Visual Disturbances',
            description: 'Do you see flashes or spots?',
            value: _visual == 1,
            onChanged: (value) {
              setState(() {
                _visual = value ? 1 : 0;
              });
            },
          ),
          SymptomToggle(
            label: 'Sensory Issues',
            description: 'Any numbness or tingling?',
            value: _sensory == 1,
            onChanged: (value) {
              setState(() {
                _sensory = value ? 1 : 0;
              });
            },
          ),

          // NEUROLOGICAL SYMPTOMS SECTION
          const SizedBox(height: 24),
          SectionHeader(
            title: 'Neurological symptoms',
            subtitle: 'These are more serious - report all you experience',
            illustrationIcon: Icons.psychology,
          ),
          const SizedBox(height: 8),
          SymptomToggle(
            label: 'Speech Difficulty',
            description: 'Dysphasia - trouble finding words?',
            value: _dysphasia == 1,
            onChanged: (value) {
              setState(() {
                _dysphasia = value ? 1 : 0;
              });
            },
          ),
          SymptomToggle(
            label: 'Speech Slurring',
            description: 'Dysarthria - slurred speech?',
            value: _dysarthria == 1,
            onChanged: (value) {
              setState(() {
                _dysarthria = value ? 1 : 0;
              });
            },
          ),
          SymptomToggle(
            label: 'Dizziness',
            description: 'Vertigo - spinning sensation?',
            value: _vertigo == 1,
            onChanged: (value) {
              setState(() {
                _vertigo = value ? 1 : 0;
              });
            },
          ),
          SymptomToggle(
            label: 'Ringing in Ears',
            description: 'Tinnitus - hearing ringing?',
            value: _tinnitus == 1,
            onChanged: (value) {
              setState(() {
                _tinnitus = value ? 1 : 0;
              });
            },
          ),
          SymptomToggle(
            label: 'Hearing Loss',
            description: 'Hypoacusis - reduced hearing?',
            value: _hypoacusis == 1,
            onChanged: (value) {
              setState(() {
                _hypoacusis = value ? 1 : 0;
              });
            },
          ),
          SymptomToggle(
            label: 'Double Vision',
            description: 'Diplopia - seeing double?',
            value: _diplopia == 1,
            onChanged: (value) {
              setState(() {
                _diplopia = value ? 1 : 0;
              });
            },
          ),
          SymptomToggle(
            label: 'Visual Field Defect',
            description: 'Blind spot or missing vision?',
            value: _defect == 1,
            onChanged: (value) {
              setState(() {
                _defect = value ? 1 : 0;
              });
            },
          ),
          SymptomToggle(
            label: 'Loss of Coordination',
            description: 'Ataxia - difficulty balancing?',
            value: _ataxia == 1,
            onChanged: (value) {
              setState(() {
                _ataxia = value ? 1 : 0;
              });
            },
          ),
          SymptomToggle(
            label: 'Loss of Consciousness',
            description: 'Did you lose consciousness?',
            value: _conscience == 1,
            onChanged: (value) {
              setState(() {
                _conscience = value ? 1 : 0;
              });
            },
          ),
          SymptomToggle(
            label: 'Abnormal Sensations',
            description: 'Paresthesia - pins and needles?',
            value: _paresthesia == 1,
            onChanged: (value) {
              setState(() {
                _paresthesia = value ? 1 : 0;
              });
            },
          ),

          // OPTIONAL DETAILS SECTION
          const SizedBox(height: 24),
          SectionHeader(
            title: 'Optional details',
            subtitle: 'Help us personalize your care',
            illustrationIcon: Icons.info,
          ),
          const SizedBox(height: 8),
          _largeNumberField(
            controller: _ageController,
            label: 'Age',
            unit: 'years',
            description: 'Your age (optional)',
            isOptional: true,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _attackIdController,
            decoration: InputDecoration(
              labelText: 'Attack ID (optional)',
              hintText: 'e.g., migraine-2024-01',
            ),
          ),

          // ACTION BUTTONS
          const SizedBox(height: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MigraineButton(
                onPressed: _submitting ? null : () => _submitForm(),
                label: 'Submit to backend',
                icon: Icons.cloud_upload,
                isLoading: _submitting,
              ),
              const SizedBox(height: 12),
              MigraineButton(
                onPressed: _submitting ? null : () => _saveDraft(),
                label: 'Save as draft',
                icon: Icons.save,
                isOutlined: true,
              ),
            ],
          ),

          // RESULT DISPLAY
          if (_response != null) ...[
            const SizedBox(height: 24),
            ResultCard(
              title: 'Prediction Result',
              content: _response!.predictedType,
              icon: Icons.verified,
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
            ),
            const SizedBox(height: 12),
            ResultCard(
              title: 'Summary',
              content: _response!.summary,
              icon: Icons.description,
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _largeNumberField({
    required TextEditingController controller,
    required String label,
    required String unit,
    String? description,
    bool isOptional = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        if (description != null) ...[
          const SizedBox(height: 4),
          Text(
            description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
        ],
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: '0',
                    hintStyle: theme.textTheme.headlineSmall?.copyWith(
                      color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                    ),
                  ),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                  validator: (value) {
                    if (isOptional && (value == null || value.isEmpty)) {
                      return null;
                    }
                    if (value == null || value.isEmpty) {
                      return 'Required';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Enter a number';
                    }
                    return null;
                  },
                ),
              ),
              Text(
                unit,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper methods for calculations

  TrackingStats _calculateStatistics(List<MigraineAttack> attacks) {
    if (attacks.isEmpty) {
      return TrackingStats(
        totalAttacks: 0,
        avgDuration: 0,
        avgIntensity: 0,
        attacksPerMonth: 0,
      );
    }

    final totalDuration = attacks.fold<int>(0, (sum, a) => sum + a.durationHours);
    final totalIntensity = attacks.fold<int>(0, (sum, a) => sum + a.intensity);

    // Calculate attacks per month
    final timestamps = attacks
        .where((a) => a.timestamp != null)
        .map((a) => a.timestamp!)
        .toList();

    double attacksPerMonth = 0;
    if (timestamps.isNotEmpty) {
      timestamps.sort();
      final firstDate = timestamps.first;
      final lastDate = timestamps.last;
      final daysDiff = lastDate.difference(firstDate).inDays;
      final monthsDiff = daysDiff / 30.0;
      attacksPerMonth = monthsDiff > 0 ? attacks.length / monthsDiff : attacks.length.toDouble();
    }

    return TrackingStats(
      totalAttacks: attacks.length,
      avgDuration: totalDuration / attacks.length,
      avgIntensity: totalIntensity / attacks.length,
      attacksPerMonth: attacksPerMonth,
    );
  }

  Map<String, int> _calculateFrequencyData(List<MigraineAttack> attacks) {
    final Map<String, int> data = {};

    for (var attack in attacks) {
      if (attack.timestamp == null) continue;

      final monthYear = DateFormat('MMM yyyy').format(attack.timestamp!);
      data[monthYear] = (data[monthYear] ?? 0) + 1;
    }

    // Sort by date
    final sortedEntries = data.entries.toList()
      ..sort((a, b) {
        try {
          final dateA = DateFormat('MMM yyyy').parse(a.key);
          final dateB = DateFormat('MMM yyyy').parse(b.key);
          return dateA.compareTo(dateB);
        } catch (e) {
          return 0;
        }
      });

    return Map.fromEntries(sortedEntries);
  }

  Map<String, int> _calculateIntensityDistribution(List<MigraineAttack> attacks) {
    final Map<String, int> distribution = {
      'Mild (1-3)': 0,
      'Moderate (4-6)': 0,
      'Severe (7-8)': 0,
      'Extreme (9-10)': 0,
    };

    for (var attack in attacks) {
      if (attack.intensity <= 3) {
        distribution['Mild (1-3)'] = distribution['Mild (1-3)']! + 1;
      } else if (attack.intensity <= 6) {
        distribution['Moderate (4-6)'] = distribution['Moderate (4-6)']! + 1;
      } else if (attack.intensity <= 8) {
        distribution['Severe (7-8)'] = distribution['Severe (7-8)']! + 1;
      } else {
        distribution['Extreme (9-10)'] = distribution['Extreme (9-10)']! + 1;
      }
    }

    return distribution;
  }

  Map<String, dynamic> _calculateTriggerStats(List<MigraineAttack> attacks) {
    if (attacks.isEmpty) return {};

    // Location frequency
    final locationMap = <String, int>{};
    for (var attack in attacks) {
      locationMap[attack.location] = (locationMap[attack.location] ?? 0) + 1;
    }

    // Character frequency
    final characterMap = <String, int>{};
    for (var attack in attacks) {
      characterMap[attack.character] = (characterMap[attack.character] ?? 0) + 1;
    }

    final topLocation = locationMap.entries.reduce((a, b) => a.value > b.value ? a : b);
    final topCharacter = characterMap.entries.reduce((a, b) => a.value > b.value ? a : b);

    return {
      'topLocation': {
        'name': topLocation.key,
        'count': topLocation.value,
        'percentage': (topLocation.value / attacks.length) * 100,
      },
      'topCharacter': {
        'name': topCharacter.key,
        'count': topCharacter.value,
        'percentage': (topCharacter.value / attacks.length) * 100,
      },
    };
  }

  Map<String, int> _calculateSymptomStats(List<MigraineAttack> attacks) {
    final Map<String, int> symptomCounts = {};

    for (var attack in attacks) {
      if (attack.nausea == 1) symptomCounts['Nausea'] = (symptomCounts['Nausea'] ?? 0) + 1;
      if (attack.vomit == 1) symptomCounts['Vomiting'] = (symptomCounts['Vomiting'] ?? 0) + 1;
      if (attack.phonophobia == 1) symptomCounts['Phonophobia'] = (symptomCounts['Phonophobia'] ?? 0) + 1;
      if (attack.photophobia == 1) symptomCounts['Photophobia'] = (symptomCounts['Photophobia'] ?? 0) + 1;
      if (attack.visual == 1) symptomCounts['Visual'] = (symptomCounts['Visual'] ?? 0) + 1;
      if (attack.sensory == 1) symptomCounts['Sensory'] = (symptomCounts['Sensory'] ?? 0) + 1;
      if (attack.dysphasia == 1) symptomCounts['Dysphasia'] = (symptomCounts['Dysphasia'] ?? 0) + 1;
      if (attack.dysarthria == 1) symptomCounts['Dysarthria'] = (symptomCounts['Dysarthria'] ?? 0) + 1;
      if (attack.vertigo == 1) symptomCounts['Vertigo'] = (symptomCounts['Vertigo'] ?? 0) + 1;
      if (attack.tinnitus == 1) symptomCounts['Tinnitus'] = (symptomCounts['Tinnitus'] ?? 0) + 1;
      if (attack.hypoacusis == 1) symptomCounts['Hypoacusis'] = (symptomCounts['Hypoacusis'] ?? 0) + 1;
      if (attack.diplopia == 1) symptomCounts['Diplopia'] = (symptomCounts['Diplopia'] ?? 0) + 1;
      if (attack.defect == 1) symptomCounts['Visual Defect'] = (symptomCounts['Visual Defect'] ?? 0) + 1;
      if (attack.ataxia == 1) symptomCounts['Ataxia'] = (symptomCounts['Ataxia'] ?? 0) + 1;
      if (attack.conscience == 1) symptomCounts['Consciousness'] = (symptomCounts['Consciousness'] ?? 0) + 1;
      if (attack.paresthesia == 1) symptomCounts['Paresthesia'] = (symptomCounts['Paresthesia'] ?? 0) + 1;
    }

    // Sort by frequency
    final sortedEntries = symptomCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Map.fromEntries(sortedEntries);
  }

  Map<String, Map<String, dynamic>> _calculateTypeDistribution(List<MigraineAttack> attacks) {
    final typeCounts = <String, int>{};

    for (var attack in attacks) {
      if (attack.type != null && attack.type!.isNotEmpty) {
        typeCounts[attack.type!] = (typeCounts[attack.type!] ?? 0) + 1;
      }
    }

    final total = typeCounts.values.fold(0, (sum, count) => sum + count);
    if (total == 0) return {};

    return typeCounts.map((type, count) {
      return MapEntry(type, {
        'count': count,
        'percentage': (count / total) * 100,
      });
    });
  }

  Color _getIntensityColor(String intensity) {
    if (intensity.contains('Mild')) return Colors.green;
    if (intensity.contains('Moderate')) return Colors.orange;
    if (intensity.contains('Severe')) return Colors.red;
    if (intensity.contains('Extreme')) return Colors.purple;
    return Colors.grey;
  }

  String _getDateRangeLabel(DateRange range) {
    switch (range) {
      case DateRange.lastWeek:
        return 'Last Week';
      case DateRange.lastMonth:
        return 'Last Month';
      case DateRange.last3Months:
        return '3 Months';
      case DateRange.last6Months:
        return '6 Months';
      case DateRange.lastYear:
        return 'Year';
      case DateRange.custom:
        return 'Custom';
      case DateRange.allTime:
        return 'All Time';
    }
  }

  void _showCustomDatePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _customStartDate != null && _customEndDate != null
          ? DateTimeRange(start: _customStartDate!, end: _customEndDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFB6F36B),
              onPrimary: Colors.black,
              surface: Color(0xFF171B22),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _customStartDate = picked.start;
        _customEndDate = picked.end;
      });
    }
  }
}

// Data models

enum DateRange {
  lastWeek,
  lastMonth,
  last3Months,
  last6Months,
  lastYear,
  custom,
  allTime,
}

class TrackingStats {
  final int totalAttacks;
  final double avgDuration;
  final double avgIntensity;
  final double attacksPerMonth;

  TrackingStats({
    required this.totalAttacks,
    required this.avgDuration,
    required this.avgIntensity,
    required this.attacksPerMonth,
  });
}

