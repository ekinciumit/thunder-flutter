import '../../../../core/errors/failures.dart';
import '../../../../models/user_model.dart';
import '../repositories/auth_repository.dart';

/// Sign In Use Case
/// 
/// Bu Use Case Clean Architecture'ın domain katmanında yer alır ve:
/// - Business logic'i içerir
/// - Repository'yi kullanır (data katmanına bağımlı değil)
/// - Test edilebilir (mock repository ile)
/// 
/// ŞU AN: Bu Use Case sadece ekleniyor, mevcut kod çalışmaya devam ediyor
/// İleride ViewModel'de kullanacağız

class SignInUseCase {
  final AuthRepository _repository;

  SignInUseCase(this._repository);

  /// Email/password ile giriş yap
  /// 
  /// Returns: Either<Failure, UserModel>
  /// - Left: Failure if authentication fails
  /// - Right: UserModel if successful
  Future<Either<Failure, UserModel>> call(String email, String password) async {
    // Business logic: Email ve password validation
    if (email.isEmpty || password.isEmpty) {
      return Either.left(ValidationFailure('E-posta ve şifre boş olamaz'));
    }

    // Repository'yi kullan
    return await _repository.signIn(email, password);
  }
}

