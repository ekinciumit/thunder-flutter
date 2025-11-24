import '../../../../core/errors/failures.dart';
import '../../../../models/event_model.dart';
import '../repositories/event_repository.dart';

/// Add Event Use Case
/// 
/// Clean Architecture Domain Layer
/// Etkinlik ekleme iş kuralını içerir.
class AddEventUseCase {
  final EventRepository _repository;

  AddEventUseCase(this._repository);

  /// Etkinlik ekle
  /// 
  /// Returns: ``Either<Failure, void>``
  Future<Either<Failure, void>> call(EventModel event) async {
    // Business logic: Validation
    if (event.title.isEmpty) {
      return Either.left(ValidationFailure('Etkinlik başlığı boş olamaz'));
    }
    if (event.description.isEmpty) {
      return Either.left(ValidationFailure('Etkinlik açıklaması boş olamaz'));
    }
    if (event.quota <= 0) {
      return Either.left(ValidationFailure('Kota 0\'dan büyük olmalıdır'));
    }

    return await _repository.addEvent(event);
  }
}

