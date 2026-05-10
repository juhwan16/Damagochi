import 'package:flutter/material.dart';

class GameBackground extends StatelessWidget {
  final Widget child;
  final String themeId;
  const GameBackground({super.key, required this.child, this.themeId = 'default'});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GameBgPainter(themeId),
      child: child,
    );
  }
}

class _Palette {
  final Color skyTop, skyBottom, sun, sunGlow, h1, h2, h3, h4;
  const _Palette(this.skyTop, this.skyBottom, this.sun, this.sunGlow,
      this.h1, this.h2, this.h3, this.h4);
}

_Palette _palette(String id) {
  switch (id) {
    case 'sky':
      return const _Palette(
        Color(0xFF7EC8E3), Color(0xFFD4EFFF),
        Color(0xFFFFE88A), Color(0xFFFFFDE0),
        Color(0xFF88D488), Color(0xFF70CC70), Color(0xFF5EC05E), Color(0xFF4AB04A),
      );
    case 'forest':
      return const _Palette(
        Color(0xFF2E7D5E), Color(0xFF76C496),
        Color(0xFFFFD62E), Color(0xFFFFE44A),
        Color(0xFF2E7D32), Color(0xFF1B5E20), Color(0xFF256820), Color(0xFF1A5216),
      );
    case 'sunset':
      return const _Palette(
        Color(0xFFD9502A), Color(0xFFFFBE4A),
        Color(0xFFFF6B00), Color(0xFFFF9850),
        Color(0xFF8B7355), Color(0xFF7A6244), Color(0xFF6A5234), Color(0xFF5A4224),
      );
    case 'lavender':
      return const _Palette(
        Color(0xFF7B52AB), Color(0xFFCCA8E0),
        Color(0xFFFFE08A), Color(0xFFFFF0C0),
        Color(0xFF6B8E3E), Color(0xFF5C7D30), Color(0xFF4E6C22), Color(0xFF405B18),
      );
    case 'ocean':
      return const _Palette(
        Color(0xFF0277BD), Color(0xFF4FC3F7),
        Color(0xFFFFD700), Color(0xFFFFEE58),
        Color(0xFF00897B), Color(0xFF00796B), Color(0xFF00695C), Color(0xFF005A52),
      );
    default:
      return const _Palette(
        Color(0xFF38B8F0), Color(0xFF90DEFF),
        Color(0xFFFFD62E), Color(0xFFFFE44A),
        Color(0xFF6ECB6E), Color(0xFF55BB55), Color(0xFF48B048), Color(0xFF3CA03C),
      );
  }
}

class _GameBgPainter extends CustomPainter {
  final String themeId;
  const _GameBgPainter(this.themeId);

  @override
  void paint(Canvas canvas, Size size) {
    final p = _palette(themeId);
    final w = size.width;
    final h = size.height;

    // Sky
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [p.skyTop, p.skyBottom],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // Sun
    canvas.drawCircle(Offset(w - 44, 68), 52, Paint()..color = p.sunGlow.withValues(alpha: 0.22));
    canvas.drawCircle(Offset(w - 44, 68), 34, Paint()..color = p.sun);
    canvas.drawCircle(Offset(w - 52, 60), 14, Paint()..color = p.sunGlow);

    // Clouds
    _cloud(canvas, 18, 95, 1.05);
    _cloud(canvas, w * 0.42, 68, 0.80);
    _cloud(canvas, w * 0.68, 105, 0.60);

    // Hills
    final path1 = Path()
      ..moveTo(0, h * 0.68)
      ..cubicTo(w * 0.12, h * 0.57, w * 0.30, h * 0.63, w * 0.48, h * 0.60)
      ..cubicTo(w * 0.65, h * 0.57, w * 0.82, h * 0.70, w, h * 0.62)
      ..lineTo(w, h)..lineTo(0, h)..close();
    canvas.drawPath(path1, Paint()..color = p.h1);

    final path2 = Path()
      ..moveTo(0, h * 0.77)
      ..cubicTo(w * 0.18, h * 0.70, w * 0.42, h * 0.75, w * 0.58, h * 0.72)
      ..cubicTo(w * 0.74, h * 0.69, w * 0.88, h * 0.78, w, h * 0.74)
      ..lineTo(w, h)..lineTo(0, h)..close();
    canvas.drawPath(path2, Paint()..color = p.h2);

    final path3 = Path()
      ..moveTo(0, h * 0.86)
      ..cubicTo(w * 0.28, h * 0.81, w * 0.56, h * 0.88, w, h * 0.83)
      ..lineTo(w, h)..lineTo(0, h)..close();
    canvas.drawPath(path3, Paint()..color = p.h3);

    final path4 = Path()
      ..moveTo(0, h * 0.93)
      ..cubicTo(w * 0.33, h * 0.90, w * 0.66, h * 0.94, w, h * 0.91)
      ..lineTo(w, h)..lineTo(0, h)..close();
    canvas.drawPath(path4, Paint()..color = p.h4);

    // Flowers
    _flower(canvas, w * 0.08, h * 0.88, const Color(0xFFFF9AD0));
    _flower(canvas, w * 0.22, h * 0.84, const Color(0xFFFFE044));
    _flower(canvas, w * 0.42, h * 0.82, const Color(0xFFFF9AD0));
    _flower(canvas, w * 0.60, h * 0.86, const Color(0xFFFFFFFF));
    _flower(canvas, w * 0.78, h * 0.83, const Color(0xFFFFE044));
    _flower(canvas, w * 0.90, h * 0.88, const Color(0xFFFF9AD0));

    // Trees
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
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x, y + 14), width: 8, height: 18),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFF8B5A2B),
    );
    final leaf = Paint()..color = const Color(0xFF3A9A3A);
    final leaf2 = Paint()..color = const Color(0xFF4DB84D);
    canvas.drawCircle(Offset(x, y + 4), 18, leaf);
    canvas.drawCircle(Offset(x - 10, y + 8), 13, leaf);
    canvas.drawCircle(Offset(x + 10, y + 8), 13, leaf);
    canvas.drawCircle(Offset(x, y - 4), 14, leaf2);
    canvas.drawCircle(Offset(x - 4, y - 6), 6, Paint()..color = const Color(0xFF66CC66));
  }

  @override
  bool shouldRepaint(_GameBgPainter old) => old.themeId != themeId;
}
