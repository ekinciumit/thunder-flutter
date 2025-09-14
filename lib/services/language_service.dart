import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService extends ChangeNotifier {
  static const String _languageKey = 'selected_language';
  
  Locale _currentLocale = const Locale('tr', '');
  
  Locale get currentLocale => _currentLocale;
  
  bool get isTurkish => _currentLocale.languageCode == 'tr';
  bool get isEnglish => _currentLocale.languageCode == 'en';
  
  // Uygulama başlatıldığında kaydedilen dili yükle
  Future<void> loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString(_languageKey) ?? 'tr';
      _currentLocale = Locale(languageCode, '');
      notifyListeners();
    } catch (e) {
      // Hata durumunda varsayılan dil (Türkçe)
      _currentLocale = const Locale('tr', '');
    }
  }
  
  // Dil değiştir ve kaydet
  Future<void> changeLanguage(Locale locale) async {
    if (_currentLocale == locale) return;
    
    _currentLocale = locale;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, locale.languageCode);
    } catch (e) {
      // Hata durumunda sessizce devam et
    }
  }
  
  // Türkçe'ye geç
  Future<void> setTurkish() async {
    await changeLanguage(const Locale('tr', ''));
  }
  
  // İngilizce'ye geç
  Future<void> setEnglish() async {
    await changeLanguage(const Locale('en', ''));
  }
}

