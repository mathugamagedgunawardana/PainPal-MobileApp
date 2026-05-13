import 'package:flutter/material.dart';

import '../theme/painpal_app_colors.dart';

/// Pain sites: diagram + chips. Stored value is the site id (e.g. `Left temple`).
class HeadPainSitePicker extends StatelessWidget {
  const HeadPainSitePicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  static const sites = <({String id, String label})>[
    (id: 'Left temple', label: 'Left'),
    (id: 'Right temple', label: 'Right'),
    (id: 'Forehead', label: 'Forehead'),
    (id: 'Occipital', label: 'Back'),
    (id: 'Diffuse', label: 'Diffuse'),
    (id: 'Neck', label: 'Neck'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pp = context.pp;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Where is the pain worst?',
          style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          'Tap the diagram or a label below',
          style: theme.textTheme.bodySmall?.copyWith(color: pp.textTertiary),
        ),
        const SizedBox(height: 12),
        Center(
          child: SizedBox(
            width: 220,
            height: 200,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                CustomPaint(
                  size: const Size(220, 200),
                  painter: _HeadDiagramPainter(
                    highlight: value,
                    accent: pp.accentPrimary,
                    outlineColor: pp.borderDefault,
                    headFill: pp.bgSecondary,
                    dotIdle: pp.textTertiary,
                  ),
                ),
                Positioned(
                  left: 24,
                  top: 48,
                  width: 72,
                  height: 88,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => onChanged('Left temple'),
                      borderRadius: BorderRadius.circular(40),
                    ),
                  ),
                ),
                Positioned(
                  right: 24,
                  top: 48,
                  width: 72,
                  height: 88,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => onChanged('Right temple'),
                      borderRadius: BorderRadius.circular(40),
                    ),
                  ),
                ),
                Positioned(
                  left: 72,
                  top: 28,
                  width: 76,
                  height: 56,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => onChanged('Forehead'),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                Positioned(
                  left: 64,
                  bottom: 36,
                  width: 92,
                  height: 64,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => onChanged('Occipital'),
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
                Positioned(
                  left: 48,
                  bottom: 4,
                  width: 124,
                  height: 36,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => onChanged('Neck'),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: sites.map((s) {
            final selected = value == s.id;
            return FilterChip(
              label: Text(s.label),
              selected: selected,
              onSelected: (_) => onChanged(s.id),
              selectedColor: pp.accentPrimary,
              checkmarkColor: pp.textOnAccent,
              labelStyle: TextStyle(
                color: selected ? pp.textOnAccent : pp.textPrimary,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
              side: BorderSide(
                color: selected ? pp.accentPrimary : pp.borderDefault,
              ),
              backgroundColor: pp.bgCard,
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _HeadDiagramPainter extends CustomPainter {
  _HeadDiagramPainter({
    required this.highlight,
    required this.accent,
    required this.outlineColor,
    required this.headFill,
    required this.dotIdle,
  });

  final String highlight;
  final Color accent;
  final Color outlineColor;
  final Color headFill;
  final Color dotIdle;

  bool _is(String id) => highlight == id;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h * 0.42);
    final headRect = Rect.fromCenter(center: center, width: w * 0.72, height: h * 0.62);

    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = outlineColor;

    final fill = Paint()..color = headFill;

    canvas.drawOval(headRect, fill);

    if (_is('Diffuse')) {
      canvas.drawOval(
        headRect.inflate(6),
        Paint()..color = accent.withValues(alpha: 0.2),
      );
    }
    if (_is('Left temple')) {
      final r = Rect.fromLTWH(
        headRect.left + 4,
        headRect.top + 24,
        headRect.width * 0.38,
        headRect.height * 0.55,
      );
      canvas.drawRect(r, Paint()..color = accent.withValues(alpha: 0.4));
    }
    if (_is('Right temple')) {
      final r = Rect.fromLTWH(
        headRect.right - headRect.width * 0.38 - 4,
        headRect.top + 24,
        headRect.width * 0.38,
        headRect.height * 0.55,
      );
      canvas.drawRect(r, Paint()..color = accent.withValues(alpha: 0.4));
    }
    if (_is('Forehead')) {
      final r = Rect.fromCenter(
        center: Offset(center.dx, headRect.top + 28),
        width: headRect.width * 0.55,
        height: 44,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(12)),
        Paint()..color = accent.withValues(alpha: 0.4),
      );
    }
    if (_is('Occipital')) {
      final r = Rect.fromCenter(
        center: Offset(center.dx, headRect.bottom - 36),
        width: headRect.width * 0.6,
        height: 52,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(14)),
        Paint()..color = accent.withValues(alpha: 0.4),
      );
    }
    if (_is('Neck')) {
      final neck = Rect.fromCenter(
        center: Offset(center.dx, headRect.bottom + 28),
        width: headRect.width * 0.42,
        height: 36,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(neck, const Radius.circular(10)),
        Paint()..color = accent.withValues(alpha: 0.45),
      );
      canvas.drawRRect(RRect.fromRectAndRadius(neck, const Radius.circular(10)), outline);
    }

    final eyePaint = Paint()..color = dotIdle;
    canvas.drawCircle(Offset(center.dx - w * 0.14, center.dy - h * 0.02), 4, eyePaint);
    canvas.drawCircle(Offset(center.dx + w * 0.14, center.dy - h * 0.02), 4, eyePaint);

    canvas.drawOval(headRect, outline);
  }

  @override
  bool shouldRepaint(covariant _HeadDiagramPainter oldDelegate) =>
      oldDelegate.highlight != highlight ||
      oldDelegate.accent != accent ||
      oldDelegate.outlineColor != outlineColor ||
      oldDelegate.headFill != headFill ||
      oldDelegate.dotIdle != dotIdle;
}
