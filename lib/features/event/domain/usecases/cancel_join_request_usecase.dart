import '../../../../core/errors/failures.dart';
import '../repositories/event_repository.dart';

/// Cancel Join Request Use Case
/// 
/// Clean Architecture Domain Layer
/// Katılma isteğini iptal etme iş kuralını içerir.
class CancelJoinRequestUseCase {
  final EventRepository _repository;

  CancelJoinRequestUseCase(this._repository);

  /// Katılma isteğini iptal et
  /// 
  /// Returns: Either<Failure, void>
  Future<Either<Failure, void>> call(String eventId, String userId) async {
    // Business logic: Validation
    if (eventId.isEmpty || userId.isEmpty) {
      return Either.left(ValidationFailure('Etkinlik ID ve kullanıcı ID boş olamaz'));
    }

    return await _repository.cancelJoinRequest(eventId, userId);
  }
}

