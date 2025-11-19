import '../../../../core/errors/failures.dart';
import '../repositories/event_repository.dart';

/// Leave Event Use Case
/// 
/// Clean Architecture Domain Layer
/// Etkinlikten ayrılma iş kuralını içerir.
class LeaveEventUseCase {
  final EventRepository _repository;

  LeaveEventUseCase(this._repository);

  /// Etkinlikten ayrıl
  /// 
  /// Returns: Either<Failure, void>
  Future<Either<Failure, void>> call(String eventId, String userId) async {
    // Business logic: Validation
    if (eventId.isEmpty || userId.isEmpty) {
      return Either.left(ValidationFailure('Etkinlik ID ve kullanıcı ID boş olamaz'));
    }

    return await _repository.leaveEvent(eventId, userId);
  }
}

