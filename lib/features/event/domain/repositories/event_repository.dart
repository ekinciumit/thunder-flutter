import '../../../../core/errors/failures.dart';
import '../entities/event_entity.dart';

/// Event Repository Interface
/// 
/// Clean Architecture Domain Layer
/// Bu interface event işlemleri için abstract tanımlar içerir.
abstract class EventRepository {
  /// Etkinlik ekle
  Future<Either<Failure, void>> addEvent(EventEntity event);
  
  /// Etkinlikleri stream olarak getir
  Stream<List<EventEntity>> getEventsStream();
  
  /// Kullanıcının etkinliklerini stream olarak getir
  Stream<List<EventEntity>> getUserEventsStream(String userId);
  
  /// Daha fazla etkinlik getir (pagination)
  Future<Either<Failure, List<EventEntity>>> fetchNextEvents({
    DateTime? startAfter,
    int limit = 50,
  });
  
  /// Etkinlik güncelle
  Future<Either<Failure, void>> updateEvent(EventEntity event);
  
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
  
  /// Katılımcıyı çıkar (sadece event sahibi)
  Future<Either<Failure, void>> removeParticipant(String eventId, String userId);
  
  /// Event'i iptal et (sadece event sahibi)
  Future<Either<Failure, void>> cancelEvent(String eventId, String cancellationReason);
  
  /// Event cover fotoğrafını yükler ve download URL'ini döndürür
  Future<Either<Failure, String>> uploadEventCoverPhoto(String photoFilePath, {String? eventId});
  
  /// Event fotoğrafını yükler ve download URL'ini döndürür
  Future<Either<Failure, String>> uploadEventPhoto(String photoFilePath, String eventId);
  
  /// Tek bir event'i stream olarak getir
  Stream<EventEntity?> getEventStream(String eventId);
  
  /// Event comments stream
  Stream<List<Map<String, dynamic>>> getEventCommentsStream(String eventId);
  
  /// Event comment ekle
  Future<Either<Failure, void>> addEventComment(String eventId, String text, String userId, String userName);
  
  /// Event comments'i sil (event silindiğinde kullanılır)
  Future<Either<Failure, void>> deleteEventComments(String eventId);
}

