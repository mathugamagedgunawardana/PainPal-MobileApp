import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/painpal_app_colors.dart';

/// Reference: minimalist geometric “mood tile” faces on bold blocks (wellness / mood apps).
enum PainpalIllustratedFace {
  skepticalBlue,
  happyPink,
  curiousYellow,
  painedOrange,
}

abstract final class PainpalIllusPalette {
  static const skyBlue = Color(0xFF5EB5FF);
  static const bubblePink = Color(0xFFFF9BC8);
  static const sunnyYellow = Color(0xFFFFF066);
  static const deepOrange = Color(0xFFFF8C42);
}

/// Single face tile — paints expressive features on [backgroundColor].
class PainpalFaceIllustration extends StatelessWidget {
  const PainpalFaceIllustration({
    super.key,
    required this.face,
    required this.backgroundColor,
  });

  final PainpalIllustratedFace face;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: backgroundColor,
      child: CustomPaint(
        painter: _FacePainter(face),
        child: const SizedBox.expand(),
      ),
    );
  }
}

/// Bento layout: blue + pink stack | tall yellow | full-width orange (matches reference collage).
class PainpalMoodCollage extends StatelessWidget {
  const PainpalMoodCollage({
    super.key,
    this.height = 220,
    this.borderRadius = PainpalRadii.cardBubble,
  });

  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        height: height,
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 13,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: const [
                        Expanded(
                          flex: 12,
                          child: PainpalFaceIllustration(
                            face: PainpalIllustratedFace.skepticalBlue,
                            backgroundColor: PainpalIllusPalette.skyBlue,
                          ),
                        ),
                        Expanded(
                          flex: 11,
                          child: PainpalFaceIllustration(
                            face: PainpalIllustratedFace.happyPink,
                            backgroundColor: PainpalIllusPalette.bubblePink,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 10,
                    child: PainpalFaceIllustration(
                      face: PainpalIllustratedFace.curiousYellow,
                      backgroundColor: PainpalIllusPalette.sunnyYellow,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: PainpalFaceIllustration(
                face: PainpalIllustratedFace.painedOrange,
                backgroundColor: PainpalIllusPalette.deepOrange,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small decorative strip of faces for cards / headers.
class PainpalFaceStrip extends StatelessWidget {
  const PainpalFaceStrip({super.key, this.size = 44});

  final double size;

  @override
  Widget build(BuildContext context) {
    const faces = [
      (PainpalIllustratedFace.skepticalBlue, PainpalIllusPalette.skyBlue),
      (PainpalIllustratedFace.happyPink, PainpalIllusPalette.bubblePink),
      (PainpalIllustratedFace.curiousYellow, PainpalIllusPalette.sunnyYellow),
      (PainpalIllustratedFace.painedOrange, PainpalIllusPalette.deepOrange),
    ];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: faces.map((f) {
        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(PainpalRadii.md),
            child: SizedBox(
              width: size,
              height: size,
              child: PainpalFaceIllustration(
                face: f.$1,
                backgroundColor: f.$2,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _FacePainter extends CustomPainter {
  _FacePainter(this.face);

  final PainpalIllustratedFace face;

  @override
  void paint(Canvas canvas, Size size) {
    switch (face) {
      case PainpalIllustratedFace.skepticalBlue:
        _skeptical(canvas, size);
      case PainpalIllustratedFace.happyPink:
        _happy(canvas, size);
      case PainpalIllustratedFace.curiousYellow:
        _curious(canvas, size);
      case PainpalIllustratedFace.painedOrange:
        _pained(canvas, size);
    }
  }

  void _skeptical(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final eyeR = size.shortestSide * 0.09;
    final lp = Offset(cx - eyeR * 2.2, cy - eyeR * 0.8);
    final rp = Offset(cx + eyeR * 2.2, cy - eyeR * 0.8);

    final white = Paint()..color = Colors.white;
    canvas.drawCircle(lp, eyeR * 1.05, white);
    canvas.drawCircle(rp, eyeR * 1.05, white);

    final pupil = Paint()..color = Colors.black;
    canvas.drawCircle(lp + Offset(eyeR * 0.35, eyeR * 0.45), eyeR * 0.42, pupil);
    canvas.drawCircle(rp + Offset(eyeR * 0.35, eyeR * 0.45), eyeR * 0.42, pupil);

    final mouth = Paint()
      ..color = Colors.black
      ..strokeWidth = size.shortestSide * 0.035
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(cx - eyeR * 2.4, cy + eyeR * 2.2),
      Offset(cx + eyeR * 2.4, cy + eyeR * 2.2),
      mouth,
    );
  }

  void _happy(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final s = size.shortestSide;
    final stroke = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.045
      ..strokeCap = StrokeCap.round;

    final eyeY = cy - s * 0.12;
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx - s * 0.18, eyeY), width: s * 0.14, height: s * 0.1),
      math.pi * 0.15,
      math.pi * 0.7,
      false,
      stroke,
    );
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx + s * 0.18, eyeY), width: s * 0.14, height: s * 0.1),
      math.pi * 0.15,
      math.pi * 0.7,
      false,
      stroke,
    );

    final smile = Path()
      ..moveTo(cx - s * 0.28, cy + s * 0.02)
      ..quadraticBezierTo(cx, cy + s * 0.28, cx + s * 0.28, cy + s * 0.02);
    canvas.drawPath(smile, stroke);
  }

  void _curious(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final cx = size.width * 0.38;
    final cy = size.height * 0.48;

    final white = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(cx, cy), s * 0.22, white);
    canvas.drawCircle(Offset(cx + s * 0.06, cy + s * 0.05), s * 0.09, Paint()..color = Colors.black);

    final r = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(size.width * 0.72, cy), width: s * 0.22, height: s * 0.12),
      Radius.circular(s * 0.03),
    );
    canvas.drawRRect(r, white);
    canvas.drawRRect(r, Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = s * 0.02);
  }

  void _pained(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final s = size.shortestSide;
    final stroke = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.045
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(cx - s * 0.26, cy - s * 0.18),
      Offset(cx - s * 0.06, cy + s * 0.02),
      stroke,
    );
    canvas.drawLine(
      Offset(cx + s * 0.26, cy - s * 0.18),
      Offset(cx + s * 0.06, cy + s * 0.02),
      stroke,
    );

    canvas.drawLine(
      Offset(cx - s * 0.14, cy + s * 0.22),
      Offset(cx + s * 0.14, cy + s * 0.22),
      stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _FacePainter oldDelegate) => oldDelegate.face != face;
}
