import 'package:flutter/material.dart';

/// App Color Configuration - BACKUP
/// 
/// Mevcut renklerin yedeği
/// Geri almak için bu dosyadaki değerleri app_color_config.dart'a kopyalayın

class AppColorConfigBackup {
  AppColorConfigBackup._();

  // ============================================================================
  // 🎨 MEVCUT RENKLER (YEDEK)
  // ============================================================================

  /// Primary Color (Ana Renk)
  static const Color primaryColor = Color(0xFF6366F1); // Indigo

  /// Secondary Color (İkincil Renk)
  static const Color secondaryColor = Color(0xFF8B5CF6); // Purple

  /// Tertiary Color (Üçüncül Renk)
  static const Color tertiaryColor = Color(0xFF06B6D4); // Cyan

  // ============================================================================
  // 🌈 MEVCUT GRADIENT RENKLER (YEDEK)
  // ============================================================================

  /// Primary Gradient (Ana Gradient)
  static const List<Color> gradientPrimary = [
    Color(0xFF7F53AC), // Deep purple
    Color(0xFF647DEE), // Blue
    Color(0xFFFFD54F), // Amber
  ];

  /// Primary Light Gradient (Açık Ana Gradient)
  static const List<Color> gradientPrimaryLight = [
    Color(0xFFE0E7FF), // Light indigo
    Color(0xFFF3E8FF), // Light purple
  ];

  /// Secondary Gradient (İkincil Gradient)
  static const List<Color> gradientSecondary = [
    Color(0xFF6366F1), // Indigo
    Color(0xFF8B5CF6), // Purple
  ];
}

