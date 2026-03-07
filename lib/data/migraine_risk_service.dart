import 'models.dart';

/// Simple migraine risk prediction from frequency, triggers, and recent attacks.
class MigraineRiskService {
  /// [attacks] should be recent (e.g. last 30–90 days) for trend.
  MigraineRiskResult calculateRisk(List<MigraineAttack> attacks) {
    if (attacks.isEmpty) {
      return MigraineRiskResult(
        score: 0,
        factors: ['No attack history yet. Log attacks to get risk insights.'],
      );
    }

    final now = DateTime.now();
    final last30 = attacks.where((a) {
      final t = a.timestamp;
      if (t == null) return false;
      return t.isAfter(now.subtract(const Duration(days: 30)));
    }).toList();
    final last7 = attacks.where((a) {
      final t = a.timestamp;
      if (t == null) return false;
      return t.isAfter(now.subtract(const Duration(days: 7)));
    }).toList();

    int score = 0;
    final factors = <String>[];

    // Frequency trend: more attacks recently -> higher risk
    final avgPerMonth = last30.isEmpty ? 0.0 : last30.length / (30 / 30);
    if (avgPerMonth >= 4) {
      score += 25;
      factors.add('High attack frequency in the last 30 days');
    } else if (avgPerMonth >= 2) {
      score += 15;
      factors.add('Moderate attack frequency recently');
    }

    // Recent attacks: attack in last 7 days -> higher risk
    if (last7.length >= 2) {
      score += 25;
      factors.add('Multiple attacks in the past week');
    } else if (last7.length == 1) {
      score += 15;
      factors.add('Recent attack in the past week');
    }

    // Triggers: common triggers in recent attacks
    final triggerCounts = <String, int>{};
    for (final a in last30) {
      for (final t in a.triggers) {
        if (t.isNotEmpty) triggerCounts[t] = (triggerCounts[t] ?? 0) + 1;
      }
    }
    final topTriggers = triggerCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (topTriggers.isNotEmpty && topTriggers.first.value >= 2) {
      score += 20;
      factors.add('Recurring trigger: ${topTriggers.first.key}');
    }
    if (topTriggers.length >= 2) {
      score += 10;
      factors.add('Multiple triggers often present');
    }

    // Intensity: high intensity recent attacks
    final avgIntensity = last30.isEmpty
        ? 0.0
        : last30.map((a) => a.intensity).reduce((a, b) => a + b) / last30.length;
    if (avgIntensity >= 7) {
      score += 15;
      factors.add('Recent attacks were severe (high intensity)');
    }

    if (factors.isEmpty) {
      factors.add('Low recent activity');
    }

    score = score.clamp(0, 100);
    return MigraineRiskResult(score: score, factors: factors);
  }
}

class MigraineRiskResult {
  final int score;
  final List<String> factors;

  MigraineRiskResult({required this.score, required this.factors});

  bool get isHigh => score > 70;
}
