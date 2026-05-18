import 'package:flutter/material.dart';

import '../data/patient_analytics_api.dart';

const _kAccent = Color(0xFFB6F36B);
const _kSurface = Color(0xFF171B22);

class NextAttackForecastCard extends StatelessWidget {
  const NextAttackForecastCard({
    super.key,
    required this.data,
    this.disclaimer,
  });

  final PatientNextAttackData data;
  final String? disclaimer;

  String _tierLabel() {
    if (data.usedHistoryFallback) return 'Based on your history';
    switch (data.confidenceTier) {
      case 'high':
        return 'High confidence';
      case 'medium':
        return 'Moderate confidence';
      default:
        return 'Low model confidence';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

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
          if (data.confidenceCaption != null && data.confidenceCaption!.isNotEmpty)
            Text(
              data.confidenceCaption!,
              style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            )
          else
            Text(
              'From your last ${data.basedOnRecords} logged episode${data.basedOnRecords == 1 ? '' : 's'}. '
              'For planning only—not medical advice.',
              style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _kSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade700.withValues(alpha: 0.35)),
            ),
            child: Text(
              [
                _tierLabel(),
                if (data.typeConfidencePercent != null && !data.usedHistoryFallback)
                  '${data.typeConfidencePercent}%',
              ].join(' · '),
              style: theme.textTheme.labelSmall?.copyWith(color: Colors.amber.shade100),
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
          if (data.usedHistoryFallback &&
              data.modelPredictedType != null &&
              data.modelPredictedType!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Model suggested: ${_formatType(data.modelPredictedType!)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.amber.shade200.withValues(alpha: 0.85),
                fontSize: 11,
              ),
            ),
          ],
          if (data.topTypes.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Top possible patterns',
              style: theme.textTheme.labelMedium?.copyWith(
                color: Colors.amber.shade200,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: data.topTypes.take(3).map((t) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _kSurface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _kAccent.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    '${t.labelDisplay} (${(t.probability * 100).round()}%)',
                    style: theme.textTheme.bodySmall,
                  ),
                );
              }).toList(),
            ),
          ],
          if (data.duration != null || data.frequency != null || data.intensity != null) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                if (data.duration != null)
                  Text(
                    'Est. ${data.duration!.toStringAsFixed(1)} h',
                    style: theme.textTheme.bodySmall?.copyWith(color: _kAccent),
                  ),
                if (data.frequency != null)
                  Text(
                    'Episodes/mo ${data.frequency!.round()}',
                    style: theme.textTheme.bodySmall?.copyWith(color: _kAccent),
                  ),
                if (data.intensity != null)
                  Text(
                    'Intensity ${data.intensity!.toStringAsFixed(1)}/10',
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
              children: data.symptomsLikely.take(8).map((s) {
                final pct = s.probability != null ? ' (${(s.probability! * 100).round()}%)' : '';
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _kSurface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _kAccent.withValues(alpha: 0.2)),
                  ),
                  child: Text('${s.name}$pct', style: theme.textTheme.bodySmall),
                );
              }).toList(),
            ),
          ],
          if (data.displayDisclaimer != null && data.displayDisclaimer!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              data.displayDisclaimer!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ],
          if (disclaimer != null && disclaimer!.isNotEmpty) ...[
            const SizedBox(height: 8),
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

  static String _formatType(String raw) {
    return raw
        .split('_')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }
}
