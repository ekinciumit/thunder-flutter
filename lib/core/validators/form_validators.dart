/// Form Validators
/// 
/// Merkezi form validasyon servisi
/// Tüm form alanları için validator fonksiyonları
library;

class FormValidators {
  /// Email format kontrolü için regex pattern
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  /// Şifre güçlülük kontrolü için regex pattern
  /// En az 6 karakter, en az bir harf ve bir rakam
  static final RegExp _passwordRegex = RegExp(
    r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d@$!%*#?&]{6,}$',
  );

  /// İsim format kontrolü için regex pattern
  /// Sadece harf, boşluk ve Türkçe karakterler
  static final RegExp _nameRegex = RegExp(
    r'^[a-zA-ZğüşıöçĞÜŞİÖÇ\s]{2,}$',
  );

  /// Email validator
  /// 
  /// Kontroller:
  /// - Boş olmamalı
  /// - Geçerli email formatı olmalı
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'E-posta adresi zorunludur';
    }

    if (!_emailRegex.hasMatch(value.trim())) {
      return 'Geçerli bir e-posta adresi giriniz';
    }

    return null;
  }

  /// Password validator
  /// 
  /// Kontroller:
  /// - Boş olmamalı
  /// - En az 6 karakter olmalı
  /// - En az bir harf ve bir rakam içermeli
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Şifre zorunludur';
    }

    if (value.length < 6) {
      return 'Şifre en az 6 karakter olmalıdır';
    }

    if (!_passwordRegex.hasMatch(value)) {
      return 'Şifre en az bir harf ve bir rakam içermelidir';
    }

    return null;
  }

  /// İsim validator
  /// 
  /// Kontroller:
  /// - Boş olmamalı
  /// - En az 2 karakter olmalı
  /// - Sadece harf, boşluk ve Türkçe karakterler içermeli
  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'İsim zorunludur';
    }

    final trimmedValue = value.trim();

    if (trimmedValue.length < 2) {
      return 'İsim en az 2 karakter olmalıdır';
    }

    if (!_nameRegex.hasMatch(trimmedValue)) {
      return 'İsim sadece harf ve boşluk içerebilir';
    }

    return null;
  }

  /// Bio validator
  /// 
  /// Kontroller:
  /// - Opsiyonel (boş olabilir)
  /// - Maksimum 500 karakter olmalı
  static String? bio(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Bio opsiyonel
    }

    if (value.length > 500) {
      return 'Biyografi en fazla 500 karakter olabilir';
    }

    return null;
  }

  /// Başlık validator
  /// 
  /// Kontroller:
  /// - Boş olmamalı
  /// - En az 3 karakter olmalı
  /// - En fazla 100 karakter olmalı
  static String? title(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Başlık zorunludur';
    }

    final trimmedValue = value.trim();

    if (trimmedValue.length < 3) {
      return 'Başlık en az 3 karakter olmalıdır';
    }

    if (trimmedValue.length > 100) {
      return 'Başlık en fazla 100 karakter olabilir';
    }

    return null;
  }

  /// Açıklama validator
  /// 
  /// Kontroller:
  /// - Boş olmamalı
  /// - En az 10 karakter olmalı
  /// - En fazla 2000 karakter olmalı
  static String? description(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Açıklama zorunludur';
    }

    final trimmedValue = value.trim();

    if (trimmedValue.length < 10) {
      return 'Açıklama en az 10 karakter olmalıdır';
    }

    if (trimmedValue.length > 2000) {
      return 'Açıklama en fazla 2000 karakter olabilir';
    }

    return null;
  }

  /// Adres validator
  /// 
  /// Kontroller:
  /// - Boş olmamalı
  /// - En az 5 karakter olmalı
  static String? address(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Adres zorunludur';
    }

    if (value.trim().length < 5) {
      return 'Adres en az 5 karakter olmalıdır';
    }

    return null;
  }

  /// Kotası validator
  /// 
  /// Kontroller:
  /// - Boş olmamalı
  /// - Geçerli bir sayı olmalı
  /// - En az 1 olmalı
  /// - En fazla 1000 olmalı
  static String? quota(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Kota zorunludur';
    }

    final quotaValue = int.tryParse(value.trim());
    if (quotaValue == null) {
      return 'Geçerli bir sayı giriniz';
    }

    if (quotaValue < 1) {
      return 'Kota en az 1 olmalıdır';
    }

    if (quotaValue > 1000) {
      return 'Kota en fazla 1000 olabilir';
    }

    return null;
  }

  /// Genel required validator
  /// 
  /// Herhangi bir alan için basit boş kontrolü
  static String? required(String? value, {String fieldName = 'Bu alan'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName zorunludur';
    }
    return null;
  }

  /// Minimum uzunluk validator
  /// 
  /// Belirli bir minimum uzunluk kontrolü
  static String? minLength(String? value, int minLength, {String fieldName = 'Bu alan'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName zorunludur';
    }

    if (value.trim().length < minLength) {
      return '$fieldName en az $minLength karakter olmalıdır';
    }

    return null;
  }

  /// Maksimum uzunluk validator
  /// 
  /// Belirli bir maksimum uzunluk kontrolü
  static String? maxLength(String? value, int maxLength, {String fieldName = 'Bu alan'}) {
    if (value == null || value.trim().isEmpty) {
      return null; // Boş değerler için max length kontrolü yapılmaz
    }

    if (value.length > maxLength) {
      return '$fieldName en fazla $maxLength karakter olabilir';
    }

    return null;
  }
}

