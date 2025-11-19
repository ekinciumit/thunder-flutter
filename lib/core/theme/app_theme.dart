import 'package:flutter/material.dart';

/// App Theme Configuration
/// 
/// Clean Architecture: Theme yapılandırması ayrı dosyada
class AppTheme {
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

