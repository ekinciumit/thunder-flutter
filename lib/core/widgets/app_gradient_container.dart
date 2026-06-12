import 'package:flutter/material.dart';
import '../theme/app_color_config.dart';

class AppGradientContainer extends StatelessWidget {
  final Widget child;
  final List<Color>? gradientColors;
  final AlignmentGeometry begin;
  final AlignmentGeometry end;
  final EdgeInsetsGeometry? padding;
  final bool enableAnimatedGradient;
  final Duration animationDuration;
  final String? backgroundImagePath;
  final BoxFit backgroundFit;
  final double backgroundOpacity;

  const AppGradientContainer({
    super.key,
    required this.child,
    this.gradientColors,
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
    this.padding,
    this.enableAnimatedGradient = false,
    this.animationDuration = const Duration(seconds: 3),
    this.backgroundImagePath,
    this.backgroundFit = BoxFit.cover,
    this.backgroundOpacity = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;

    if (backgroundImagePath != null) {
      return AnimatedContainer(
        duration: enableAnimatedGradient
            ? animationDuration
            : const Duration(milliseconds: 300),
        padding: padding,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(backgroundImagePath!),
            fit: backgroundFit,
            opacity: backgroundOpacity,
          ),
        ),
        child: child,
      );
    }

    if (brightness == Brightness.dark && gradientColors == null) {
      return AnimatedContainer(
        duration: enableAnimatedGradient
            ? animationDuration
            : const Duration(milliseconds: 300),
        padding: padding,
        color: AppColorConfig.surfaceColorDark,
        child: child,
      );
    }

    final defaultGradient = gradientColors ??
        AppColorConfig.getGradientPrimaryLight(brightness)
            .map((color) => color.withAlpha(180))
            .toList();

    final colors = gradientColors ?? defaultGradient;
    final stops = List.generate(
      colors.length,
      (index) => index / (colors.length - 1),
    );

    return AnimatedContainer(
      duration: enableAnimatedGradient
          ? animationDuration
          : const Duration(milliseconds: 300),
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: begin,
          end: end,
          stops: stops,
        ),
      ),
      child: child,
    );
  }
}
