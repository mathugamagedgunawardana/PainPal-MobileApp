import 'dart:math' as math;

import 'package:flutter/material.dart';

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
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDDE7F4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F2D4A),
            blurRadius: 16,
            offset: Offset(0, 6),
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
                    color: option == selected
                        ? const Color(0xFF114D83)
                        : const Color(0xFF385670),
                  ),
                  selectedColor: const Color(0xFFD9ECFF),
                  backgroundColor: const Color(0xFFF5F8FC),
                  side: const BorderSide(color: Color(0xFFD4E1F1)),
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
    final options = <String>['Week', 'Month'];
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF2F7FC),
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
                        ? const Color(0xFFD9ECFF)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    option,
                    style: TextStyle(
                      color: selected == option
                          ? const Color(0xFF114D83)
                          : const Color(0xFF5F7892),
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
    return SizedBox(
      height: 150,
      child: CustomPaint(
        painter: _LineChartPainter(points),
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
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF6A8097),
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
  _LineChartPainter(this.points);

  final List<TrendPoint> points;

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
      ..color = const Color(0xFFDDE7F4)
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
        ..color = const Color(0xFF3B82F6).withValues(alpha: 0.12)
        ..style = PaintingStyle.fill,
    );

    canvas.drawPath(
      linePath,
      Paint()
        ..color = const Color(0xFF3B82F6)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    for (var i = 0; i < pointsOffset.length; i++) {
      final isSpike = points[i].isSpike;
      final color = isSpike ? const Color(0xFFEF4444) : const Color(0xFF3B82F6);
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
    return oldDelegate.points != points;
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
        _IntensityBar(label: 'Low', value: low, maxValue: maxValue, color: const Color(0xFF93C5FD)),
        const SizedBox(width: 12),
        _IntensityBar(label: 'Medium', value: medium, maxValue: maxValue, color: const Color(0xFF60A5FA)),
        const SizedBox(width: 12),
        _IntensityBar(label: 'High', value: high, maxValue: maxValue, color: const Color(0xFF2563EB)),
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
            style: const TextStyle(
              color: Color(0xFF5F7892),
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            '$value',
            style: const TextStyle(
              color: Color(0xFF163C60),
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDE7F4)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFFD9ECFF),
            child: Icon(icon, size: 16, color: const Color(0xFF114D83)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF244764),
              ),
            ),
          ),
          Text(
            '$percent%',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF114D83),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF234A67),
                ),
              ),
            ),
            Text(
              '$successRate% relief',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF114D83),
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
            backgroundColor: const Color(0xFFE4EDF8),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$monthlyUses uses this month',
          style: const TextStyle(
            color: Color(0xFF6A8097),
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F9FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDE7F4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF3B82F6)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF2E4A62),
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
        color: const Color(0xFFEAF1F9),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

