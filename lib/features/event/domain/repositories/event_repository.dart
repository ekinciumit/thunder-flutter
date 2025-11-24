import '../../../../core/errors/failures.dart';
import '../../../../models/event_model.dart';

/// Event Repository Interface
/// 
/// Clean Architecture Domain Layer
/// Bu interface event işlemleri için abstract tanımlar içerir.
abstract class EventRepository {
  /// Etkinlik ekle
  Future<Either<Failure, void>> addEvent(EventModel event);
  
  /// Etkinlikleri stream olarak getir
  Stream<List<EventModel>> getEventsStream();
  
  /// Kullanıcının etkinliklerini stream olarak getir
  Stream<List<EventModel>> getUserEventsStream(String userId);
  
  /// Daha fazla etkinlik getir (pagination)
  Future<Either<Failure, List<EventModel>>> fetchNextEvents({
    DateTime? startAfter,
    int limit = 50,
  });
  
  /// Etkinlik güncelle
  Future<Either<Failure, void>> updateEvent(EventModel event);
  
  /// Etkinlik sil
  Future<Either<Failure, void>> deleteEvent(String eventId);
  
  /// Etkinliğe katıl
  Future<Either<Failure, void>> joinEvent(String eventId, String userId);
  
  /// Etkinlikten ayrıl
  Future<Either<Failure, void>> leaveEvent(String eventId, String userId);
  
  /// Katılma isteği gönder
  Future<Either<Failure, void>> sendJoinRequest(String eventId, String userId);
  
  /// Katılma isteğini onayla
  Future<Either<Failure, void>> approveJoinRequest(String eventId, String userId);
  
  /// Katılma isteğini reddet
  Future<Either<Failure, void>> rejectJoinRequest(String eventId, String userId);
  
  /// Katılma isteğini iptal et
  Future<Either<Failure, void>> cancelJoinRequest(String eventId, String userId);
}

