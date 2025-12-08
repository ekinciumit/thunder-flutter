/// Uygulama seviyesinde failure (hata) sınıfları
/// 
/// Failure'lar, exception'ların domain katmanında kullanılan versiyonudur.
/// Clean Architecture'da domain katmanı exception'lara bağımlı olmamalı,
/// bu yüzden failure kullanırız.

/// Either type için basit bir wrapper
/// 
/// Clean Architecture'da standart pattern:
/// - Left: Failure (hata durumu)
/// - Right: Success (başarılı sonuç)
/// 
/// Generic parametreler:
/// - L: Left tipi (genellikle Failure)
/// - R: Right tipi (genellikle başarılı sonuç)
class Either<L, R> {
  final L? _left;
  final R? _right;
  final bool _isLeft;

  Either._(this._left, this._right, this._isLeft);

  factory Either.left(L value) => Either._(value, null, true);
  factory Either.right(R value) => Either._(null, value, false);
  
  /// void döndüren metodlar için özel factory
  /// Dart'ta void aslında Null tipidir, bu yüzden null geçebiliriz
  static Either<L, void> rightVoid<L>() => Either._(null, null, false);

  bool get isLeft => _isLeft;
  bool get isRight => !_isLeft;

  L get left {
    if (!_isLeft) {
      throw StateError('Either is Right, not Left');
    }
    final value = _left;
    if (value == null) {
      throw StateError('Either is Left but value is null');
    }
    return value;
  }
  
  R get right {
    if (_isLeft) {
      throw StateError('Either is Left, not Right');
    }
    // void tipi için null geçilebilir (void aslında Null'tır)
    // Nullable tipler için de null geçilebilir
    return _right as R;
  }

  /// Either'i düz bir değere çevirir
  /// 
  /// leftFn: Left durumunda çağrılacak fonksiyon
  /// rightFn: Right durumunda çağrılacak fonksiyon
  T fold<T>(T Function(L) leftFn, T Function(R) rightFn) {
    if (_isLeft) {
      final value = _left;
      if (value == null) {
        throw StateError('Either is Left but value is null');
      }
      return leftFn(value);
    } else {
      // right getter kullanarak değeri al (void için null handle edilir)
      return rightFn(right);
    }
  }
}

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

