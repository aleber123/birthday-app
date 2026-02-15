import 'package:flutter/material.dart';

/// Renders the Vipps logo – the characteristic "V" checkmark shape.
/// Uses Vipps' brand orange color (#FF5B24).
class VippsLogo extends StatelessWidget {
  final double size;
  final double borderRadius;
  final bool showBackground;

  const VippsLogo({
    super.key,
    this.size = 48,
    this.borderRadius = 14,
    this.showBackground = true,
  });

  static const vippsOrange = Color(0xFFFF5B24);

  @override
  Widget build(BuildContext context) {
    if (showBackground) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: vippsOrange,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: vippsOrange.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: CustomPaint(
          painter: _VippsLogoPainter(logoColor: Colors.white),
        ),
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _VippsLogoPainter(logoColor: vippsOrange),
      ),
    );
  }
}

class _VippsLogoPainter extends CustomPainter {
  final Color logoColor;

  _VippsLogoPainter({required this.logoColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = logoColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.12
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    // Padding from edges
    final px = w * 0.22;
    final py = h * 0.25;

    // The Vipps logo is a stylized checkmark / V shape
    final path = Path();

    // Start from top-left
    path.moveTo(px, py + h * 0.05);

    // Down to bottom-center (the V point)
    path.lineTo(w * 0.42, h - py);

    // Up to top-right
    path.lineTo(w - px, py);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _VippsLogoPainter oldDelegate) {
    return oldDelegate.logoColor != logoColor;
  }
}
