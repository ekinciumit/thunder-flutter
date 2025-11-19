import '../../../../core/errors/failures.dart';
import '../../../../models/user_model.dart';

/// Authentication Repository Interface
/// 
/// Bu interface SOLID prensiplerinden Dependency Inversion Principle'a uyar:
/// - Domain katmanı data katmanına bağımlı değil
/// - Abstract interface kullanır
/// - Either pattern kullanır (Clean Architecture standart)

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

