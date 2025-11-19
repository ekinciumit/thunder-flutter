import '../../../../core/errors/failures.dart';
import '../../../../models/user_model.dart';
import '../repositories/auth_repository.dart';

/// Save User Profile Use Case
/// 
/// Bu Use Case Clean Architecture'ın domain katmanında yer alır ve:
/// - Business logic'i içerir
/// - Repository'yi kullanır (data katmanına bağımlı değil)
/// - Test edilebilir (mock repository ile)

class SaveUserProfileUseCase {
  final AuthRepository _repository;

  SaveUserProfileUseCase(this._repository);

  /// Kullanıcı profilini kaydet
  /// 
  /// Returns: `Either<Failure, void>`
  Future<Either<Failure, void>> call(UserModel user) async {
    // Business logic: User validation
    if (user.uid.isEmpty) {
      return Either.left(ValidationFailure('Kullanıcı ID boş olamaz'));
    }

    if (user.email.isEmpty) {
      return Either.left(ValidationFailure('E-posta boş olamaz'));
    }

    // Repository'yi kullan
    return await _repository.saveUserProfile(user);
  }
}

