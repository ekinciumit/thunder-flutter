import 'package:flutter/material.dart';

/// App Color Configuration
/// 
/// Tüm uygulama renklerinin tek yerden yönetildiği konfigürasyon dosyası
/// 
/// KULLANIM:
/// - Primary, Secondary, Gradient renklerini buradan değiştirin
/// - Error, Warning, Info ve gri tonlar sabit kalır (semantik renkler)
/// - Değişiklikler tüm uygulamaya otomatik yansır
class AppColorConfig {
  // Private constructor - Bu sınıf sadece static members içerir
  AppColorConfig._();

  // ============================================================================
  // 🎨 ANA RENKLER - Buradan değiştirebilirsiniz
  // ============================================================================

  /// Primary Color (Ana Renk)
  /// Butonlar, vurgular, navigation için kullanılır
  static const Color primaryColor = Color(0xFF3674B5); // Medium Dark Blue

  /// Secondary Color (İkincil Renk)
  /// İkincil butonlar, aksanlar için kullanılır
  static const Color secondaryColor = Color(0xFF578FCA); // Lighter Blue

  /// Tertiary Color (Üçüncül Renk)
  /// Üçüncül vurgular, bilgi mesajları için kullanılır
  static const Color tertiaryColor = Color(0xFFA1E3F9); // Light Sky Blue

  // ============================================================================
  // 🌈 GRADIENT RENKLER - Buradan değiştirebilirsiniz
  // ============================================================================

  /// Primary Gradient (Ana Gradient)
  /// Ana sayfa arka planları, büyük card'lar için
  static const List<Color> gradientPrimary = [
    Color(0xFF3674B5), // Medium Dark Blue
    Color(0xFF578FCA), // Lighter Blue
    Color(0xFFA1E3F9), // Light Sky Blue
    Color(0xFFD1F8EF), // Very Pale Mint Green
  ];

  /// Primary Light Gradient (Açık Ana Gradient)
  /// Hafif arka planlar, input alanları için
  static const List<Color> gradientPrimaryLight = [
    Color(0xFF578FCA), // Lighter Blue
    Color(0xFFA1E3F9), // Light Sky Blue
  ];

  /// Secondary Gradient (İkincil Gradient)
  /// Butonlar, vurgular, navigation için
  static const List<Color> gradientSecondary = [
    Color(0xFF3674B5), // Medium Dark Blue
    Color(0xFF578FCA), // Lighter Blue
  ];

  // ============================================================================
  // 🎯 SEMANTIK RENKLER - SABİT (Değiştirmeyin)
  // ============================================================================

  /// Success Color (Başarı Rengi)
  /// Başarı mesajları, onay durumları için
  static const Color successColor = Color(0xFF10B981); // Green
  static const Color successColorLight = Color(0xFF34D399); // Light green

  /// Error Color (Hata Rengi)
  /// Hata mesajları, validasyon için
  static const Color errorColor = Color(0xFFDC2626); // Red
  static const Color errorColorLight = Color(0xFFEF4444); // Light red

  /// Warning Color (Uyarı Rengi)
  /// Uyarı mesajları, dikkat gerektiren durumlar için
  static const Color warningColor = Color(0xFFFFB800); // Amber

  /// Info Color (Bilgi Rengi)
  /// Bilgilendirme mesajları için (Tertiary ile aynı)
  static Color get infoColor => tertiaryColor;

  // ============================================================================
  // ☀️ GRİ TONLAR - LIGHT MODE (Material Design 3 uyumlu)
  // ============================================================================

  /// Surface (Yüzey) Renkleri - Light Mode
  /// Material Design 3: #FFFFFF base, ama daha yumuşak tonlar
  static const Color surfaceColorLight = Color(0xFFFFFBFE); // Material Design 3 base light (hafif sıcak beyaz)
  static const Color surfaceContainerHighestLight = Color(0xFFF5F5F5); // Daha yumuşak gri (elevation için)
  static const Color cardColorLight = Color(0xFFFFFFFF); // Saf beyaz (card'lar için)

