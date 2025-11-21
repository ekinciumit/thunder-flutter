import 'package:flutter/material.dart';
import 'app_color_config.dart';

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
  /// AppColorConfig'den alınır
  static List<Color> get gradientPrimary => AppColorConfig.gradientPrimary;
  
  static List<Color> get gradientPrimaryLight => AppColorConfig.gradientPrimaryLight;
  
  static List<Color> get gradientSecondary => AppColorConfig.gradientSecondary;
  
  static List<Color> get gradientSuccess => AppColorConfig.gradientSuccess;
  
  static List<Color> get gradientError => AppColorConfig.gradientError;
  
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
        seedColor: AppColorConfig.primaryColor,
        brightness: Brightness.light,
        primary: AppColorConfig.primaryColor,
        onPrimary: const Color(0xFFFFFFFF), // White on primary
        primaryContainer: AppColorConfig.primaryContainer,
        onPrimaryContainer: AppColorConfig.primaryContainerText,
        secondary: AppColorConfig.secondaryColor,
        onSecondary: const Color(0xFF1C1B1F), // Dark text on secondary
        secondaryContainer: AppColorConfig.secondaryContainer,
        onSecondaryContainer: AppColorConfig.secondaryContainerText,
        tertiary: AppColorConfig.tertiaryColor,
        onTertiary: const Color(0xFFFFFFFF), // White on tertiary
        tertiaryContainer: AppColorConfig.tertiaryContainer,
        onTertiaryContainer: AppColorConfig.tertiaryContainerText,
        error: AppColorConfig.errorColor,
        onError: const Color(0xFFFFFFFF), // White on error
        errorContainer: AppColorConfig.errorContainer,
        onErrorContainer: AppColorConfig.errorContainerText,
        surface: AppColorConfig.surfaceColor,
        onSurface: AppColorConfig.textPrimary,
        surfaceContainerHighest: AppColorConfig.surfaceContainerHighest,
        onSurfaceVariant: AppColorConfig.textSecondary,
        outline: AppColorConfig.borderColor,
        outlineVariant: AppColorConfig.borderColorLight,
        shadow: AppColorConfig.shadowColor,
        scrim: AppColorConfig.shadowColor,
        inverseSurface: const Color(0xFF313033), // Dark surface
        onInverseSurface: const Color(0xFFF4EFF4), // Light text on dark
        inversePrimary: AppColorConfig.primaryColor.withAlpha(AppTheme.alphaMedium),
        surfaceTint: AppColorConfig.primaryColor,
      ),
      scaffoldBackgroundColor: AppColorConfig.surfaceColor,
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
        fillColor: AppColorConfig.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColorConfig.borderColorInput),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColorConfig.borderColorInput),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColorConfig.primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColorConfig.errorColor),
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
        seedColor: AppColorConfig.primaryColor,
        brightness: Brightness.dark,
      ),
    );
  }
}

