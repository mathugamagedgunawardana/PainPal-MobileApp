import 'package:flutter/material.dart';

/// Soft palette for flat illustrations (light UI style)
class IllustrationColors {
  static const Color softBlue = Color(0xFF5B9BD5);
  static const Color softBlueLight = Color(0xFFE3F2FD);
  static const Color warmOrange = Color(0xFFFFB74D);
  static const Color warmGreen = Color(0xFF81C784);
  static const Color softPurple = Color(0xFFB39DDB);
  static const Color softPink = Color(0xFFF48FB1);
  static const Color cream = Color(0xFFFFF8E1);
  static const Color textMuted = Color(0xFF6F767E);
}

/// Hero illustration: friendly figure with health/migraine theme (flat style)
class WelcomeHeroIllustration extends StatelessWidget {
  const WelcomeHeroIllustration({
    super.key,
    this.size = 200,
    this.primaryColor,
    this.secondaryColor,
  });

  final double size;
  final Color? primaryColor;
  final Color? secondaryColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = primaryColor ?? (isDark ? IllustrationColors.softBlue : IllustrationColors.softBlue);
    final secondary = secondaryColor ?? (isDark ? IllustrationColors.warmOrange : IllustrationColors.warmOrange);

    return SizedBox(
      width: size,
      height: size * 1.1,
      child: CustomPaint(
        painter: _WelcomeHeroPainter(
          primary: primary,
          secondary: secondary,
          isDark: isDark,
        ),
      ),
    );
  }
}

class _WelcomeHeroPainter extends CustomPainter {
  _WelcomeHeroPainter({
    required this.primary,
    required this.secondary,
    required this.isDark,
  });

  final Color primary;
  final Color secondary;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final centerX = w / 2;

    // Soft background circle
    final bgPaint = Paint()
      ..color = (isDark ? primary : IllustrationColors.softBlueLight).withValues(alpha: isDark ? 0.3 : 0.8)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(centerX, h * 0.5), w * 0.48, bgPaint);

    // Head (circle)
    final headCenter = Offset(centerX, h * 0.32);
    final headR = w * 0.14;
    final headPaint = Paint()..color = primary..style = PaintingStyle.fill;
    canvas.drawCircle(headCenter, headR, headPaint);

    // Eyes (two small circles)
    final eyePaint = Paint()..color = isDark ? Colors.white : Colors.white;
    canvas.drawCircle(Offset(centerX - headR * 0.35, headCenter.dy - headR * 0.1), headR * 0.15, eyePaint);
    canvas.drawCircle(Offset(centerX + headR * 0.35, headCenter.dy - headR * 0.1), headR * 0.15, eyePaint);
    final pupilPaint = Paint()..color = isDark ? Colors.black87 : Colors.black54;
    canvas.drawCircle(Offset(centerX - headR * 0.35, headCenter.dy - headR * 0.1), headR * 0.08, pupilPaint);
    canvas.drawCircle(Offset(centerX + headR * 0.35, headCenter.dy - headR * 0.1), headR * 0.08, pupilPaint);

    // Smile (arc)
    final smilePath = Path();
    smilePath.moveTo(centerX - headR * 0.5, headCenter.dy + headR * 0.2);
    smilePath.quadraticBezierTo(centerX, headCenter.dy + headR * 0.7, centerX + headR * 0.5, headCenter.dy + headR * 0.2);
    final smilePaint = Paint()
      ..color = isDark ? Colors.white70 : Colors.black26
      ..style = PaintingStyle.stroke
      ..strokeWidth = headR * 0.12
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(smilePath, smilePaint);

    // Body (rounded rect / torso)
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(centerX, h * 0.58),
        width: w * 0.28,
        height: h * 0.22,
      ),
      const Radius.circular(24),
    );
    canvas.drawRRect(bodyRect, headPaint);

    // Heart / health icon above head (thought-bubble style)
    final heartCenter = Offset(centerX + w * 0.28, h * 0.12);
    final heartPaint = Paint()..color = secondary..style = PaintingStyle.fill;
    _drawHeart(canvas, heartCenter, w * 0.08, heartPaint);

    // Small circle "bubble" connector
    canvas.drawCircle(Offset(centerX + w * 0.18, h * 0.22), w * 0.03, heartPaint);
  }

  void _drawHeart(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    path.moveTo(center.dx, center.dy + size * 0.3);
    path.cubicTo(center.dx - size, center.dy - size * 0.5, center.dx - size * 1.2, center.dy + size * 0.8, center.dx, center.dy + size * 1.2);
    path.cubicTo(center.dx + size * 1.2, center.dy + size * 0.8, center.dx + size, center.dy - size * 0.5, center.dx, center.dy + size * 0.3);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Card-style illustration with icon and soft background (for features, risk, etc.)
class IllustrationCard extends StatelessWidget {
  const IllustrationCard({
    super.key,
    required this.icon,
    this.iconColor,
    this.backgroundColor,
    this.size = 80,
  });

  final IconData icon;
  final Color? iconColor;
  final Color? backgroundColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = backgroundColor ?? (isDark ? IllustrationColors.softBlue.withValues(alpha: 0.2) : IllustrationColors.softBlueLight);
    final color = iconColor ?? IllustrationColors.softBlue;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, size: size * 0.5, color: color),
    );
  }
}

/// Simple progress indicator (e.g. "Step 1 of 3")
class StepProgressBar extends StatelessWidget {
  const StepProgressBar({
    super.key,
    required this.current,
    required this.total,
    this.color,
  });

  final int current;
  final int total;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = color ?? theme.colorScheme.primary;

    return Row(
      children: [
        Text(
          '$current/$total',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total > 0 ? (current / total).clamp(0.0, 1.0) : 0,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(c),
              minHeight: 6,
            ),
          ),
        ),
      ],
    );
  }
}