  /// Text (Metin) Renkleri - Light Mode
  /// WCAG AAA kontrast için optimize edilmiş
  static const Color textPrimaryLight = Color(0xFF1A1A1A); // Daha koyu siyah (WCAG AAA - %87 kontrast)
  static const Color textSecondaryLight = Color(0xFF5A5A5A); // Daha belirgin ikincil metin (%60 kontrast)

  /// Border (Kenarlık) Renkleri - Light Mode
  /// Daha belirgin ve görünür border'lar
  static const Color borderColorLightMode = Color(0xFF8A8A8A); // Daha belirgin border
  static const Color borderColorLightLightMode = Color(0xFFD0D0D0); // Hafif border (daha belirgin)
  static const Color borderColorInputLightMode = Color(0xFFE0E0E0); // Input kenarlığı (daha belirgin)

  // ============================================================================
  // 🌙 GRİ TONLAR - DARK MODE (Material Design 3 uyumlu)
  // ============================================================================

  /// Surface (Yüzey) Renkleri - Dark Mode
  /// Material Design 3: #121212 base, ama daha yumuşak tonlar
  static const Color surfaceColorDark = Color(0xFF121212); // Material Design 3 base dark
  static const Color surfaceContainerHighestDark = Color(0xFF1E1E1E); // Biraz daha açık (elevation için)
  static const Color cardColorDark = Color(0xFF1D1D1D); // Card için hafif daha açık

  /// Text (Metin) Renkleri - Dark Mode
  /// Daha iyi kontrast için optimize edilmiş
  static const Color textPrimaryDark = Color(0xFFE8E8E8); // Daha parlak beyaz (WCAG AAA)
  static const Color textSecondaryDark = Color(0xFFB0B0B0); // Daha belirgin ikincil metin

  /// Border (Kenarlık) Renkleri - Dark Mode
  /// Daha belirgin ve görünür border'lar
  static const Color borderColorDark = Color(0xFF5A5A5A); // Daha belirgin border
  static const Color borderColorLightDark = Color(0xFF3A3A3A); // Hafif border
  static const Color borderColorInputDark = Color(0xFF2A2A2A); // Input kenarlığı (daha belirgin)

  // ============================================================================
  // 🔘 GRİ TONLAR - BACKWARD COMPATIBILITY (Light mode için)
  // ============================================================================

  /// Surface (Yüzey) Renkleri
  static const Color surfaceColor = surfaceColorLight;
  static const Color surfaceContainerHighest = surfaceContainerHighestLight;
  static const Color cardColor = cardColorLight;

  /// Text (Metin) Renkleri
  static const Color textPrimary = textPrimaryLight;
  static const Color textSecondary = textSecondaryLight;

  /// Border (Kenarlık) Renkleri
  static const Color borderColor = borderColorLightMode;
  static const Color borderColorLight = borderColorLightLightMode;
  static const Color borderColorInput = borderColorInputLightMode;

  /// Shadow (Gölge) Renkleri
  static const Color shadowColor = Color(0xFF000000); // Siyah (light mode - hafif opacity ile kullanılır)
  static const Color shadowColorDark = Color(0xFF000000); // Siyah (dark mode - daha opak)
  
  /// Brightness'a göre shadow rengi döndürür
  static Color getShadowColor(Brightness brightness) {
    return brightness == Brightness.dark ? shadowColorDark : shadowColor;
  }
  
  /// Brightness'a göre success container döndürür
  static Color getSuccessContainer(Brightness brightness) {
    return brightness == Brightness.dark ? successContainerDark : successContainerLight;
  }
  
  /// Brightness'a göre success container text döndürür
  static Color getSuccessContainerText(Brightness brightness) {
    return brightness == Brightness.dark ? successContainerTextDark : successContainerTextLight;
  }
  
  /// Brightness'a göre warning container döndürür
  static Color getWarningContainer(Brightness brightness) {
    return brightness == Brightness.dark ? warningContainerDark : warningContainerLight;
  }
  
