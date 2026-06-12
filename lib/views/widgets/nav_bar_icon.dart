import 'package:flutter/material.dart';

/// Navigation bar icon widget with animation
class NavBarIcon extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  
  const NavBarIcon({
    super.key,
    required this.icon, 
    required this.label,
    required this.selected, 
    required this.onTap,
  });

  @override
  State<NavBarIcon> createState() => _NavBarIconState();
}

class _NavBarIconState extends State<NavBarIcon> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    // İlk durumu ayarla
    if (widget.selected) {
      _animationController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(NavBarIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected != oldWidget.selected) {
      if (widget.selected) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final isDark = brightness == Brightness.dark;
    
    // Dark mode'da navigation bar arka planı koyu olduğu için icon renkleri açık olmalı
    // Light mode'da navigation bar mavi olduğu için icon renkleri beyaz olmalı
    final iconColor = isDark 
        ? (widget.selected ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant)
        : (widget.selected ? Colors.white : Colors.white.withValues(alpha: 0.7));
    
    final backgroundColor = isDark
        ? (widget.selected ? theme.colorScheme.primaryContainer : Colors.transparent)
        : (widget.selected ? Colors.white.withValues(alpha: 0.2) : Colors.transparent);
    
    final borderColor = isDark
        ? (widget.selected ? theme.colorScheme.primary : null)
        : (widget.selected ? Colors.white.withValues(alpha: 0.3) : null);
    
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: 64,
              height: 56,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(20),
                border: widget.selected && borderColor != null
                  ? Border.all(
                      color: borderColor,
                      width: 1.5,
                    )
                  : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.icon,
                    color: iconColor,
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: widget.selected ? FontWeight.w600 : FontWeight.normal,
                      color: iconColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

