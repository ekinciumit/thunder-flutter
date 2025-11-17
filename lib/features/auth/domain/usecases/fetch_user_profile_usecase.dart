import '../../../../core/errors/failures.dart';
import '../../../../models/user_model.dart';
import '../repositories/auth_repository.dart';

/// Fetch User Profile Use Case
/// 
/// Bu Use Case Clean Architecture'ın domain katmanında yer alır ve:
/// - Business logic'i içerir
/// - Repository'yi kullanır (data katmanına bağımlı değil)
/// - Test edilebilir (mock repository ile)

class FetchUserProfileUseCase {
  final AuthRepository _repository;

  FetchUserProfileUseCase(this._repository);

  /// Kullanıcı profilini getir
  /// 
  /// Returns: Either<Failure, UserModel?>
  /// - Left: Failure if fetch fails
  /// - Right: UserModel if found, null otherwise
  Future<Either<Failure, UserModel?>> call(String uid) async {
    // Business logic: UID validation
    if (uid.isEmpty) {
      return Either.left(ValidationFailure('Kullanıcı ID boş olamaz'));
    }

    // Repository'yi kullan
    return await _repository.fetchUserProfile(uid);
  }
}

