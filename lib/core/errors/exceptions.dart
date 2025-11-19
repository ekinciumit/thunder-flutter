/// Uygulama seviyesinde exception sınıfları
/// 
/// Bu sınıflar SOLID prensiplerinden Single Responsibility Principle'a uyar:
/// - Her exception sınıfı belirli bir hata türünü temsil eder
library;

/// Sunucu (server) hataları için exception
class ServerException implements Exception {
  final String message;
  ServerException(this.message);
  
  @override
  String toString() => 'ServerException: $message';
}

/// Cache (yerel depolama) hataları için exception
class CacheException implements Exception {
  final String message;
  CacheException(this.message);
  
  @override
  String toString() => 'CacheException: $message';
}

/// Network (internet bağlantısı) hataları için exception
class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);
  
  @override
  String toString() => 'NetworkException: $message';
}

/// Validation (doğrulama) hataları için exception
class ValidationException implements Exception {
  final String message;
  ValidationException(this.message);
  
  @override
  String toString() => 'ValidationException: $message';
}

/// Permission (izin) hataları için exception
class PermissionException implements Exception {
  final String message;
  PermissionException(this.message);
  
  @override
  String toString() => 'PermissionException: $message';
}

