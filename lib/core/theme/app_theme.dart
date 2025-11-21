import 'package:flutter/material.dart';

/// App Theme Configuration
/// 
/// Clean Architecture: Theme yapılandırması ayrı dosyada
class AppTheme {
  // Private constructor - Bu sınıf sadece static members içerir
  AppTheme._();

  /// Spacing Constants
  /// 
  /// Uygulama genelinde tutarlı spacing değerleri
  static const double spacingXs = 4.0;      // Çok küçük boşluk
  static const double spacingSm = 8.0;      // Küçük boşluk
  static const double spacingMd = 12.0;     // Orta boşluk
  static const double spacingLg = 16.0;     // Büyük boşluk
  static const double spacingXl = 20.0;     // Çok büyük boşluk
  static const double spacingXxl = 24.0;    // Extra büyük boşluk
  static const double spacingXxxl = 32.0;   // Çok extra büyük boşluk

  /// Border Radius Constants
  /// 
  /// Uygulama genelinde tutarlı border radius değerleri
  static const double radiusXs = 4.0;      // Çok küçük
  static const double radiusSm = 8.0;      // Küçük
  static const double radiusMd = 12.0;     // Orta
  static const double radiusLg = 14.0;     // Büyük
  static const double radiusXl = 16.0;     // Çok büyük
  static const double radiusXxl = 20.0;    // Extra büyük
  static const double radiusXxxl = 24.0;   // Çok extra büyük
  static const double radiusRound = 28.0;  // Yuvarlak (modal'lar için)
  static const double radiusFull = 32.0;   // Tam yuvarlak (card'lar için)

  /// Alpha Constants
  /// 
  /// Uygulama genelinde kullanılan alpha (opacity) değerleri
  static const int alphaVeryLight = 10;   // Çok açık (background)
  static const int alphaLight = 15;       // Açık
  static const int alphaMediumLight = 20; // Orta-açık
  static const int alphaMedium = 25;      // Orta
  static const int alphaMediumDark = 30;  // Orta-koyu
  static const int alphaDark = 40;        // Koyu
  static const int alphaDarker = 60;      // Daha koyu
  static const int alphaVeryDark = 100;   // Çok koyu
  static const int alphaAlmostOpaque = 120; // Neredeyse opak

  /// Icon Sizes
  /// 
  /// Uygulama genelinde tutarlı icon boyutları
  static const double iconSizeXs = 16.0;   // Çok küçük
  static const double iconSizeSm = 20.0;   // Küçük
  static const double iconSizeMd = 24.0;   // Orta
  static const double iconSizeLg = 32.0;   // Büyük
  static const double iconSizeXl = 48.0;   // Çok büyük
  static const double iconSizeXxl = 64.0;  // Extra büyük

  /// Gradient Colors
  /// 
  /// Uygulama genelinde kullanılan gradient renk kombinasyonları
  static const List<Color> gradientPrimary = [
    Color(0xFF7F53AC), // Deep purple
    Color(0xFF647DEE), // Blue
    Color(0xFFFFD54F), // Amber
  ];
  
  static const List<Color> gradientPrimaryLight = [
    Color(0xFFE0E7FF), // Light indigo
    Color(0xFFF3E8FF), // Light purple
  ];
  
  static const List<Color> gradientSecondary = [
    Color(0xFF6366F1), // Indigo
    Color(0xFF8B5CF6), // Purple
  ];
  
  static const List<Color> gradientSuccess = [
    Color(0xFF10B981), // Green
    Color(0xFF34D399), // Light green
  ];
  
  static const List<Color> gradientError = [
    Color(0xFFDC2626), // Red
    Color(0xFFEF4444), // Light red
  ];
  
  /// Helper: Alpha ile gradient oluştur
  static List<Color> gradientWithAlpha(List<Color> colors, int alpha) {
    return colors.map((color) => color.withAlpha(alpha)).toList();
  }

  /// Shadow Helpers
  /// 
  /// Uygulama genelinde tutarlı shadow değerleri
  static BoxShadow shadowSoft({
    Color? color,
    double blurRadius = 4.0,
    Offset offset = const Offset(0, 2),
  }) => BoxShadow(
    color: color ?? Colors.black.withAlpha(alphaVeryDark),
    blurRadius: blurRadius,
    offset: offset,
  );
  
  static BoxShadow shadowMedium({
    Color? color,
    double blurRadius = 12.0,
    Offset offset = const Offset(0, 4),
  }) => BoxShadow(
    color: color ?? Colors.black.withAlpha(alphaDarker),
    blurRadius: blurRadius,
    offset: offset,
  );
  
  static BoxShadow shadowLarge({
    Color? color,
    double blurRadius = 24.0,
    Offset offset = const Offset(0, 8),
  }) => BoxShadow(
    color: color ?? Colors.black.withAlpha(alphaDark),
    blurRadius: blurRadius,
    offset: offset,
  );
  /// Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6366F1), // Modern indigo
        brightness: Brightness.light,
        primary: const Color(0xFF6366F1), // Indigo
        onPrimary: const Color(0xFFFFFFFF), // White on primary
        primaryContainer: const Color(0xFFE0E7FF), // Light indigo
        onPrimaryContainer: const Color(0xFF1E1B93), // Dark indigo
        secondary: const Color(0xFF8B5CF6), // Purple
        onSecondary: const Color(0xFFFFFFFF), // White on secondary
        secondaryContainer: const Color(0xFFF3E8FF), // Light purple
        onSecondaryContainer: const Color(0xFF4C1D95), // Dark purple
        tertiary: const Color(0xFF06B6D4), // Cyan
        onTertiary: const Color(0xFFFFFFFF), // White on tertiary
        tertiaryContainer: const Color(0xFFCCFBF1), // Light cyan
        onTertiaryContainer: const Color(0xFF0F766E), // Dark cyan
        error: const Color(0xFFDC2626), // Red
        onError: const Color(0xFFFFFFFF), // White on error
        errorContainer: const Color(0xFFFEE2E2), // Light red
        onErrorContainer: const Color(0xFF991B1B), // Dark red
        surface: const Color(0xFFFFFBFE), // Pure white
        onSurface: const Color(0xFF1C1B1F), // Dark text
        surfaceContainerHighest: const Color(0xFFF3F4F6), // Light gray
        onSurfaceVariant: const Color(0xFF49454F), // Medium gray text
        outline: const Color(0xFF79747E), // Border color
        outlineVariant: const Color(0xFFCAC4D0), // Light border
        shadow: const Color(0xFF000000), // Black shadow
        scrim: const Color(0xFF000000), // Black scrim
        inverseSurface: const Color(0xFF313033), // Dark surface
        onInverseSurface: const Color(0xFFF4EFF4), // Light text on dark
        inversePrimary: const Color(0xFFC5C0FF), // Light indigo
        surfaceTint: const Color(0xFF6366F1), // Indigo tint
      ),
      scaffoldBackgroundColor: const Color(0xFFFFFBFE),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: Colors.transparent,
        foregroundColor: Color(0xFF1C1B1F),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF3F4F6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDC2626)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  /// Dark Theme (gelecekte eklenebilir)
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6366F1),
        brightness: Brightness.dark,
      ),
    );
  }
}

