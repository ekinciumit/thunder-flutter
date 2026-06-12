import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../theme/app_theme.dart';

/// Glassmorphism Container Widget
/// 
/// iOS 16 tarzı şeffaf, camsı görünüm için reusable widget
/// Dark mode'da otomatik olarak glassmorphism uygular
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blurStrength;
  final double glassAlpha;
  final double borderAlpha;
  final Color? backgroundColor;
  final Color? borderColor;
  final List<BoxShadow>? boxShadow;
  final bool enableGlassmorphism;
  final BorderRadius? customBorderRadius;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius = AppTheme.radiusLg,
    this.blurStrength = 10.0,
    this.glassAlpha = 0.05,
    this.borderAlpha = 0.15,
    this.backgroundColor,
    this.borderColor,
    this.boxShadow,
    this.enableGlassmorphism = true,
    this.customBorderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final isDark = brightness == Brightness.dark;
    final shouldApplyGlass = enableGlassmorphism && isDark;

    final container = Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: customBorderRadius ?? BorderRadius.circular(borderRadius),
        color: backgroundColor ??
            (shouldApplyGlass
                ? Colors.white.withValues(alpha: glassAlpha)
                : theme.colorScheme.surface.withValues(alpha: isDark ? 0.1 : 0.9)),
        border: Border.all(
          color: borderColor ??
              (shouldApplyGlass
                  ? Colors.white.withValues(alpha: borderAlpha)
                  : theme.colorScheme.outline.withValues(
                      alpha: isDark ? 0.2 : 0.1,
                    )),
          width: 1.0,
        ),
        boxShadow: boxShadow ??
            (shouldApplyGlass
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : []),
      ),
      child: child,
    );

    if (shouldApplyGlass) {
      return ClipRRect(
        borderRadius: customBorderRadius ?? BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: blurStrength, sigmaY: blurStrength),
          child: container,
        ),
      );
    }

    return container;
  }
}

