import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Dark card surface; aligns with History / Settings / `scaffoldBackgroundColor` in the app theme.
const _kSurface = Color(0xFF171B22);
const _kAccent = Color(0xFFB6F36B);

class AnalyticsCard extends StatelessWidget {
  const AnalyticsCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final outline = _kAccent.withValues(alpha: 0.22);
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class AnalyticsFilterChips extends StatelessWidget {
  const AnalyticsFilterChips({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options
            .map(
              (option) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(option),
                  selected: option == selected,
                  onSelected: (_) => onSelected(option),
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: option == selected ? _kAccent : scheme.onSurfaceVariant,
                  ),
                  selectedColor: _kAccent.withValues(alpha: 0.2),
                  backgroundColor: _kSurface,
                  side: BorderSide(
                    color: option == selected
                        ? _kAccent.withValues(alpha: 0.5)
                        : scheme.outline.withValues(alpha: 0.35),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class TrendToggle extends StatelessWidget {
  const TrendToggle({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final options = <String>['Week', 'Month'];
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options
            .map(
              (option) => GestureDetector(
                onTap: () => onChanged(option),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: selected == option
                        ? _kAccent.withValues(alpha: 0.22)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    option,
                    style: TextStyle(
                      color: selected == option ? _kAccent : scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class TrendPoint {
  const TrendPoint({
    required this.label,
    required this.value,
    required this.isSpike,
  });

  final String label;
  final int value;
  final bool isSpike;
}

class MiniLineChart extends StatelessWidget {
  const MiniLineChart({
    super.key,
    required this.points,
  });

  final List<TrendPoint> points;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 150,
      child: CustomPaint(
        painter: _LineChartPainter(
          points,
          lineColor: _kAccent,
          spikeColor: scheme.error,
          gridColor: scheme.outline.withValues(alpha: 0.35),
          fillColor: _kAccent.withValues(alpha: 0.12),
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: 124, left: 6, right: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: points
                .map(
                  (point) => Expanded(
                    child: Text(
                      point.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter(
    this.points, {
    required this.lineColor,
    required this.spikeColor,
    required this.gridColor,
    required this.fillColor,
  });

  final List<TrendPoint> points;
  final Color lineColor;
  final Color spikeColor;
  final Color gridColor;
  final Color fillColor;

  @override
  void paint(Canvas canvas, Size size) {
    final chartHeight = size.height - 26;
    if (points.isEmpty || chartHeight <= 0) {
      return;
    }

    final maxValue = points
        .map((point) => point.value)
        .fold<int>(1, (current, value) => math.max(current, value));

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = chartHeight * (i / 3);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final pointsOffset = <Offset>[];
    for (var i = 0; i < points.length; i++) {
      final dx = points.length == 1
          ? size.width / 2
          : (size.width / (points.length - 1)) * i;
      final normalized = points[i].value / maxValue;
      final dy = chartHeight - (normalized * (chartHeight - 8));
      pointsOffset.add(Offset(dx, dy));
    }

    final linePath = Path()..moveTo(pointsOffset.first.dx, pointsOffset.first.dy);
    for (var i = 1; i < pointsOffset.length; i++) {
      linePath.lineTo(pointsOffset[i].dx, pointsOffset[i].dy);
    }

    final fillPath = Path.from(linePath)
      ..lineTo(pointsOffset.last.dx, chartHeight)
      ..lineTo(pointsOffset.first.dx, chartHeight)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill,
    );

    canvas.drawPath(
      linePath,
      Paint()
        ..color = lineColor
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    for (var i = 0; i < pointsOffset.length; i++) {
      final isSpike = points[i].isSpike;
      final color = isSpike ? spikeColor : lineColor;
      canvas.drawCircle(pointsOffset[i], isSpike ? 5.5 : 4.5, Paint()..color = color);
      canvas.drawCircle(
        pointsOffset[i],
        isSpike ? 2.5 : 2,
        Paint()..color = Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.spikeColor != spikeColor ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.fillColor != fillColor;
  }
}

class DistributionBars extends StatelessWidget {
  const DistributionBars({
    super.key,
    required this.low,
    required this.medium,
    required this.high,
  });

  final int low;
  final int medium;
  final int high;

  @override
  Widget build(BuildContext context) {
    final maxValue = math.max(1, math.max(low, math.max(medium, high)));

    return Row(
      children: [
        _IntensityBar(
          label: 'Low',
          value: low,
          maxValue: maxValue,
          color: _kAccent.withValues(alpha: 0.35),
        ),
        const SizedBox(width: 12),
        _IntensityBar(
          label: 'Medium',
          value: medium,
          maxValue: maxValue,
          color: _kAccent.withValues(alpha: 0.58),
        ),
        const SizedBox(width: 12),
        _IntensityBar(
          label: 'High',
          value: high,
          maxValue: maxValue,
          color: _kAccent,
        ),
      ],
    );
  }
}

class _IntensityBar extends StatelessWidget {
  const _IntensityBar({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.color,
  });

  final String label;
  final int value;
  final int maxValue;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ratio = value / maxValue;
    return Expanded(
      child: Column(
        children: [
          SizedBox(
            height: 96,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOut,
                width: 46,
                height: math.max(8, 90 * ratio),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            '$value',
            style: TextStyle(
              color: scheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class TriggerTile extends StatelessWidget {
  const TriggerTile({
    super.key,
    required this.icon,
    required this.title,
    required this.percent,
  });

  final IconData icon;
  final String title;
  final int percent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kAccent.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: _kAccent.withValues(alpha: 0.18),
            child: Icon(icon, size: 16, color: _kAccent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
          ),
          Text(
            '$percent%',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: _kAccent,
            ),
          ),
        ],
      ),
    );
  }
}

class MedicationTile extends StatelessWidget {
  const MedicationTile({
    super.key,
    required this.name,
    required this.successRate,
    required this.monthlyUses,
  });

  final String name;
  final int successRate;
  final int monthlyUses;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
            ),
            Text(
              '$successRate% relief',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: _kAccent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: successRate / 100,
            backgroundColor: scheme.outline.withValues(alpha: 0.25),
            valueColor: const AlwaysStoppedAnimation<Color>(_kAccent),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$monthlyUses uses this month',
          style: TextStyle(
            color: scheme.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class InsightTile extends StatelessWidget {
  const InsightTile({
    super.key,
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kAccent.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: _kAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: scheme.onSurface.withValues(alpha: 0.92),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AnalyticsSkeleton extends StatelessWidget {
  const AnalyticsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        _SkeletonBlock(height: 130),
        SizedBox(height: 14),
        _SkeletonBlock(height: 52),
        SizedBox(height: 14),
        _SkeletonBlock(height: 210),
        SizedBox(height: 14),
        _SkeletonBlock(height: 180),
        SizedBox(height: 14),
        _SkeletonBlock(height: 165),
      ],
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kAccent.withValues(alpha: 0.12)),
      ),
    );
  }
}

