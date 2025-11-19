/// Uygulama genelinde kullanılan sabitler
/// 
/// Bu sınıf SOLID prensiplerinden Single Responsibility Principle'a uyar:
/// - Sadece uygulama sabitlerini içerir
/// - Değişmeyen değerleri merkezi bir yerde toplar
library;
/// 
/// ŞU AN: Bu sabitler sadece ekleniyor, mevcut kod çalışmaya devam ediyor
/// İleride bu sabitleri kullanacağız.

class AppConstants {
  // Private constructor - Bu sınıf sadece sabitler içerir, instance oluşturulamaz
  AppConstants._();

  // ==================== PAGINATION LIMITS ====================
  
  /// Mesaj listesi için varsayılan limit
  static const int defaultMessageLimit = 50;
  
  /// Eski mesajları yüklerken kullanılan limit
  static const int olderMessagesLimit = 20;
  
  /// Tüm mesajlarda arama için limit
  static const int searchAllMessagesLimit = 100;
  
  /// Etkinlik listesi için varsayılan limit
  static const int defaultEventLimit = 50;
  
  /// Kullanıcı listesi için limit
  static const int defaultUserLimit = 10;

  // ==================== CACHE SETTINGS ====================
  
  /// Cache süresi (saat cinsinden)
  static const int cacheExpiryHours = 24;
  
  /// Cache temizleme süresi (gün cinsinden)
  static const int cacheCleanupDays = 7;

  // ==================== MESSAGE SETTINGS ====================
  
  /// Maksimum mesaj uzunluğu (karakter sayısı)
  static const int maxMessageLength = 1000;
  
  /// Maksimum dosya boyutu (byte cinsinden) - 10 MB
  static const int maxFileSize = 10 * 1024 * 1024;
  
  /// Maksimum ses mesajı süresi (saniye cinsinden)
  static const int maxVoiceMessageDuration = 60;

  // ==================== EVENT SETTINGS ====================
  
  /// Maksimum etkinlik katılımcı sayısı
  static const int maxEventParticipants = 100;
  
  /// Minimum etkinlik katılımcı sayısı
  static const int minEventParticipants = 1;
  
  /// Etkinlik oluşturma için minimum gün sayısı (bugünden itibaren)
  static const int minEventDaysInAdvance = 0;
  
  /// Etkinlik oluşturma için maksimum gün sayısı (bugünden itibaren)
  static const int maxEventDaysInAdvance = 365;

  // ==================== UI SETTINGS ====================
  
  /// Animasyon süresi (milisaniye cinsinden)
  static const int animationDurationMs = 300;
  
  /// Snackbar gösterim süresi (saniye cinsinden)
  static const int snackbarDurationSeconds = 3;
  
  /// Debounce süresi (milisaniye cinsinden) - arama için
  static const int debounceDurationMs = 500;

  // ==================== NETWORK SETTINGS ====================
  
  /// Request timeout süresi (saniye cinsinden)
  static const int requestTimeoutSeconds = 30;
  
  /// Retry deneme sayısı
  static const int maxRetryAttempts = 3;
  
  /// Retry bekleme süresi (saniye cinsinden)
  static const int retryDelaySeconds = 2;

  // ==================== VALIDATION SETTINGS ====================
  
  /// Minimum şifre uzunluğu
  static const int minPasswordLength = 6;
  
  /// Maksimum şifre uzunluğu
  static const int maxPasswordLength = 128;
  
  /// Minimum kullanıcı adı uzunluğu
  static const int minUsernameLength = 3;
  
  /// Maksimum kullanıcı adı uzunluğu
  static const int maxUsernameLength = 30;
  
  /// Minimum display name uzunluğu
  static const int minDisplayNameLength = 2;
  
  /// Maksimum display name uzunluğu
  static const int maxDisplayNameLength = 50;

  // ==================== FILE SETTINGS ====================
  
  /// Desteklenen resim formatları
  static const List<String> supportedImageFormats = [
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
  ];
  
  /// Desteklenen video formatları
  static const List<String> supportedVideoFormats = [
    'mp4',
    'mov',
    'avi',
    'mkv',
  ];
  
  /// Desteklenen ses formatları
  static const List<String> supportedAudioFormats = [
    'mp3',
    'm4a',
    'wav',
    'aac',
  ];
  
  /// Desteklenen dosya formatları
  static const List<String> supportedFileFormats = [
    'pdf',
    'doc',
    'docx',
    'xls',
    'xlsx',
    'ppt',
    'pptx',
    'txt',
  ];
}

