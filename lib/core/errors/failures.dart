/// Uygulama seviyesinde failure (hata) sınıfları
/// 
/// Failure'lar, exception'ların domain katmanında kullanılan versiyonudur.
/// Clean Architecture'da domain katmanı exception'lara bağımlı olmamalı,
/// bu yüzden failure kullanırız.
/// 
/// ŞU AN: Bu sınıflar sadece ekleniyor, mevcut kod çalışmaya devam ediyor
/// İleride bu failure'ları kullanacağız.

/// Tüm failure'ların temel sınıfı
abstract class Failure {
  final String message;
  Failure(this.message);
  
  @override
  String toString() => message;
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;
}

/// Sunucu (server) hataları için failure
class ServerFailure extends Failure {
  ServerFailure(super.message);
}

/// Cache (yerel depolama) hataları için failure
class CacheFailure extends Failure {
  CacheFailure(super.message);
}

/// Network (internet bağlantısı) hataları için failure
class NetworkFailure extends Failure {
  NetworkFailure(super.message);
}

/// Validation (doğrulama) hataları için failure
class ValidationFailure extends Failure {
  ValidationFailure(super.message);
}

/// Permission (izin) hataları için failure
class PermissionFailure extends Failure {
  PermissionFailure(super.message);
}

/// Bilinmeyen hatalar için failure
class UnknownFailure extends Failure {
  UnknownFailure(super.message);
}

