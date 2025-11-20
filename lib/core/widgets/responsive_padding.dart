import 'package:flutter/material.dart';
import '../utils/responsive_helper.dart';

/// Responsive Padding Widget
/// 
/// Ekran boyutuna göre otomatik padding ayarlayan widget
class ResponsivePadding extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final bool useAllPadding;
  final bool useHorizontalPadding;
  final bool useVerticalPadding;

  const ResponsivePadding({
    super.key,
    required this.child,
    this.padding,
    this.useAllPadding = true,
    this.useHorizontalPadding = false,
    this.useVerticalPadding = false,
  });

  @override
  Widget build(BuildContext context) {
    EdgeInsets effectivePadding;
    
    if (padding != null) {
      effectivePadding = padding!;
    } else if (useAllPadding) {
      effectivePadding = ResponsiveHelper.getPadding(context);
    } else if (useHorizontalPadding) {
      effectivePadding = ResponsiveHelper.getHorizontalPadding(context);
    } else if (useVerticalPadding) {
      effectivePadding = ResponsiveHelper.getVerticalPadding(context);
    } else {
      effectivePadding = ResponsiveHelper.getPadding(context);
    }
    
    return Padding(
      padding: effectivePadding,
      child: child,
    );
  }
}

