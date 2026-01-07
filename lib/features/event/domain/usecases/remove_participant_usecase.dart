import '../../../../core/errors/failures.dart';
import '../repositories/event_repository.dart';

/// Remove Participant Use Case
/// 
/// Clean Architecture Domain Layer
/// Event sahibi tarafından katılımcı çıkarma iş kuralını içerir.
class RemoveParticipantUseCase {
  final EventRepository _repository;

  RemoveParticipantUseCase(this._repository);

  /// Katılımcıyı çıkar
  /// 
  /// Returns: ``Either<Failure, void>``
  Future<Either<Failure, void>> call(String eventId, String userId) async {
    // Business logic: Validation
    if (eventId.isEmpty) {
      return Either.left(ValidationFailure('Etkinlik ID boş olamaz'));
    }
    if (userId.isEmpty) {
      return Either.left(ValidationFailure('Kullanıcı ID boş olamaz'));
    }

    return await _repository.removeParticipant(eventId, userId);
  }
}

