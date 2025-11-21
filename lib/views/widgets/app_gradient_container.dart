import 'package:flutter/material.dart';

class AppGradientContainer extends StatelessWidget {
  final Widget child;
  final List<Color>? gradientColors;
  final AlignmentGeometry begin;
  final AlignmentGeometry end;
  final EdgeInsetsGeometry? padding;
  final bool enableAnimatedGradient;
  final Duration animationDuration;

  const AppGradientContainer({
    super.key,
    required this.child,
    this.gradientColors,
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
    this.padding,
    this.enableAnimatedGradient = false,
    this.animationDuration = const Duration(seconds: 3),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final defaultGradient = [
      theme.colorScheme.primary.withValues(alpha: 0.1),
      theme.colorScheme.secondary.withValues(alpha: 0.05),
      theme.colorScheme.tertiary.withValues(alpha: 0.03),
    ];

    final colors = gradientColors ?? defaultGradient;
    final stops = List.generate(
      colors.length,
      (index) => index / (colors.length - 1),
    );

    if (enableAnimatedGradient) {
      return AnimatedContainer(
        duration: animationDuration,
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

    return Container(
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