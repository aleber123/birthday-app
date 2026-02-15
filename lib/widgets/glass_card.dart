import 'dart:ui';
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

/// Responsible Glassmorphism card (2026 trend)
/// - Frosted glass with subtle blur
/// - Soft UI dual-shadow for tactile depth
/// - High contrast borders for readability
/// - Never compromises text legibility
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blur;
  final Color? borderColor;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 22,
    this.blur = 16,
    this.borderColor,
    this.gradient,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: isDark
            ? AppTheme.softShadowDarkMode()
            : AppTheme.softShadow(),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              onLongPress: onLongPress,
              borderRadius: BorderRadius.circular(borderRadius),
              child: Container(
                decoration: BoxDecoration(
                  gradient: gradient ??
                      LinearGradient(
                        colors: isDark
                            ? [
                                Colors.white.withValues(alpha: 0.09),
                                Colors.white.withValues(alpha: 0.04),
                              ]
                            : [
                                Colors.white.withValues(alpha: 0.82),
                                Colors.white.withValues(alpha: 0.62),
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: Border.all(
                    color: borderColor ??
                        (isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.white.withValues(alpha: 0.7)),
                    width: 1,
                  ),
                ),
                padding: padding ?? const EdgeInsets.all(16),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
