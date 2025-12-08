import 'package:flutter/material.dart';
import 'dart:ui';

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
    
    // Glassmorphism için özel widget
    if (widget.enableGlassmorphism) {
      return _buildGlassCard();
    }
    
    // Normal kart
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
    Widget glassContent = Container(
      width: widget.width,
      height: widget.height,
      margin: widget.margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: widget.blurStrength,
            sigmaY: widget.blurStrength,
          ),
          child: CustomPaint(
            painter: _GlassBorderPainter(
              borderRadius: widget.borderRadius,
              opacity: widget.glassOpacity,
            ),
            child: Container(
              padding: widget.padding ?? const EdgeInsets.all(20),
              decoration: BoxDecoration(
                // Çok hafif şeffaf dolgu - arkası net görünsün
                color: Colors.white.withValues(alpha: widget.glassOpacity * 0.4),
                borderRadius: BorderRadius.circular(widget.borderRadius),
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );

    // Dış gölge için sarmalayıcı
    glassContent = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        boxShadow: widget.boxShadow ?? [
          // Alt gölge - derinlik
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 30,
            offset: const Offset(0, 15),
            spreadRadius: -5,
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

// Gradient kenarlık için CustomPainter
class _GlassBorderPainter extends CustomPainter {
  final double borderRadius;
  final double opacity;

  _GlassBorderPainter({
    required this.borderRadius,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    // Gradient kenarlık - sol üstten sağ alta doğru solan
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.6),
          Colors.white.withValues(alpha: 0.3),
          Colors.white.withValues(alpha: 0.1),
          Colors.white.withValues(alpha: 0.05),
        ],
        stops: const [0.0, 0.3, 0.6, 1.0],
      ).createShader(rect);

    canvas.drawRRect(rrect, borderPaint);

    // İç ışık efekti - sol üst köşe
    final highlightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.center,
        colors: [
          Colors.white.withValues(alpha: 0.4),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(rect);

    // Sadece üst ve sol kenarı çiz
    final path = Path()
      ..moveTo(borderRadius, 0)
      ..lineTo(size.width - borderRadius, 0)
      ..arcToPoint(
        Offset(size.width, borderRadius),
        radius: Radius.circular(borderRadius),
      );
    
    canvas.drawPath(path, highlightPaint);

    final leftPath = Path()
      ..moveTo(0, size.height - borderRadius)
      ..lineTo(0, borderRadius)
      ..arcToPoint(
        Offset(borderRadius, 0),
        radius: Radius.circular(borderRadius),
      );
    
    canvas.drawPath(leftPath, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 