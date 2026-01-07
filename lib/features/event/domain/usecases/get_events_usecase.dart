import '../entities/event_entity.dart';
import '../repositories/event_repository.dart';

/// Get Events Use Case
/// 
/// Clean Architecture Domain Layer
/// Etkinlikleri stream olarak getirme iş kuralını içerir.
class GetEventsUseCase {
  final EventRepository _repository;

  GetEventsUseCase(this._repository);

  /// Etkinlikleri stream olarak getir
  /// 
  /// Returns: ``Stream<List<EventEntity>>``
  Stream<List<EventEntity>> call() {
    return _repository.getEventsStream();
  }
}

