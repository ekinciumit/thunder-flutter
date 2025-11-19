import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../models/event_model.dart';
import '../../domain/repositories/event_repository.dart';
import '../datasources/event_remote_data_source.dart';

/// Event Repository Implementation
/// 
/// Clean Architecture Data Layer
/// Domain repository interface'ini implement eder ve
/// Exception'ları Failure'lara çevirir.
class EventRepositoryImpl implements EventRepository {
  final EventRemoteDataSource _remoteDataSource;

  EventRepositoryImpl({
    required EventRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  @override
  Future<Either<Failure, void>> addEvent(EventModel event) async {
    try {
      await _remoteDataSource.addEvent(event);
      return Either.right(null);
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } catch (e) {
      return Either.left(UnknownFailure('Etkinlik eklenirken bir hata oluştu: ${e.toString()}'));
    }
  }

  @override
  Stream<List<EventModel>> getEventsStream() {
    try {
      return _remoteDataSource.getEventsStream();
    } catch (e) {
      // Stream'ler için hata durumunda boş stream döndür
      return Stream.value(<EventModel>[]);
    }
  }

  @override
  Stream<List<EventModel>> getUserEventsStream(String userId) {
    try {
      return _remoteDataSource.getUserEventsStream(userId);
    } catch (e) {
      // Stream'ler için hata durumunda boş stream döndür
      return Stream.value(<EventModel>[]);
    }
  }

  @override
  Future<Either<Failure, List<EventModel>>> fetchNextEvents({
    DateTime? startAfter,
    int limit = 50,
  }) async {
    try {
      final events = await _remoteDataSource.fetchNextEvents(
        startAfter: startAfter,
        limit: limit,
      );
      return Either.right(events);
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } catch (e) {
      return Either.left(UnknownFailure('Etkinlikler getirilirken bir hata oluştu: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> updateEvent(EventModel event) async {
    try {
      await _remoteDataSource.updateEvent(event);
      return Either.right(null);
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } catch (e) {
      return Either.left(UnknownFailure('Etkinlik güncellenirken bir hata oluştu: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteEvent(String eventId) async {
    try {
      await _remoteDataSource.deleteEvent(eventId);
      return Either.right(null);
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } catch (e) {
      return Either.left(UnknownFailure('Etkinlik silinirken bir hata oluştu: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> joinEvent(String eventId, String userId) async {
    try {
      await _remoteDataSource.joinEvent(eventId, userId);
      return Either.right(null);
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } catch (e) {
      return Either.left(UnknownFailure('Etkinliğe katılırken bir hata oluştu: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> leaveEvent(String eventId, String userId) async {
    try {
      await _remoteDataSource.leaveEvent(eventId, userId);
      return Either.right(null);
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } catch (e) {
      return Either.left(UnknownFailure('Etkinlikten ayrılırken bir hata oluştu: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> sendJoinRequest(String eventId, String userId) async {
    try {
      await _remoteDataSource.sendJoinRequest(eventId, userId);
      return Either.right(null);
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } catch (e) {
      return Either.left(UnknownFailure('Katılma isteği gönderilirken bir hata oluştu: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> approveJoinRequest(String eventId, String userId) async {
    try {
      await _remoteDataSource.approveJoinRequest(eventId, userId);
      return Either.right(null);
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } catch (e) {
      return Either.left(UnknownFailure('Katılma isteği onaylanırken bir hata oluştu: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> rejectJoinRequest(String eventId, String userId) async {
    try {
      await _remoteDataSource.rejectJoinRequest(eventId, userId);
      return Either.right(null);
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } catch (e) {
      return Either.left(UnknownFailure('Katılma isteği reddedilirken bir hata oluştu: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> cancelJoinRequest(String eventId, String userId) async {
    try {
      await _remoteDataSource.cancelJoinRequest(eventId, userId);
      return Either.right(null);
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } catch (e) {
      return Either.left(UnknownFailure('Katılma isteği iptal edilirken bir hata oluştu: ${e.toString()}'));
    }
  }
}

/// Factory function for creating EventRepositoryImpl
Future<EventRepository> createEventRepository() async {
  return EventRepositoryImpl(
    remoteDataSource: EventRemoteDataSourceImpl(),
  );
}