  /// Brightness'a göre warning container text döndürür
  static Color getWarningContainerText(Brightness brightness) {
    return brightness == Brightness.dark ? warningContainerTextDark : warningContainerTextLight;
  }

  // ============================================================================
  // 🎨 DERİVED COLORS (Türetilmiş Renkler)
  // ============================================================================

  /// Primary Container (Primary Arka Plan)
  /// Primary renginin açık versiyonu
  static Color get primaryContainer => _lightenColor(primaryColor, 0.85);

  /// Primary Container Text (Primary Container Üzerindeki Metin)
  /// Primary container üzerinde okunabilir koyu renk
  static Color get primaryContainerText => _darkenColor(primaryColor, 0.4);

  /// Secondary Container (Secondary Arka Plan)
  /// Secondary renginin açık versiyonu
  static Color get secondaryContainer => _lightenColor(secondaryColor, 0.85);

  /// Secondary Container Text (Secondary Container Üzerindeki Metin)
  /// Secondary container üzerinde okunabilir koyu renk
  static Color get secondaryContainerText => _darkenColor(secondaryColor, 0.4);

  /// Tertiary Container (Tertiary Arka Plan)
  /// Tertiary renginin açık versiyonu
  static Color get tertiaryContainer => _lightenColor(tertiaryColor, 0.85);

  /// Tertiary Container Text (Tertiary Container Üzerindeki Metin)
  /// Tertiary container üzerinde okunabilir koyu renk
  static Color get tertiaryContainerText => _darkenColor(tertiaryColor, 0.4);

  /// Error Container (Error Arka Plan)
  /// Error renginin açık versiyonu
  static const Color errorContainer = Color(0xFFFEE2E2); // Light red (light mode)
  static const Color errorContainerText = Color(0xFF991B1B); // Dark red (light mode)
  
  /// Success Container - Light Mode
  static const Color successContainerLight = Color(0xFFD1FAE5); // Açık yeşil arka plan
  static const Color successContainerTextLight = Color(0xFF065F46); // Koyu yeşil metin
  
  /// Warning Container - Light Mode
  static const Color warningContainerLight = Color(0xFFFEF3C7); // Açık amber arka plan
  static const Color warningContainerTextLight = Color(0xFF92400E); // Koyu amber metin
  
  /// Error Container - Dark Mode
  static const Color errorContainerDark = Color(0xFF4A1F1F); // Koyu kırmızı arka plan
  static const Color errorContainerTextDark = Color(0xFFFF6B6B); // Açık kırmızı metin
  
  /// Success Container - Dark Mode
  static const Color successContainerDark = Color(0xFF1F4A2F); // Koyu yeşil arka plan
  static const Color successContainerTextDark = Color(0xFF6BFF8B); // Açık yeşil metin
  
  /// Warning Container - Dark Mode
  static const Color warningContainerDark = Color(0xFF4A3F1F); // Koyu amber arka plan
  static const Color warningContainerTextDark = Color(0xFFFFD96B); // Açık amber metin

  // ============================================================================
  // 🔧 HELPER METHODS
  // ============================================================================

