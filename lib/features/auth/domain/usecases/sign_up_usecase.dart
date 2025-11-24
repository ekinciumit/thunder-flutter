import '../../../../core/errors/failures.dart';
import '../../../../models/user_model.dart';
import '../repositories/auth_repository.dart';

/// Sign Up Use Case
/// 
/// Bu Use Case Clean Architecture'ın domain katmanında yer alır ve:
/// - Business logic'i içerir
/// - Repository'yi kullanır (data katmanına bağımlı değil)
/// - Test edilebilir (mock repository ile)

class SignUpUseCase {
  final AuthRepository _repository;

  SignUpUseCase(this._repository);

  /// Email/password ile kayıt ol
  /// 
  /// Returns: ``Either<Failure, UserModel>``
  /// - Left: Failure if registration fails
  /// - Right: UserModel if successful
  Future<Either<Failure, UserModel>> call(String email, String password) async {
    // Business logic: Email ve password validation
    if (email.isEmpty || password.isEmpty) {
      return Either.left(ValidationFailure('E-posta ve şifre boş olamaz'));
    }

    if (password.length < 6) {
      return Either.left(ValidationFailure('Şifre en az 6 karakter olmalıdır'));
    }

    // Repository'yi kullan
    return await _repository.signUp(email, password);
  }
}

