import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Floating Action Button pozisyon helper'ı
/// Tüm sayfalarda tutarlı buton pozisyonları için
class FABPositionHelper {
  /// Bottom navigation bar'ın toplam yüksekliğini hesaplar
  static double getBottomNavBarHeight(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final marginTop = AppTheme.spacingSm; // 8px
    final marginBottom = bottomPadding + AppTheme.spacingXs; // bottom padding + 4px
    final verticalPadding = AppTheme.spacingMd * 2; // 12px * 2 = 24px (üst + alt)
    final iconHeight = 24.0; // Icon yüksekliği
    const labelHeight = 14.0; // Label yüksekliği (font size 10 + line height)
    const iconLabelSpacing = 4.0; // Icon ile label arası
    final contentHeight = iconHeight + iconLabelSpacing + labelHeight; // ~42px
    
    return marginTop + marginBottom + verticalPadding + contentHeight;
  }

  /// Floating action button'ın bottom pozisyonunu hesaplar
  /// Tüm sayfalarda aynı pozisyon için kullanılır
  static double getFABBottomPosition(BuildContext context, {bool isTopButton = false}) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final navBarHeight = getBottomNavBarHeight(context);
    const buttonHeight = 56.0;
    const buttonSpacing = 16.0; // İki buton arası boşluk
    const spacingFromNavBar = AppTheme.spacingLg; // Nav bar'dan boşluk (16px)
    
    // Bottom navigation bar'ın hemen üstünde, makul bir mesafe
    final baseOffset = bottomPadding + navBarHeight + spacingFromNavBar;
    
    if (isTopButton) {
      // Üstteki buton (+ butonu gibi)
      return baseOffset + buttonHeight + buttonSpacing;
    } else {
      // Alttaki buton (bildirim butonu gibi)
      return baseOffset;
    }
  }
}

