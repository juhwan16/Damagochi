import 'package:flutter/material.dart';

class GameBackground extends StatelessWidget {
  final Widget child;
  const GameBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GameBgPainter(),
      child: child,
    );
  }
}

class _GameBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ── Sky gradient ──────────────────────────────────────────
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF38B8F0), Color(0xFF90DEFF)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), skyPaint);

    // ── Sun (top-right) ───────────────────────────────────────
    final sunGlow = Paint()..color = const Color(0xFFFFE44A).withValues(alpha: 0.22);
    canvas.drawCircle(Offset(w - 44, 68), 52, sunGlow);
    final sunPaint = Paint()..color = const Color(0xFFFFD62E);
    canvas.drawCircle(Offset(w - 44, 68), 34, sunPaint);
    // Sun inner highlight
    canvas.drawCircle(
      Offset(w - 52, 60),
      14,
      Paint()..color = const Color(0xFFFFF0A0),
    );

    // ── Clouds ────────────────────────────────────────────────
    _cloud(canvas, 18, 95, 1.05);
    _cloud(canvas, w * 0.42, 68, 0.80);
    _cloud(canvas, w * 0.68, 105, 0.60);

    // ── Far rolling hill (lighter green) ─────────────────────
    final hill1 = Paint()..color = const Color(0xFF6ECB6E);
    final p1 = Path()
      ..moveTo(0, h * 0.68)
      ..cubicTo(w * 0.12, h * 0.57, w * 0.30, h * 0.63, w * 0.48, h * 0.60)
      ..cubicTo(w * 0.65, h * 0.57, w * 0.82, h * 0.70, w, h * 0.62)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(p1, hill1);

    // ── Mid hill ─────────────────────────────────────────────
    final hill2 = Paint()..color = const Color(0xFF55BB55);
    final p2 = Path()
      ..moveTo(0, h * 0.77)
      ..cubicTo(w * 0.18, h * 0.70, w * 0.42, h * 0.75, w * 0.58, h * 0.72)
      ..cubicTo(w * 0.74, h * 0.69, w * 0.88, h * 0.78, w, h * 0.74)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(p2, hill2);

    // ── Ground strip ─────────────────────────────────────────
    final ground = Paint()..color = const Color(0xFF48B048);
    final p3 = Path()
      ..moveTo(0, h * 0.86)
      ..cubicTo(w * 0.28, h * 0.81, w * 0.56, h * 0.88, w, h * 0.83)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(p3, ground);

    // ── Grass edge (darker strip at very bottom) ──────────────
    final grass = Paint()..color = const Color(0xFF3CA03C);
    final p4 = Path()
      ..moveTo(0, h * 0.93)
      ..cubicTo(w * 0.33, h * 0.90, w * 0.66, h * 0.94, w, h * 0.91)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(p4, grass);

    // ── Flowers on hills ──────────────────────────────────────
    _flower(canvas, w * 0.08, h * 0.88, const Color(0xFFFF9AD0));
    _flower(canvas, w * 0.22, h * 0.84, const Color(0xFFFFE044));
    _flower(canvas, w * 0.42, h * 0.82, const Color(0xFFFF9AD0));
    _flower(canvas, w * 0.60, h * 0.86, const Color(0xFFFFFFFF));
    _flower(canvas, w * 0.78, h * 0.83, const Color(0xFFFFE044));
    _flower(canvas, w * 0.90, h * 0.88, const Color(0xFFFF9AD0));

    // ── Small trees on far hill ───────────────────────────────
    _tree(canvas, w * 0.14, h * 0.70);
    _tree(canvas, w * 0.84, h * 0.66);
  }

  void _cloud(Canvas canvas, double x, double y, double s) {
    final p = Paint()..color = Colors.white.withValues(alpha: 0.92);
    final r = 22.0 * s;
    canvas.drawCircle(Offset(x, y), r, p);
    canvas.drawCircle(Offset(x + r * 1.25, y - r * 0.28), r * 1.22, p);
    canvas.drawCircle(Offset(x + r * 2.48, y + r * 0.08), r * 0.90, p);
    canvas.drawCircle(Offset(x + r * 0.45, y + r * 0.52), r * 0.68, p);
    canvas.drawCircle(Offset(x + r * 1.70, y + r * 0.52), r * 0.72, p);
  }

  void _flower(Canvas canvas, double x, double y, Color color) {
    final petal = Paint()..color = color;
    final center = Paint()..color = const Color(0xFFFFEE88);
    const r = 4.5;
    canvas.drawCircle(Offset(x, y - 7), r, petal);
    canvas.drawCircle(Offset(x, y + 7), r, petal);
    canvas.drawCircle(Offset(x - 7, y), r, petal);
    canvas.drawCircle(Offset(x + 7, y), r, petal);
    canvas.drawCircle(Offset(x, y), r, center);
  }

  void _tree(Canvas canvas, double x, double y) {
    // Trunk
    final trunk = Paint()..color = const Color(0xFF8B5A2B);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x, y + 14), width: 8, height: 18),
        const Radius.circular(3),
      ),
      trunk,
    );
    // Canopy layers
    final leaf = Paint()..color = const Color(0xFF3A9A3A);
    final leaf2 = Paint()..color = const Color(0xFF4DB84D);
    canvas.drawCircle(Offset(x, y + 4), 18, leaf);
    canvas.drawCircle(Offset(x - 10, y + 8), 13, leaf);
    canvas.drawCircle(Offset(x + 10, y + 8), 13, leaf);
    canvas.drawCircle(Offset(x, y - 4), 14, leaf2);
    // Top highlight
    canvas.drawCircle(
      Offset(x - 4, y - 6),
      6,
      Paint()..color = const Color(0xFF66CC66),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
