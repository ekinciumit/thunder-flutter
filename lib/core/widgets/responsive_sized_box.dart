import 'package:flutter/material.dart';
import '../utils/responsive_helper.dart';

/// Responsive SizedBox Widget
/// 
/// Ekran boyutuna göre otomatik spacing ayarlayan SizedBox
class ResponsiveSizedBox extends StatelessWidget {
  final Widget? child;
  final double? width;
  final double? height;
  final bool useSpacing;
  
  const ResponsiveSizedBox({
    super.key,
    this.child,
    this.width,
    this.height,
    this.useSpacing = false,
  });

  const ResponsiveSizedBox.spacing({
    super.key,
  }) : width = null,
       height = null,
       child = null,
       useSpacing = true;

  @override
  Widget build(BuildContext context) {
    if (useSpacing) {
      final spacing = ResponsiveHelper.getSpacing(context);
      return SizedBox(
        width: width ?? spacing,
        height: height ?? spacing,
        child: child,
      );
    }
    
    return SizedBox(
      width: width,
      height: height,
      child: child,
    );
  }
}

/// Responsive spacing için extension
extension ResponsiveSpacingExtension on BuildContext {
  /// Responsive spacing döndürür
  double get responsiveSpacing => ResponsiveHelper.getSpacing(this);
  
  /// Responsive padding döndürür
  EdgeInsets get responsivePadding => ResponsiveHelper.getPadding(this);
  
  /// Device type döndürür
  DeviceType get deviceType => ResponsiveHelper.getDeviceType(this);
  
  /// Mobile mi?
  bool get isMobile => ResponsiveHelper.isMobile(this);
  
  /// Tablet mi?
  bool get isTablet => ResponsiveHelper.isTablet(this);
  
  /// Desktop mi?
  bool get isDesktop => ResponsiveHelper.isDesktop(this);
}

