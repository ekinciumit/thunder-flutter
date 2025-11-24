import '../../../../core/errors/failures.dart';
import '../repositories/event_repository.dart';

/// Delete Event Use Case
/// 
/// Clean Architecture Domain Layer
/// Etkinlik silme iş kuralını içerir.
class DeleteEventUseCase {
  final EventRepository _repository;

  DeleteEventUseCase(this._repository);

  /// Etkinlik sil
  /// 
  /// Returns: ``Either<Failure, void>``
  Future<Either<Failure, void>> call(String eventId) async {
    // Business logic: Validation
    if (eventId.isEmpty) {
      return Either.left(ValidationFailure('Etkinlik ID boş olamaz'));
    }

    return await _repository.deleteEvent(eventId);
  }
}

