import 'package:flutter/material.dart';

/// Renders the official Swish logo using the brand PNG asset.
class SwishLogo extends StatelessWidget {
  final double size;
  final Color? backgroundColor;
  final double borderRadius;
  final bool showBackground;

  const SwishLogo({
    super.key,
    this.size = 48,
    this.backgroundColor,
    this.borderRadius = 14,
    this.showBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      'assets/images/swish_logo.png',
      width: size * 0.7,
      height: size * 0.7,
      fit: BoxFit.contain,
    );

    if (showBackground) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF41B845).withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(child: image),
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: Center(child: image),
    );
  }
}
