import '../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

/// Sign Out Use Case
/// 
/// Bu Use Case Clean Architecture'ın domain katmanında yer alır ve:
/// - Business logic'i içerir
/// - Repository'yi kullanır (data katmanına bağımlı değil)
/// - Test edilebilir (mock repository ile)

class SignOutUseCase {
  final AuthRepository _repository;

  SignOutUseCase(this._repository);

  /// Çıkış yap
  /// 
  /// Returns: ``Either<Failure, void>``
  Future<Either<Failure, void>> call() async {
    // Business logic: Çıkış yapmadan önce kontrol yapılabilir
    // Şu an direkt repository'yi kullanıyoruz
    
    return await _repository.signOut();
  }
}

