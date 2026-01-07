import '../../../../core/errors/failures.dart';
import '../repositories/event_repository.dart';

/// Cancel Event Use Case
/// 
/// Clean Architecture Domain Layer
/// Event iptal etme iş kuralını içerir.
class CancelEventUseCase {
  final EventRepository _repository;

  CancelEventUseCase(this._repository);

  /// Event'i iptal et
  /// 
  /// Returns: ``Either<Failure, void>``
  Future<Either<Failure, void>> call(String eventId, String cancellationReason) async {
    // Business logic: Validation
    if (eventId.isEmpty) {
      return Either.left(ValidationFailure('Etkinlik ID boş olamaz'));
    }
    if (cancellationReason.trim().isEmpty) {
      return Either.left(ValidationFailure('İptal sebebi boş olamaz'));
    }

    return await _repository.cancelEvent(eventId, cancellationReason.trim());
  }
}

