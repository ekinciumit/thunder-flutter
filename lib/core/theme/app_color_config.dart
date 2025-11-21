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
  static const Color primaryColor = Color(0xFF8CE4FF); // Sky Blue

  /// Secondary Color (İkincil Renk)
  /// İkincil butonlar, aksanlar için kullanılır
  static const Color secondaryColor = Color(0xFFFEEE91); // Pale Yellow

  /// Tertiary Color (Üçüncül Renk)
  /// Üçüncül vurgular, bilgi mesajları için kullanılır
  static const Color tertiaryColor = Color(0xFFFFA239); // Orange

  // ============================================================================
  // 🌈 GRADIENT RENKLER - Buradan değiştirebilirsiniz
  // ============================================================================

  /// Primary Gradient (Ana Gradient)
  /// Ana sayfa arka planları, büyük card'lar için
  static const List<Color> gradientPrimary = [
    Color(0xFF8CE4FF), // Sky Blue
    Color(0xFFFEEE91), // Pale Yellow
    Color(0xFFFFA239), // Orange
    Color(0xFFFF5656), // Coral/Reddish Orange
  ];

  /// Primary Light Gradient (Açık Ana Gradient)
  /// Hafif arka planlar, input alanları için
  static const List<Color> gradientPrimaryLight = [
    Color(0xFF8CE4FF), // Sky Blue
    Color(0xFFFEEE91), // Pale Yellow
  ];

  /// Secondary Gradient (İkincil Gradient)
  /// Butonlar, vurgular, navigation için
  static const List<Color> gradientSecondary = [
    Color(0xFFFFA239), // Orange
    Color(0xFFFF5656), // Coral/Reddish Orange
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
  // 🔘 GRİ TONLAR - SABİT (Değiştirmeyin)
  // ============================================================================

  /// Surface (Yüzey) Renkleri
  static const Color surfaceColor = Color(0xFFFFFBFE); // Neredeyse beyaz
  static const Color surfaceContainerHighest = Color(0xFFF3F4F6); // Açık gri
  static const Color cardColor = Colors.white; // Beyaz

  /// Text (Metin) Renkleri
  static const Color textPrimary = Color(0xFF1C1B1F); // Koyu gri (ana metin)
  static const Color textSecondary = Color(0xFF49454F); // Orta gri (ikincil metin)

  /// Border (Kenarlık) Renkleri
  static const Color borderColor = Color(0xFF79747E); // Orta gri
  static const Color borderColorLight = Color(0xFFCAC4D0); // Açık gri
  static const Color borderColorInput = Color(0xFFE5E7EB); // Input kenarlığı

  /// Shadow (Gölge) Renkleri
  static const Color shadowColor = Color(0xFF000000); // Siyah

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
  static const Color errorContainer = Color(0xFFFEE2E2); // Light red
  static const Color errorContainerText = Color(0xFF991B1B); // Dark red

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
}

