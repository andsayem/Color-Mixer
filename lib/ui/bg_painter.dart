import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Soft, slowly drifting glow orbs painted behind every screen.
class BgPainter extends CustomPainter {
  final Animation<double> anim;

  BgPainter(this.anim) : super(repaint: anim);

  @override
  void paint(Canvas canvas, Size size) {
    final t = anim.value * 2 * math.pi;

    void orb(double cx, double cy, double r, Color color) {
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [color.withAlpha(38), Colors.transparent],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));
      canvas.drawCircle(Offset(cx, cy), r, paint);
    }

    orb(
      size.width * (0.15 + 0.06 * math.sin(t)),
      size.height * (0.2 + 0.04 * math.cos(t)),
      size.width * 0.55,
      AppColors.accent1,
    );
    orb(
      size.width * (0.8 + 0.05 * math.cos(t)),
      size.height * (0.72 + 0.05 * math.sin(t)),
      size.width * 0.5,
      AppColors.accent2,
    );
    orb(
      size.width * 0.5,
      size.height * (0.45 + 0.03 * math.sin(t + 1)),
      size.width * 0.35,
      AppColors.accent3,
    );
  }

  @override
  bool shouldRepaint(BgPainter oldDelegate) => true;
}
