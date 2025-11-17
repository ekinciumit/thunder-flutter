import '../../../../models/user_model.dart';
import '../repositories/auth_repository.dart';

/// Get Current User Use Case
/// 
/// Bu Use Case Clean Architecture'ın domain katmanında yer alır ve:
/// - Business logic'i içerir
/// - Repository'yi kullanır (data katmanına bağımlı değil)
/// - Test edilebilir (mock repository ile)

class GetCurrentUserUseCase {
  final AuthRepository _repository;

  GetCurrentUserUseCase(this._repository);

  /// Mevcut kullanıcıyı getir
  /// 
  /// Returns: UserModel if logged in, null otherwise
  /// (Synchronous operation, no Either needed)
  UserModel? call() {
    // Business logic: Mevcut kullanıcıyı getir
    return _repository.getCurrentUser();
  }
}

