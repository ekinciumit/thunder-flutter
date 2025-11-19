import '../../../../core/errors/failures.dart';
import '../../../../models/event_model.dart';
import '../repositories/event_repository.dart';

/// Update Event Use Case
/// 
/// Clean Architecture Domain Layer
/// Etkinlik güncelleme iş kuralını içerir.
class UpdateEventUseCase {
  final EventRepository _repository;

  UpdateEventUseCase(this._repository);

  /// Etkinlik güncelle
  /// 
  /// Returns: Either<Failure, void>
  Future<Either<Failure, void>> call(EventModel event) async {
    // Business logic: Validation
    if (event.title.isEmpty) {
      return Either.left(ValidationFailure('Etkinlik başlığı boş olamaz'));
    }
    if (event.description.isEmpty) {
      return Either.left(ValidationFailure('Etkinlik açıklaması boş olamaz'));
    }

    return await _repository.updateEvent(event);
  }
}

