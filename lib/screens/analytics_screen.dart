import 'package:flutter/material.dart';

import '../data/database.dart';
import '../data/models.dart';
import '../widgets/analytics_widgets.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final _database = PainpalDatabase.instance;

  String _selectedRange = 'Last 30 days';
  String _selectedTrendView = 'Week';
  late Future<_AnalyticsViewModel> _analyticsFuture;

  @override
  void initState() {
	super.initState();
	_analyticsFuture = _loadAnalytics();
  }

  Future<_AnalyticsViewModel> _loadAnalytics() async {
	await Future<void>.delayed(const Duration(milliseconds: 600));
	final attacks = await _database.fetchMigraineAttacks();

	final cutoff = DateTime.now().subtract(Duration(days: _rangeDays));
	final filtered = attacks
		.where((attack) => (attack.timestamp ?? DateTime.now()).isAfter(cutoff))
		.toList();

	final samples = filtered.isEmpty
		? _dummySamplesForRange(_rangeDays)
		: filtered
			.map(
			  (attack) => _AttackSample(
				date: attack.timestamp ?? DateTime.now(),
				intensity: attack.intensity,
				durationHours: attack.durationHours,
			  ),
			)
			.toList();

	final totalMigraines = samples.length;
	final avgIntensity = totalMigraines == 0
		? 0.0
		: samples
				.map((sample) => sample.intensity)
				.reduce((a, b) => a + b) /
			totalMigraines;
	final avgDuration = totalMigraines == 0
		? 0.0
		: samples
				.map((sample) => sample.durationHours)
				.reduce((a, b) => a + b) /
			totalMigraines;

	final low = samples.where((sample) => sample.intensity <= 3).length;
	final medium = samples
		.where((sample) => sample.intensity >= 4 && sample.intensity <= 6)
		.length;
	final high = samples.where((sample) => sample.intensity >= 7).length;

	final trendPoints = _buildTrendPoints(samples);
	final triggers = _dummyTriggerData();
	final medications = _dummyMedicationData(avgIntensity);
	final warning = medications.any((item) => item.monthlyUses >= 11)
		? 'You may be overusing medication. Consider discussing this with your clinician.'
		: null;

	final mostCommonTrigger = triggers.reduce(
	  (current, next) => current.percent >= next.percent ? current : next,
	);

	return _AnalyticsViewModel(
	  totalMigraines: totalMigraines,
	  averageIntensity: avgIntensity,
	  averageDuration: avgDuration,
	  lowPainCount: low,
	  mediumPainCount: medium,
	  highPainCount: high,
	  trend: trendPoints,
	  triggers: triggers,
	  medications: medications,
	  aiSummary:
		  'Your migraines increased this week and are often triggered by ${mostCommonTrigger.label.toLowerCase()}.',
	  mostCommonTrigger: mostCommonTrigger.label,
	  warning: warning,
	  aiInsights: _buildAiInsights(
		trendPoints: trendPoints,
		averageIntensity: avgIntensity,
		averageDuration: avgDuration,
	  ),
	);
  }

  int get _rangeDays {
	switch (_selectedRange) {
	  case 'Last 7 days':
		return 7;
	  case 'Last 3 months':
		return 90;
	  default:
		return 30;
	}
  }

  List<TrendPoint> _buildTrendPoints(List<_AttackSample> samples) {
	if (samples.isEmpty) {
	  return const [
		TrendPoint(label: 'W1', value: 0, isSpike: false),
	  ];
	}

	final now = DateTime.now();
	if (_selectedTrendView == 'Month') {
	  final startMonth = DateTime(now.year, now.month - 2, 1);
	  final points = <TrendPoint>[];
	  for (var offset = 0; offset < 3; offset++) {
		final monthStart = DateTime(startMonth.year, startMonth.month + offset, 1);
		final monthEnd = DateTime(monthStart.year, monthStart.month + 1, 1);
		final count = samples
			.where((sample) => sample.date.isAfter(monthStart) && sample.date.isBefore(monthEnd))
			.length;
		points.add(
		  TrendPoint(
			label: _monthLabel(monthStart.month),
			value: count,
			isSpike: false,
		  ),
		);
	  }
	  final average = points.map((point) => point.value).fold<int>(0, (a, b) => a + b) /
		  points.length;
	  return points
		  .map(
			(point) => TrendPoint(
			  label: point.label,
			  value: point.value,
			  isSpike: point.value >= (average + 1),
			),
		  )
		  .toList();
	}

	final weeks = (_rangeDays / 7).ceil();
	final points = <TrendPoint>[];
	for (var week = weeks - 1; week >= 0; week--) {
	  final end = now.subtract(Duration(days: week * 7));
	  final start = end.subtract(const Duration(days: 7));
	  final count = samples
		  .where((sample) => sample.date.isAfter(start) && sample.date.isBefore(end))
		  .length;
	  points.add(
		TrendPoint(
		  label: 'W${points.length + 1}',
		  value: count,
		  isSpike: false,
		),
	  );
	}

	final average = points.map((point) => point.value).fold<int>(0, (a, b) => a + b) /
		points.length;
	return points
		.map(
		  (point) => TrendPoint(
			label: point.label,
			value: point.value,
			isSpike: point.value >= (average + 1),
		  ),
		)
		.toList();
  }

  String _monthLabel(int month) {
	const labels = <String>[
	  'Jan',
	  'Feb',
	  'Mar',
	  'Apr',
	  'May',
	  'Jun',
	  'Jul',
	  'Aug',
	  'Sep',
	  'Oct',
	  'Nov',
	  'Dec',
	];
	return labels[(month - 1) % 12];
  }

  List<_AttackSample> _dummySamplesForRange(int days) {
	final count = days <= 7
		? 5
		: days <= 30
			? 12
			: 26;
	final now = DateTime.now();
	return List<_AttackSample>.generate(count, (index) {
	  final dayOffset = (index * (days / count)).floor();
	  return _AttackSample(
		date: now.subtract(Duration(days: dayOffset)),
		intensity: 4 + (index % 5),
		durationHours: 2 + (index % 4),
	  );
	});
  }

  List<_TriggerData> _dummyTriggerData() {
	if (_selectedRange == 'Last 7 days') {
	  return const [
		_TriggerData(label: 'Stress', percent: 48, icon: Icons.psychology_alt_outlined),
		_TriggerData(label: 'Sleep Issues', percent: 31, icon: Icons.bedtime_outlined),
		_TriggerData(label: 'Food', percent: 21, icon: Icons.restaurant_outlined),
	  ];
	}
	return const [
	  _TriggerData(label: 'Stress', percent: 45, icon: Icons.psychology_alt_outlined),
	  _TriggerData(label: 'Sleep Issues', percent: 30, icon: Icons.bedtime_outlined),
	  _TriggerData(label: 'Food', percent: 25, icon: Icons.restaurant_outlined),
	];
  }

  List<_MedicationData> _dummyMedicationData(double averageIntensity) {
	final base = averageIntensity >= 7 ? 62 : 74;
	return [
	  _MedicationData(name: 'Sumatriptan', successRate: base + 8, monthlyUses: 12),
	  _MedicationData(name: 'Naproxen', successRate: base - 6, monthlyUses: 8),
	  _MedicationData(name: 'Ibuprofen', successRate: base - 12, monthlyUses: 6),
	];
  }

  List<String> _buildAiInsights({
	required List<TrendPoint> trendPoints,
	required double averageIntensity,
	required double averageDuration,
  }) {
	final hasSpike = trendPoints.any((point) => point.isSpike);
	final insights = <String>[];

	if (hasSpike) {
	  insights.add('A clear spike appears in your recent trend. Plan extra rest on high-risk days.');
	}

	if (averageIntensity >= 7) {
	  insights.add('Pain severity is trending high. Consider early intervention at first warning signs.');
	} else {
	  insights.add('Average pain is in a moderate range. Your current coping plan may be helping.');
	}

	if (averageDuration >= 4) {
	  insights.add('Attacks are lasting longer than usual. Discuss preventive options with your clinician.');
	} else {
	  insights.add('Most attacks are shorter lately, which may indicate improving control.');
	}

	insights.add('Possible migraine with aura pattern detected. Keep tracking visual symptoms.');
	return insights.take(3).toList();
  }

  @override
  Widget build(BuildContext context) {
	return Scaffold(
	  backgroundColor: const Color(0xFFF2F6FB),
	  appBar: AppBar(
		backgroundColor: const Color(0xFFF2F6FB),
		elevation: 0,
		scrolledUnderElevation: 0,
		title: const Text(
		  'Analytics',
		  style: TextStyle(
			color: Color(0xFF17324D),
			fontWeight: FontWeight.w800,
		  ),
		),
	  ),
	  body: FutureBuilder<_AnalyticsViewModel>(
		future: _analyticsFuture,
		builder: (context, snapshot) {
		  if (snapshot.connectionState == ConnectionState.waiting) {
			return const AnalyticsSkeleton();
		  }

		  if (!snapshot.hasData) {
			return const Center(child: Text('No analytics yet'));
		  }

		  final data = snapshot.data!;

		  return RefreshIndicator(
			onRefresh: () async {
			  setState(() {
				_analyticsFuture = _loadAnalytics();
			  });
			  await _analyticsFuture;
			},
			child: SingleChildScrollView(
			  physics: const BouncingScrollPhysics(
				parent: AlwaysScrollableScrollPhysics(),
			  ),
			  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
			  child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
				  AnalyticsCard(
					child: Column(
					  crossAxisAlignment: CrossAxisAlignment.start,
					  children: [
						const Text(
						  'This month at a glance',
						  style: TextStyle(
							fontSize: 17,
							color: Color(0xFF123E67),
							fontWeight: FontWeight.w800,
						  ),
						),
						const SizedBox(height: 14),
						Row(
						  children: [
							Expanded(
							  child: _SummaryMetric(
								label: 'Migraine total',
								value: '${data.totalMigraines}',
							  ),
							),
							Expanded(
							  child: _SummaryMetric(
								label: 'Avg pain',
								value: data.averageIntensity.toStringAsFixed(1),
							  ),
							),
							Expanded(
							  child: _SummaryMetric(
								label: 'Top trigger',
								value: data.mostCommonTrigger,
							  ),
							),
						  ],
						),
						const SizedBox(height: 14),
						Container(
						  padding: const EdgeInsets.all(12),
						  decoration: BoxDecoration(
							color: const Color(0xFFE9F3FF),
							borderRadius: BorderRadius.circular(12),
						  ),
						  child: Row(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
							  const Icon(Icons.auto_awesome, color: Color(0xFF1D5D99)),
							  const SizedBox(width: 10),
							  Expanded(
								child: Text(
								  data.aiSummary,
								  style: const TextStyle(
									color: Color(0xFF1E476D),
									fontWeight: FontWeight.w600,
								  ),
								),
							  ),
							],
						  ),
						),
					  ],
					),
				  ),
				  const SizedBox(height: 14),
				  AnalyticsFilterChips(
					options: const ['Last 7 days', 'Last 30 days', 'Last 3 months'],
					selected: _selectedRange,
					onSelected: (value) {
					  setState(() {
						_selectedRange = value;
						_analyticsFuture = _loadAnalytics();
					  });
					},
				  ),
				  const SizedBox(height: 14),
				  AnalyticsCard(
					child: Column(
					  crossAxisAlignment: CrossAxisAlignment.start,
					  children: [
						Row(
						  children: [
							const Expanded(
							  child: Text(
								'Migraine trends',
								style: TextStyle(
								  fontSize: 16,
								  color: Color(0xFF17324D),
								  fontWeight: FontWeight.w800,
								),
							  ),
							),
							TrendToggle(
							  selected: _selectedTrendView,
							  onChanged: (value) {
								setState(() {
								  _selectedTrendView = value;
								  _analyticsFuture = _loadAnalytics();
								});
							  },
							),
						  ],
						),
						const SizedBox(height: 14),
						MiniLineChart(points: data.trend),
						if (data.trend.any((point) => point.isSpike)) ...[
						  const SizedBox(height: 8),
						  const Text(
							'Red points show spikes.',
							style: TextStyle(
							  color: Color(0xFFB91C1C),
							  fontSize: 12,
							  fontWeight: FontWeight.w700,
							),
						  ),
						],
					  ],
					),
				  ),
				  const SizedBox(height: 14),
				  AnalyticsCard(
					child: Column(
					  crossAxisAlignment: CrossAxisAlignment.start,
					  children: [
						const Text(
						  'Pain and duration',
						  style: TextStyle(
							fontSize: 16,
							color: Color(0xFF17324D),
							fontWeight: FontWeight.w800,
						  ),
						),
						const SizedBox(height: 12),
						DistributionBars(
						  low: data.lowPainCount,
						  medium: data.mediumPainCount,
						  high: data.highPainCount,
						),
						const SizedBox(height: 12),
						Text(
						  'Average duration per attack: ${data.averageDuration.toStringAsFixed(1)} hours',
						  style: const TextStyle(
							color: Color(0xFF2E4A62),
							fontWeight: FontWeight.w700,
						  ),
						),
					  ],
					),
				  ),
				  const SizedBox(height: 14),
				  AnalyticsCard(
					child: Column(
					  crossAxisAlignment: CrossAxisAlignment.start,
					  children: [
						const Text(
						  'Trigger insights',
						  style: TextStyle(
							fontSize: 16,
							color: Color(0xFF17324D),
							fontWeight: FontWeight.w800,
						  ),
						),
						const SizedBox(height: 12),
						...data.triggers
							.map(
							  (item) => Padding(
								padding: const EdgeInsets.only(bottom: 10),
								child: TriggerTile(
								  icon: item.icon,
								  title: item.label,
								  percent: item.percent,
								),
							  ),
							)
							.toList(),
					  ],
					),
				  ),
				  const SizedBox(height: 14),
				  AnalyticsCard(
					child: Column(
					  crossAxisAlignment: CrossAxisAlignment.start,
					  children: [
						const Text(
						  'Medication effectiveness',
						  style: TextStyle(
							fontSize: 16,
							color: Color(0xFF17324D),
							fontWeight: FontWeight.w800,
						  ),
						),
						const SizedBox(height: 12),
						...data.medications
							.map(
							  (item) => Padding(
								padding: const EdgeInsets.only(bottom: 12),
								child: MedicationTile(
								  name: item.name,
								  successRate: item.successRate,
								  monthlyUses: item.monthlyUses,
								),
							  ),
							)
							.toList(),
						if (data.warning != null)
						  Container(
							padding: const EdgeInsets.all(12),
							decoration: BoxDecoration(
							  color: const Color(0xFFFFF3E8),
							  borderRadius: BorderRadius.circular(12),
							  border: Border.all(color: const Color(0xFFFFD6AE)),
							),
							child: Row(
							  crossAxisAlignment: CrossAxisAlignment.start,
							  children: [
								const Icon(Icons.warning_amber_rounded, color: Color(0xFFB45309)),
								const SizedBox(width: 10),
								Expanded(
								  child: Text(
									data.warning!,
									style: const TextStyle(
									  color: Color(0xFF7C2D12),
									  fontWeight: FontWeight.w600,
									),
								  ),
								),
							  ],
							),
						  ),
					  ],
					),
				  ),
				  const SizedBox(height: 14),
				  AnalyticsCard(
					child: Column(
					  crossAxisAlignment: CrossAxisAlignment.start,
					  children: [
						const Text(
						  'AI insights',
						  style: TextStyle(
							fontSize: 16,
							color: Color(0xFF17324D),
							fontWeight: FontWeight.w800,
						  ),
						),
						const SizedBox(height: 12),
						...data.aiInsights
							.map(
							  (insight) => Padding(
								padding: const EdgeInsets.only(bottom: 10),
								child: InsightTile(
								  icon: Icons.insights_outlined,
								  text: insight,
								),
							  ),
							)
							.toList(),
					  ],
					),
				  ),
				],
			  ),
			),
		  );
		},
	  ),
	);
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
	required this.label,
	required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
	return Column(
	  crossAxisAlignment: CrossAxisAlignment.start,
	  children: [
		Text(
		  value,
		  maxLines: 1,
		  overflow: TextOverflow.ellipsis,
		  style: const TextStyle(
			fontSize: 20,
			fontWeight: FontWeight.w800,
			color: Color(0xFF0C3E66),
		  ),
		),
		const SizedBox(height: 3),
		Text(
		  label,
		  style: const TextStyle(
			color: Color(0xFF607A92),
			fontSize: 12,
			fontWeight: FontWeight.w600,
		  ),
		),
	  ],
	);
  }
}

