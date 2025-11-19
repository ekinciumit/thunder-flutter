import '../../../../core/errors/failures.dart';
import '../repositories/event_repository.dart';

/// Join Event Use Case
/// 
/// Clean Architecture Domain Layer
/// Etkinliğe katılma iş kuralını içerir.
class JoinEventUseCase {
  final EventRepository _repository;

  JoinEventUseCase(this._repository);

  /// Etkinliğe katıl
  /// 
  /// Returns: Either<Failure, void>
  Future<Either<Failure, void>> call(String eventId, String userId) async {
    // Business logic: Validation
    if (eventId.isEmpty || userId.isEmpty) {
      return Either.left(ValidationFailure('Etkinlik ID ve kullanıcı ID boş olamaz'));
    }

    return await _repository.joinEvent(eventId, userId);
  }
}

