/// Form ve input doğrulama fonksiyonları
/// 
/// Bu sınıf SOLID prensiplerinden Single Responsibility Principle'a uyar:
/// - Sadece doğrulama (validation) işlemlerinden sorumlu
/// - Her fonksiyon tek bir şeyi doğrular
library;
/// 
/// ŞU AN: Bu fonksiyonlar sadece ekleniyor, mevcut kod çalışmaya devam ediyor
/// İleride bu validators'ları kullanacağız.

import '../constants/app_constants.dart';

class Validators {
  // Private constructor - Bu sınıf sadece static metodlar içerir
  Validators._();

  // ==================== EMAIL VALIDATION ====================
  
  /// Email formatını doğrular
  /// 
  /// Returns: true if valid, false otherwise
  static bool isValidEmail(String email) {
    if (email.isEmpty) return false;
    
    // Basit email regex pattern
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    return emailRegex.hasMatch(email);
  }

  // ==================== PASSWORD VALIDATION ====================
  
  /// Şifre uzunluğunu doğrular
  /// 
  /// Returns: true if valid, false otherwise
  static bool isValidPasswordLength(String password) {
    return password.length >= AppConstants.minPasswordLength &&
           password.length <= AppConstants.maxPasswordLength;
  }
  
  /// Şifre gücünü kontrol eder
  /// 
  /// Returns: true if strong, false otherwise
  /// Güçlü şifre: en az 6 karakter, büyük harf, küçük harf, rakam içermeli
  static bool isStrongPassword(String password) {
    if (!isValidPasswordLength(password)) return false;
    
    // En az bir büyük harf
    final hasUpperCase = RegExp(r'[A-Z]').hasMatch(password);
    // En az bir küçük harf
    final hasLowerCase = RegExp(r'[a-z]').hasMatch(password);
    // En az bir rakam
    final hasDigit = RegExp(r'[0-9]').hasMatch(password);
    
    return hasUpperCase && hasLowerCase && hasDigit;
  }

  // ==================== USERNAME VALIDATION ====================
  
  /// Kullanıcı adı formatını doğrular
  /// 
  /// Returns: true if valid, false otherwise
  /// Geçerli kullanıcı adı: 3-30 karakter, sadece harf, rakam, alt çizgi
  static bool isValidUsername(String username) {
    if (username.isEmpty) return false;
    
    // Uzunluk kontrolü
    if (username.length < AppConstants.minUsernameLength ||
        username.length > AppConstants.maxUsernameLength) {
      return false;
    }
    
    // Sadece harf, rakam ve alt çizgi içermeli
    final usernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');
    return usernameRegex.hasMatch(username);
  }

  // ==================== DISPLAY NAME VALIDATION ====================
  
  /// Display name (görünen isim) formatını doğrular
  /// 
  /// Returns: true if valid, false otherwise
  static bool isValidDisplayName(String displayName) {
    if (displayName.isEmpty) return false;
    
    // Uzunluk kontrolü
    if (displayName.length < AppConstants.minDisplayNameLength ||
        displayName.length > AppConstants.maxDisplayNameLength) {
      return false;
    }
    
    // Sadece boşluk değil
    if (displayName.trim().isEmpty) return false;
    
    return true;
  }

  // ==================== MESSAGE VALIDATION ====================
  
  /// Mesaj uzunluğunu doğrular
  /// 
  /// Returns: true if valid, false otherwise
  static bool isValidMessageLength(String message) {
    return message.length <= AppConstants.maxMessageLength;
  }
  
  /// Mesajın boş olmadığını kontrol eder
  /// 
  /// Returns: true if not empty, false otherwise
  static bool isNotEmptyMessage(String message) {
    return message.trim().isNotEmpty;
  }

  // ==================== FILE VALIDATION ====================
  
  /// Dosya boyutunu doğrular
  /// 
  /// Returns: true if valid, false otherwise
  static bool isValidFileSize(int fileSizeInBytes) {
    return fileSizeInBytes <= AppConstants.maxFileSize;
  }
  
  /// Resim formatını doğrular
  /// 
  /// Returns: true if valid, false otherwise
  static bool isValidImageFormat(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    return AppConstants.supportedImageFormats.contains(extension);
  }
  
  /// Video formatını doğrular
  /// 
  /// Returns: true if valid, false otherwise
  static bool isValidVideoFormat(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    return AppConstants.supportedVideoFormats.contains(extension);
  }
  
  /// Ses formatını doğrular
  /// 
  /// Returns: true if valid, false otherwise
  static bool isValidAudioFormat(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    return AppConstants.supportedAudioFormats.contains(extension);
  }
  
  /// Dosya formatını doğrular
  /// 
  /// Returns: true if valid, false otherwise
  static bool isValidFileFormat(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    return AppConstants.supportedFileFormats.contains(extension);
  }

  // ==================== EVENT VALIDATION ====================
  
  /// Etkinlik katılımcı sayısını doğrular
  /// 
  /// Returns: true if valid, false otherwise
  static bool isValidParticipantCount(int count) {
    return count >= AppConstants.minEventParticipants &&
           count <= AppConstants.maxEventParticipants;
  }
  
  /// Etkinlik tarihini doğrular (bugünden ileri bir tarih olmalı)
  /// 
  /// Returns: true if valid, false otherwise
  static bool isValidEventDate(DateTime eventDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDay = DateTime(eventDate.year, eventDate.month, eventDate.day);
    
    // Etkinlik tarihi bugünden önce olmamalı
    return eventDay.isAfter(today) || eventDay.isAtSameMomentAs(today);
  }

  // ==================== GENERAL VALIDATION ====================
  
  /// String'in boş olmadığını kontrol eder
  /// 
  /// Returns: true if not empty, false otherwise
  static bool isNotEmpty(String value) {
    return value.trim().isNotEmpty;
  }
  
  /// String'in minimum uzunluğunu kontrol eder
  /// 
  /// Returns: true if valid, false otherwise
  static bool hasMinLength(String value, int minLength) {
    return value.length >= minLength;
  }
  
  /// String'in maksimum uzunluğunu kontrol eder
  /// 
  /// Returns: true if valid, false otherwise
  static bool hasMaxLength(String value, int maxLength) {
    return value.length <= maxLength;
  }
  
  /// String'in belirli bir uzunluk aralığında olduğunu kontrol eder
  /// 
  /// Returns: true if valid, false otherwise
  static bool hasLengthBetween(String value, int minLength, int maxLength) {
    return value.length >= minLength && value.length <= maxLength;
  }
}

