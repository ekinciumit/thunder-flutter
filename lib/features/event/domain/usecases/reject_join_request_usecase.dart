import '../../../../core/errors/failures.dart';
import '../repositories/event_repository.dart';

/// Reject Join Request Use Case
/// 
/// Clean Architecture Domain Layer
/// Katılma isteğini reddetme iş kuralını içerir.
class RejectJoinRequestUseCase {
  final EventRepository _repository;

  RejectJoinRequestUseCase(this._repository);

  /// Katılma isteğini reddet
  /// 
  /// Returns: ``Either<Failure, void>``
  Future<Either<Failure, void>> call(String eventId, String userId) async {
    // Business logic: Validation
    if (eventId.isEmpty || userId.isEmpty) {
      return Either.left(ValidationFailure('Etkinlik ID ve kullanıcı ID boş olamaz'));
    }

    return await _repository.rejectJoinRequest(eventId, userId);
  }
}

