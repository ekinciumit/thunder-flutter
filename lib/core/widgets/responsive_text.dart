import 'package:flutter/material.dart';
import '../utils/responsive_helper.dart';

/// Responsive Text Widget
/// 
/// Ekran boyutuna göre otomatik font size ayarlayan text widget
class ResponsiveText extends StatelessWidget {
  final String text;
  final double? fontSize;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final Color? color;
  final FontWeight? fontWeight;

  const ResponsiveText(
    this.text, {
    super.key,
    this.fontSize,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.color,
    this.fontWeight,
  });

  @override
  Widget build(BuildContext context) {
    final baseFontSize = fontSize ?? 
        (style?.fontSize ?? Theme.of(context).textTheme.bodyLarge?.fontSize ?? 16);
    
    final responsiveFontSize = ResponsiveHelper.getFontSize(context, baseFontSize);
    
    TextStyle effectiveStyle;
    if (style != null) {
      effectiveStyle = style!.copyWith(
        fontSize: responsiveFontSize,
        color: color ?? style!.color,
        fontWeight: fontWeight ?? style!.fontWeight,
      );
    } else {
      effectiveStyle = TextStyle(
        fontSize: responsiveFontSize,
        color: color,
        fontWeight: fontWeight,
      );
    }
    
    return Text(
      text,
      style: effectiveStyle,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

