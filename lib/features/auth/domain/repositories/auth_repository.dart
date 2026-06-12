import '../../../../core/errors/failures.dart';
import '../../../user/domain/entities/user_entity.dart';

/// Authentication Repository Interface
/// 
/// Bu interface SOLID prensiplerinden Dependency Inversion Principle'a uyar:
/// - Domain katmanı data katmanına bağımlı değil
/// - Abstract interface kullanır
/// - Either pattern kullanır (Clean Architecture standart)

abstract class AuthRepository {
  /// Email/password ile giriş yap
  /// 
  /// Returns: Either with Failure (Left) or UserEntity (Right)
  Future<Either<Failure, UserEntity>> signIn(String email, String password);
  
  /// Email/password ile kayıt ol
  /// 
  /// Returns: Either with Failure (Left) or UserEntity (Right)
  Future<Either<Failure, UserEntity>> signUp(String email, String password);
  
  /// Çıkış yap
  /// 
  /// Returns: Either with Failure (Left) or void (Right)
  Future<Either<Failure, void>> signOut();
  
  /// Kullanıcı profilini kaydet
  /// 
  /// Returns: Either with Failure (Left) or void (Right)
  Future<Either<Failure, void>> saveUserProfile(UserEntity user);
  
  /// Kullanıcı profilini getir
  /// 
  /// Returns: Either with Failure (Left) or UserEntity? (Right)
  Future<Either<Failure, UserEntity?>> fetchUserProfile(String uid);
  
  /// FCM token'ını kaydet
  /// 
  /// Returns: Either with Failure (Left) or void (Right)
  Future<Either<Failure, void>> saveUserToken(String token);
  
  /// Mevcut kullanıcıyı getir
  /// 
  /// Returns: UserEntity if logged in, null otherwise
  /// (Synchronous operation, no Either needed)
  UserEntity? getCurrentUser();
  
  /// Profil fotoğrafını yükler ve download URL'ini döndürür
  Future<Either<Failure, String>> uploadProfilePhoto(String photoFilePath, String userId);
  
  /// Tüm kullanıcıları stream olarak getir
  Stream<List<UserEntity>> getAllUsersStream();

  /// Şifre sıfırlama email'i gönder
  Future<Either<Failure, void>> sendPasswordResetEmail(String email);

  /// Hesabı kalıcı olarak sil
  Future<Either<Failure, void>> deleteAccount({required String password});
}

