import '../../../../core/errors/failures.dart';
import '../../../../models/event_model.dart';
import '../repositories/event_repository.dart';

/// Fetch Next Events Use Case
/// 
/// Clean Architecture Domain Layer
/// Daha fazla etkinlik getirme (pagination) iş kuralını içerir.
class FetchNextEventsUseCase {
  final EventRepository _repository;

  FetchNextEventsUseCase(this._repository);

  /// Daha fazla etkinlik getir
  /// 
  /// Returns: Either<Failure, List<EventModel>>
  Future<Either<Failure, List<EventModel>>> call({
    DateTime? startAfter,
    int limit = 50,
  }) async {
    // Business logic: Validation
    if (limit <= 0) {
      return Either.left(ValidationFailure('Limit 0\'dan büyük olmalıdır'));
    }
    if (limit > 100) {
      return Either.left(ValidationFailure('Limit 100\'den küçük olmalıdır'));
    }

    return await _repository.fetchNextEvents(
      startAfter: startAfter,
      limit: limit,
    );
  }
}

