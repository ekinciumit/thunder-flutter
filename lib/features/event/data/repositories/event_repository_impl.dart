import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/repositories/event_repository.dart';
import '../../domain/entities/event_entity.dart';
import '../mappers/event_mapper.dart';
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
  Future<Either<Failure, void>> addEvent(EventEntity event) async {
    try {
      // Entity -> DTO dönüşümü
      final eventModel = EventMapper.toModel(event);
      await _remoteDataSource.addEvent(eventModel);
      return Either.right(null);
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } catch (e) {
      return Either.left(UnknownFailure('Etkinlik eklenirken bir hata oluştu: ${e.toString()}'));
    }
  }

  @override
  Stream<List<EventEntity>> getEventsStream() {
    try {
      // DTO stream'i -> Entity stream'e çevir
      return _remoteDataSource.getEventsStream().map((eventModels) {
        return EventMapper.toEntityList(eventModels);
      });
    } catch (e) {
      // Stream'ler için hata durumunda boş stream döndür
      // Ama hatayı logla
      if (kDebugMode) {
        debugPrint('❌ [EVENT_REPO] getEventsStream hatası: $e');
      }
      return Stream.value(<EventEntity>[]);
    }
  }

  @override
  Stream<List<EventEntity>> getUserEventsStream(String userId) {
    try {
      // DTO stream'i -> Entity stream'e çevir
      return _remoteDataSource.getUserEventsStream(userId).map((eventModels) {
        return EventMapper.toEntityList(eventModels);
      });
    } catch (e) {
      // Stream'ler için hata durumunda boş stream döndür
      return Stream.value(<EventEntity>[]);
    }
  }

  @override
  Future<Either<Failure, List<EventEntity>>> fetchNextEvents({
    DateTime? startAfter,
    int limit = 50,
  }) async {
    try {
      final eventModels = await _remoteDataSource.fetchNextEvents(
        startAfter: startAfter,
        limit: limit,
      );
      // DTO -> Entity dönüşümü
      return Either.right(EventMapper.toEntityList(eventModels));
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } catch (e) {
      return Either.left(UnknownFailure('Etkinlikler getirilirken bir hata oluştu: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> updateEvent(EventEntity event) async {
    try {
      // Entity -> DTO dönüşümü
      final eventModel = EventMapper.toModel(event);
      await _remoteDataSource.updateEvent(eventModel);
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

  @override
  Future<Either<Failure, void>> removeParticipant(String eventId, String userId) async {
    try {
      await _remoteDataSource.removeParticipant(eventId, userId);
      return Either.right(null);
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } catch (e) {
      return Either.left(UnknownFailure('Katılımcı çıkarılırken bir hata oluştu: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> cancelEvent(String eventId, String cancellationReason) async {
    try {
      await _remoteDataSource.cancelEvent(eventId, cancellationReason);
      return Either.right(null);
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } catch (e) {
      return Either.left(UnknownFailure('Etkinlik iptal edilirken bir hata oluştu: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, String>> uploadEventCoverPhoto(String photoFilePath, {String? eventId}) async {
    try {
      final file = File(photoFilePath);
      final url = await _remoteDataSource.uploadEventCoverPhoto(file, eventId: eventId);
      return Either.right(url);
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } catch (e) {
      return Either.left(UnknownFailure('Event cover fotoğrafı yüklenirken bir hata oluştu: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, String>> uploadEventPhoto(String photoFilePath, String eventId) async {
    try {
      final file = File(photoFilePath);
      final url = await _remoteDataSource.uploadEventPhoto(file, eventId);
      return Either.right(url);
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } catch (e) {
      return Either.left(UnknownFailure('Event fotoğrafı yüklenirken bir hata oluştu: ${e.toString()}'));
    }
  }

  @override
  Stream<EventEntity?> getEventStream(String eventId) {
    try {
      // DTO stream'i -> Entity stream'e çevir
      return _remoteDataSource.getEventStream(eventId).map((eventModel) {
        return eventModel != null ? EventMapper.toEntity(eventModel) : null;
      });
    } catch (e) {
      // Stream'ler için hata durumunda boş stream döndür
      return Stream.value(null);
    }
  }

  @override
  Stream<List<Map<String, dynamic>>> getEventCommentsStream(String eventId) {
    try {
      return _remoteDataSource.getEventCommentsStream(eventId);
    } catch (e) {
      // Stream'ler için hata durumunda boş stream döndür
      return Stream.value(<Map<String, dynamic>>[]);
    }
  }

  @override
  Future<Either<Failure, void>> addEventComment(String eventId, String text, String userId, String userName) async {
    try {
      await _remoteDataSource.addEventComment(eventId, text, userId, userName);
      return Either.right(null);
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } catch (e) {
      return Either.left(UnknownFailure('Yorum eklenirken bir hata oluştu: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteEventComments(String eventId) async {
    try {
      await _remoteDataSource.deleteEventComments(eventId);
      return Either.right(null);
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } catch (e) {
      // Comments silme hatası kritik değil, sessizce devam et
      return Either.right(null);
    }
  }
}

/// Factory function for creating EventRepositoryImpl
Future<EventRepository> createEventRepository() async {
  return EventRepositoryImpl(
    remoteDataSource: EventRemoteDataSourceImpl(),
  );
}

