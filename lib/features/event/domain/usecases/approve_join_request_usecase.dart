import '../../../../core/errors/failures.dart';
import '../repositories/event_repository.dart';

/// Approve Join Request Use Case
/// 
/// Clean Architecture Domain Layer
/// Katılma isteğini onaylama iş kuralını içerir.
class ApproveJoinRequestUseCase {
  final EventRepository _repository;

  ApproveJoinRequestUseCase(this._repository);

  /// Katılma isteğini onayla
  /// 
  /// Returns: ``Either<Failure, void>``
  Future<Either<Failure, void>> call(String eventId, String userId) async {
    // Business logic: Validation
    if (eventId.isEmpty || userId.isEmpty) {
      return Either.left(ValidationFailure('Etkinlik ID ve kullanıcı ID boş olamaz'));
    }

    return await _repository.approveJoinRequest(eventId, userId);
  }
}