  /// Renk açıklığı artırır (lighten)
  static Color _lightenColor(Color color, double amount) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
  }

  /// Renk koyuluğu artırır (darken)
  static Color _darkenColor(Color color, double amount) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }

  /// Gradient Success (Başarı Gradient)
  static List<Color> get gradientSuccess => [successColor, successColorLight];

  /// Gradient Error (Hata Gradient)
  static List<Color> get gradientError => [errorColor, errorColorLight];

  // ============================================================================
  // 🌓 DARK MODE HELPER METHODS
  // ============================================================================

  /// Brightness'a göre surface rengi döndürür
  static Color getSurfaceColor(Brightness brightness) {
    return brightness == Brightness.dark ? surfaceColorDark : surfaceColorLight;
  }

  /// Brightness'a göre surface container highest rengi döndürür
  static Color getSurfaceContainerHighest(Brightness brightness) {
    return brightness == Brightness.dark 
        ? surfaceContainerHighestDark 
        : surfaceContainerHighestLight;
  }

  /// Brightness'a göre card rengi döndürür
  static Color getCardColor(Brightness brightness) {
    return brightness == Brightness.dark ? cardColorDark : cardColorLight;
  }

  /// Brightness'a göre text primary rengi döndürür
  static Color getTextPrimary(Brightness brightness) {
    return brightness == Brightness.dark ? textPrimaryDark : textPrimaryLight;
  }

  /// Brightness'a göre text secondary rengi döndürür
  static Color getTextSecondary(Brightness brightness) {
    return brightness == Brightness.dark ? textSecondaryDark : textSecondaryLight;
  }

  /// Brightness'a göre border rengi döndürür
  static Color getBorderColor(Brightness brightness) {
    return brightness == Brightness.dark ? borderColorDark : borderColorLightMode;
  }

  /// Brightness'a göre border light rengi döndürür
  static Color getBorderColorLight(Brightness brightness) {
    return brightness == Brightness.dark ? borderColorLightDark : borderColorLightLightMode;
  }

  /// Brightness'a göre border input rengi döndürür
  static Color getBorderColorInput(Brightness brightness) {
    return brightness == Brightness.dark ? borderColorInputDark : borderColorInputLightMode;
  }

  /// Brightness'a göre primary gradient döndürür
  static List<Color> getGradientPrimary(Brightness brightness) {
    if (brightness == Brightness.dark) {
      // Dark mode için yumuşak gradient - çok subtle geçişler
      return [
        const Color(0xFF121212), // Çok koyu başlangıç (surfaceColorDark ile aynı)
        const Color(0xFF151515), // Çok hafif açık
        const Color(0xFF181818), // Biraz daha açık
        const Color(0xFF1A1A1A), // En açık ton
      ];
    }
    return gradientPrimary;
  }

  /// Brightness'a göre primary light gradient döndürür
  static List<Color> getGradientPrimaryLight(Brightness brightness) {
    if (brightness == Brightness.dark) {
      // Dark mode için düz siyah - gradient yok
      return [
        surfaceColorDark, // Düz, temiz siyah (#121212)
        surfaceColorDark, // Aynı renk (gradient efekti yok)
      ];
    }
    // Light mode için daha belirgin ve canlı gradient
    return [
      const Color(0xFF578FCA), // Lighter Blue - daha belirgin
      const Color(0xFFA1E3F9), // Light Sky Blue - daha belirgin
      const Color(0xFFD1F8EF), // Very Pale Mint Green - daha belirgin
    ];
  }
  
  /// Brightness'a göre error container döndürür
  static Color getErrorContainer(Brightness brightness) {
    return brightness == Brightness.dark ? errorContainerDark : errorContainer;
  }
  
  /// Brightness'a göre error container text döndürür
  static Color getErrorContainerText(Brightness brightness) {
    return brightness == Brightness.dark ? errorContainerTextDark : errorContainerText;
  }

  // ============================================================================
  // 🖼️ GRADIENT / GÖRSEL ARKA PLAN ÜZERİNDE İÇERİK RENKLERİ
  // ============================================================================

  /// Gradient veya arka plan görseli üzerindeki ana metin rengi.
  /// Light: koyu metin, Dark: açık metin.
  static Color getOverlayTextPrimary(Brightness brightness) {
    return getTextPrimary(brightness);
  }

  /// Gradient veya arka plan görseli üzerindeki ikincil metin rengi.
  static Color getOverlayTextSecondary(Brightness brightness) {
    return getTextSecondary(brightness);
  }

  /// Gradient/görsel üzerinde vurgu rengi (buton kenarlığı, ikon).
  static Color getOverlayAccent(Brightness brightness) {
    return brightness == Brightness.dark ? const Color(0xFFFFFFFF) : primaryColor;
  }

  /// Gradient/görsel üzerinde outline buton kenarlığı.
  static Color getOverlayBorder(Brightness brightness) {
    return getOverlayAccent(brightness).withValues(
      alpha: brightness == Brightness.dark ? 0.7 : 0.55,
    );
  }
}