class _AnalyticsViewModel {
  const _AnalyticsViewModel({
	required this.totalMigraines,
	required this.averageIntensity,
	required this.averageDuration,
	required this.lowPainCount,
	required this.mediumPainCount,
	required this.highPainCount,
	required this.trend,
	required this.triggers,
	required this.medications,
	required this.aiSummary,
	required this.mostCommonTrigger,
	required this.aiInsights,
	this.warning,
  });

  final int totalMigraines;
  final double averageIntensity;
  final double averageDuration;
  final int lowPainCount;
  final int mediumPainCount;
  final int highPainCount;
  final List<TrendPoint> trend;
  final List<_TriggerData> triggers;
  final List<_MedicationData> medications;
  final String aiSummary;
  final String mostCommonTrigger;
  final List<String> aiInsights;
  final String? warning;
}

class _AttackSample {
  const _AttackSample({
	required this.date,
	required this.intensity,
	required this.durationHours,
  });

  final DateTime date;
  final int intensity;
  final int durationHours;
}

class _TriggerData {
  const _TriggerData({
	required this.label,
	required this.percent,
	required this.icon,
  });

  final String label;
  final int percent;
  final IconData icon;
}

class _MedicationData {
  const _MedicationData({
	required this.name,
	required this.successRate,
	required this.monthlyUses,
  });

  final String name;
  final int successRate;
  final int monthlyUses;
}

