import '../../../../core/errors/failures.dart';
import '../../../../models/user_model.dart';

/// Authentication Repository Interface
/// 
/// Bu interface SOLID prensiplerinden Dependency Inversion Principle'a uyar:
/// - Domain katmanı data katmanına bağımlı değil
/// - Abstract interface kullanır
/// - Either pattern kullanır (Clean Architecture standart)
/// 
/// ŞU AN: Bu interface sadece ekleniyor, mevcut kod çalışmaya devam ediyor
/// İleride bu repository'yi kullanacağız

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

  bool get isLeft => _isLeft;
  bool get isRight => !_isLeft;

  L get left {
    if (!_isLeft || _left == null) {
      throw StateError('Either is Right, not Left');
    }
    // Null check yapıldığı için analyzer'a göre ! gereksiz ama tip güvenliği için gerekli
    // ignore: unnecessary_non_null_assertion
    return _left!;
  }
  
  R get right {
    if (_isLeft || _right == null) {
      throw StateError('Either is Left, not Right');
    }
    // Null check yapıldığı için analyzer'a göre ! gereksiz ama tip güvenliği için gerekli
    // ignore: unnecessary_non_null_assertion
    return _right!;
  }

  /// Either'i düz bir değere çevirir
  /// 
  /// onLeft: Left durumunda ne yapılacak
  /// onRight: Right durumunda ne yapılacak
  /// Returns: Her iki durumda da aynı tip döner
  T fold<T>(T Function(L) onLeft, T Function(R) onRight) {
    if (_isLeft) {
      // Null check yapıldığı için analyzer'a göre ! gereksiz ama tip güvenliği için gerekli
      // ignore: unnecessary_non_null_assertion
      return onLeft(_left!);
    } else {
      // Null check yapıldığı için analyzer'a göre ! gereksiz ama tip güvenliği için gerekli
      // ignore: unnecessary_non_null_assertion
      return onRight(_right!);
    }
  }
}

abstract class AuthRepository {
  /// Email/password ile giriş yap
  /// 
  /// Returns: Either with Failure (Left) or UserModel (Right)
  Future<Either<Failure, UserModel>> signIn(String email, String password);
  
  /// Email/password ile kayıt ol
  /// 
  /// Returns: Either with Failure (Left) or UserModel (Right)
  Future<Either<Failure, UserModel>> signUp(String email, String password);
  
  /// Çıkış yap
  /// 
  /// Returns: Either with Failure (Left) or void (Right)
  Future<Either<Failure, void>> signOut();
  
  /// Kullanıcı profilini kaydet
  /// 
  /// Returns: Either with Failure (Left) or void (Right)
  Future<Either<Failure, void>> saveUserProfile(UserModel user);
  
  /// Kullanıcı profilini getir
  /// 
  /// Returns: Either with Failure (Left) or UserModel? (Right)
  Future<Either<Failure, UserModel?>> fetchUserProfile(String uid);
  
  /// FCM token'ını kaydet
  /// 
  /// Returns: Either with Failure (Left) or void (Right)
  Future<Either<Failure, void>> saveUserToken(String token);
  
  /// Mevcut kullanıcıyı getir
  /// 
  /// Returns: UserModel if logged in, null otherwise
  /// (Synchronous operation, no Either needed)
  UserModel? getCurrentUser();
}

