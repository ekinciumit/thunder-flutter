import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Category utility functions
class CategoryUtils {
  /// Kategori renk şemasını döndürür
  static Map<String, Color> getCategoryColorScheme(String category) {
    switch (category) {
      case 'Müzik':
        return {
          'primary': const Color(0xFF7C3AED), // Deep purple
          'secondary': const Color(0xFFA855F7), // Lighter purple
        };
      case 'Spor':
        return {
          'primary': const Color(0xFF2563EB), // Blue
          'secondary': const Color(0xFF3B82F6), // Lighter blue
        };
      case 'Yemek':
        return {
          'primary': const Color(0xFFEA580C), // Orange
          'secondary': const Color(0xFFFB923C), // Lighter orange
        };
      case 'Sanat':
        return {
          'primary': const Color(0xFFDC2626), // Red
          'secondary': const Color(0xFFEF4444), // Lighter red
        };
      case 'Parti':
        return {
          'primary': const Color(0xFF059669), // Teal
          'secondary': const Color(0xFF10B981), // Lighter teal
        };
      case 'Teknoloji':
        return {
          'primary': const Color(0xFF4F46E5), // Indigo
          'secondary': const Color(0xFF6366F1), // Lighter indigo
        };
      case 'Doğa':
        return {
          'primary': const Color(0xFF16A34A), // Green
          'secondary': const Color(0xFF22C55E), // Lighter green
        };
      case 'Eğitim':
        return {
          'primary': const Color(0xFF92400E), // Brown
          'secondary': const Color(0xFFB45309), // Lighter brown
        };
      case 'Oyun':
        return {
          'primary': const Color(0xFF7C2D12), // Dark brown
          'secondary': const Color(0xFF991B1B), // Lighter brown
        };
      default: // Diğer
        return {
          'primary': const Color(0xFF6B7280), // Gray
          'secondary': Colors.grey.shade400,
        };
    }
  }

  /// Kategori için BitmapDescriptor döndürür (fallback için)
  static BitmapDescriptor getCategoryIconFallback(String category) {
    switch (category) {
      case 'Müzik':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
      case 'Spor':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      case 'Yemek':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      case 'Sanat':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose);
      case 'Parti':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueMagenta);
      case 'Teknoloji':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
      case 'Doğa':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      case 'Eğitim':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      case 'Oyun':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
      default:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    }
  }

  /// Kategori listesi
  static const List<String> categories = [
    'Müzik',
    'Spor',
    'Yemek',
    'Sanat',
    'Parti',
    'Teknoloji',
    'Doğa',
    'Eğitim',
    'Oyun',
    'Diğer'
  ];
}

