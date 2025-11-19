import '../../../../core/errors/failures.dart';
import '../repositories/event_repository.dart';

/// Send Join Request Use Case
/// 
/// Clean Architecture Domain Layer
/// Katılma isteği gönderme iş kuralını içerir.
class SendJoinRequestUseCase {
  final EventRepository _repository;

  SendJoinRequestUseCase(this._repository);

  /// Katılma isteği gönder
  /// 
  /// Returns: Either<Failure, void>
  Future<Either<Failure, void>> call(String eventId, String userId) async {
    // Business logic: Validation
    if (eventId.isEmpty || userId.isEmpty) {
      return Either.left(ValidationFailure('Etkinlik ID ve kullanıcı ID boş olamaz'));
    }

    return await _repository.sendJoinRequest(eventId, userId);
  }
}

