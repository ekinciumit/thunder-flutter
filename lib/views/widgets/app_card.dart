import 'package:flutter/material.dart';
import 'dart:ui';
import '../../core/theme/app_color_config.dart';

class AppCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final List<Color>? gradientColors;
  final List<BoxShadow>? boxShadow;
  final VoidCallback? onTap;
  final bool enableGlassmorphism;
  final double? width;
  final double? height;
  final double blurStrength;
  final double glassOpacity;

  const AppCard({
    super.key,
    required this.child,
    this.margin,
    this.padding,
    this.borderRadius = 20,
    this.gradientColors,
    this.boxShadow,
    this.onTap,
    this.enableGlassmorphism = false,
    this.width,
    this.height,
    this.blurStrength = 15,
    this.glassOpacity = 0.15,
  });

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _animationController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _animationController.reverse();
  }

  void _handleTapCancel() {
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    
    // Dark mode'da otomatik glassmorphism, light mode'da normal veya manuel glassmorphism
    if (widget.enableGlassmorphism || brightness == Brightness.dark) {
      return _buildGlassCard();
    }
    
    // Light mode normal kart
    Widget cardContent = Container(
      width: widget.width,
      height: widget.height,
      margin: widget.margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: widget.padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: widget.gradientColors != null 
          ? LinearGradient(
              colors: widget.gradientColors!,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
          : LinearGradient(
              colors: [
                theme.colorScheme.surface,
                theme.colorScheme.surfaceContainerHighest,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
        borderRadius: BorderRadius.circular(widget.borderRadius),
        boxShadow: widget.boxShadow ?? [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: widget.child,
    );

    if (widget.onTap != null) {
      return GestureDetector(
        onTap: widget.onTap,
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: cardContent,
            );
          },
        ),
      );
    }

    return cardContent;
  }

  Widget _buildGlassCard() {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final isDark = brightness == Brightness.dark;
    
    Widget glassContent = Container(
      width: widget.width,
      height: widget.height,
      margin: widget.margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: BackdropFilter(
          // iOS 16 tarzı güçlü blur
          filter: ImageFilter.blur(
            sigmaX: isDark ? 20 : widget.blurStrength,
            sigmaY: isDark ? 20 : widget.blurStrength,
          ),
          child: Container(
            padding: widget.padding ?? const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              // iOS 16 tarzı şeffaf glassmorphism
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05) // Çok şeffaf
                  : Colors.white.withValues(alpha: 0.15),
              // İnce, şeffaf border
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : AppColorConfig.primaryColor.withValues(alpha: 0.6),
                width: isDark ? 1.0 : 1.4,
              ),
            ),
            child: widget.child,
          ),
        ),
      ),
    );

    // Dış gölge için sarmalayıcı - hafif gölge (ChatGPT önerisi)
    glassContent = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        boxShadow: widget.boxShadow ?? [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: brightness == Brightness.dark ? 0.4 : 0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: glassContent,
    );

    if (widget.onTap != null) {
      return GestureDetector(
        onTap: widget.onTap,
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: glassContent,
            );
          },
        ),
      );
    }

    return glassContent;
  }
} 