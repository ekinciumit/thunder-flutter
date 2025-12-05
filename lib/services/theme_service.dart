import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme Service
/// 
/// Uygulama temasını (light/dark/system) yönetir ve SharedPreferences'a kaydeder.
class ThemeService extends ChangeNotifier {
  static const String _themeKey = 'selected_theme';
  
  ThemeMode _themeMode = ThemeMode.light;
  
  ThemeMode get themeMode => _themeMode;
  
  bool get isLight => _themeMode == ThemeMode.light;
  bool get isDark => _themeMode == ThemeMode.dark;
  bool get isSystem => _themeMode == ThemeMode.system;
  
  /// Uygulama başlatıldığında kaydedilen temayı yükle
  Future<void> loadSavedTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeIndex = prefs.getInt(_themeKey) ?? 0;
      _themeMode = ThemeMode.values[themeIndex];
      notifyListeners();
    } catch (e) {
      _themeMode = ThemeMode.light;
    }
  }
  
  /// Tema değiştir ve kaydet
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    
    _themeMode = mode;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeKey, mode.index);
    } catch (e) {
      // Hata durumunda sessizce devam et
    }
  }
  
  /// Aydınlık moda geç
  Future<void> setLightMode() async {
    await setThemeMode(ThemeMode.light);
  }
  
  /// Karanlık moda geç
  Future<void> setDarkMode() async {
    await setThemeMode(ThemeMode.dark);
  }
  
  /// Sistem ayarını kullan
  Future<void> setSystemMode() async {
    await setThemeMode(ThemeMode.system);
  }
  
  /// Temayı toggle et (light <-> dark)
  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.dark) {
      await setLightMode();
    } else {
      await setDarkMode();
    }
  }
}

