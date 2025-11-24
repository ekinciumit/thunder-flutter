import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:thunder/features/event/data/repositories/event_repository_impl.dart';
import 'package:thunder/features/event/data/datasources/event_remote_data_source.dart';
import 'package:thunder/models/event_model.dart';
import 'package:thunder/core/errors/exceptions.dart';
import 'package:thunder/core/errors/failures.dart';

import 'event_repository_impl_test.mocks.dart';

/// Mock classes için annotation
@GenerateMocks([EventRemoteDataSource])
void main() {
  late EventRepositoryImpl repository;
  late MockEventRemoteDataSource mockRemoteDataSource;

  setUp(() {
    mockRemoteDataSource = MockEventRemoteDataSource();
    repository = EventRepositoryImpl(remoteDataSource: mockRemoteDataSource);
  });

  group('EventRepositoryImpl', () {
    final testEvent = EventModel(
      id: 'event-123',
      title: 'Test Event',
      description: 'Test Description',
      location: const GeoPoint(41.0082, 28.9784),
      address: 'Test Address',
      datetime: DateTime.now().add(const Duration(days: 1)),
      quota: 10,
      createdBy: 'user-123',
      participants: [],
    );

    group('addEvent', () {
      test('should return Right(void) when event is added successfully', () async {
        // Arrange
        when(mockRemoteDataSource.addEvent(testEvent))
            .thenAnswer((_) async => Future.value());

        // Act
        final result = await repository.addEvent(testEvent);

        // Assert
        expect(result.isRight, true);
        expect(result.isLeft, false);
        verify(mockRemoteDataSource.addEvent(testEvent)).called(1);
      });

      test('should return Left(ServerFailure) when ServerException is thrown', () async {
        // Arrange
        when(mockRemoteDataSource.addEvent(testEvent))
            .thenThrow(ServerException('Server error'));

        // Act
        final result = await repository.addEvent(testEvent);

        // Assert
        expect(result.isLeft, true);
        expect(result.left, isA<ServerFailure>());
        expect(result.left.message, 'Server error');
        verify(mockRemoteDataSource.addEvent(testEvent)).called(1);
      });

      test('should return Left(UnknownFailure) when unknown exception is thrown', () async {
        // Arrange
        when(mockRemoteDataSource.addEvent(testEvent))
            .thenThrow(Exception('Unknown error'));

        // Act
        final result = await repository.addEvent(testEvent);

        // Assert
        expect(result.isLeft, true);
        expect(result.left, isA<UnknownFailure>());
        expect(result.left.message, contains('Etkinlik eklenirken bir hata oluştu'));
        verify(mockRemoteDataSource.addEvent(testEvent)).called(1);
      });
    });

    group('getEventsStream', () {
      test('should return stream of events when successful', () async {
        // Arrange
        final testEvents = [testEvent];
        when(mockRemoteDataSource.getEventsStream())
            .thenAnswer((_) => Stream.value(testEvents));

        // Act
        final stream = repository.getEventsStream();

        // Assert
        expect(stream, isA<Stream<List<EventModel>>>());
        final result = await stream.first;
        expect(result, testEvents);
        verify(mockRemoteDataSource.getEventsStream()).called(1);
      });

      test('should return empty stream when exception is thrown', () async {
        // Arrange
        when(mockRemoteDataSource.getEventsStream())
            .thenThrow(Exception('Error'));

        // Act
        final stream = repository.getEventsStream();

        // Assert
        final result = await stream.first;
        expect(result, isEmpty);
        verify(mockRemoteDataSource.getEventsStream()).called(1);
      });
    });

    group('updateEvent', () {
      test('should return Right(void) when event is updated successfully', () async {
        // Arrange
        when(mockRemoteDataSource.updateEvent(testEvent))
            .thenAnswer((_) async => Future.value());

        // Act
        final result = await repository.updateEvent(testEvent);

        // Assert
        expect(result.isRight, true);
        verify(mockRemoteDataSource.updateEvent(testEvent)).called(1);
      });

      test('should return Left(ServerFailure) when ServerException is thrown', () async {
        // Arrange
        when(mockRemoteDataSource.updateEvent(testEvent))
            .thenThrow(ServerException('Update failed'));

        // Act
        final result = await repository.updateEvent(testEvent);

        // Assert
        expect(result.isLeft, true);
        expect(result.left, isA<ServerFailure>());
        expect(result.left.message, 'Update failed');
      });
    });

    group('deleteEvent', () {
      const testEventId = 'event-123';

      test('should return Right(void) when event is deleted successfully', () async {
        // Arrange
        when(mockRemoteDataSource.deleteEvent(testEventId))
            .thenAnswer((_) async => Future.value());

        // Act
        final result = await repository.deleteEvent(testEventId);

        // Assert
        expect(result.isRight, true);
        verify(mockRemoteDataSource.deleteEvent(testEventId)).called(1);
      });

      test('should return Left(ServerFailure) when ServerException is thrown', () async {
        // Arrange
        when(mockRemoteDataSource.deleteEvent(testEventId))
            .thenThrow(ServerException('Delete failed'));

        // Act
        final result = await repository.deleteEvent(testEventId);

        // Assert
        expect(result.isLeft, true);
        expect(result.left, isA<ServerFailure>());
        expect(result.left.message, 'Delete failed');
      });
    });

    group('joinEvent', () {
      const testEventId = 'event-123';
      const testUserId = 'user-123';

      test('should return Right(void) when join is successful', () async {
        // Arrange
        when(mockRemoteDataSource.joinEvent(testEventId, testUserId))
            .thenAnswer((_) async => Future.value());

        // Act
        final result = await repository.joinEvent(testEventId, testUserId);

        // Assert
        expect(result.isRight, true);
        verify(mockRemoteDataSource.joinEvent(testEventId, testUserId)).called(1);
      });

      test('should return Left(ServerFailure) when ServerException is thrown', () async {
        // Arrange
        when(mockRemoteDataSource.joinEvent(testEventId, testUserId))
            .thenThrow(ServerException('Join failed'));

        // Act
        final result = await repository.joinEvent(testEventId, testUserId);

        // Assert
        expect(result.isLeft, true);
        expect(result.left, isA<ServerFailure>());
        expect(result.left.message, 'Join failed');
      });
    });

    group('leaveEvent', () {
      const testEventId = 'event-123';
      const testUserId = 'user-123';

      test('should return Right(void) when leave is successful', () async {
        // Arrange
        when(mockRemoteDataSource.leaveEvent(testEventId, testUserId))
            .thenAnswer((_) async => Future.value());

        // Act
        final result = await repository.leaveEvent(testEventId, testUserId);

        // Assert
        expect(result.isRight, true);
        verify(mockRemoteDataSource.leaveEvent(testEventId, testUserId)).called(1);
      });

      test('should return Left(ServerFailure) when ServerException is thrown', () async {
        // Arrange
        when(mockRemoteDataSource.leaveEvent(testEventId, testUserId))
            .thenThrow(ServerException('Leave failed'));

        // Act
        final result = await repository.leaveEvent(testEventId, testUserId);

        // Assert
        expect(result.isLeft, true);
        expect(result.left, isA<ServerFailure>());
        expect(result.left.message, 'Leave failed');
      });
    });

    group('sendJoinRequest', () {
      const testEventId = 'event-123';
      const testUserId = 'user-123';

      test('should return Right(void) when request is sent successfully', () async {
        // Arrange
        when(mockRemoteDataSource.sendJoinRequest(testEventId, testUserId))
            .thenAnswer((_) async => Future.value());

        // Act
        final result = await repository.sendJoinRequest(testEventId, testUserId);

        // Assert
        expect(result.isRight, true);
        verify(mockRemoteDataSource.sendJoinRequest(testEventId, testUserId)).called(1);
      });

      test('should return Left(ServerFailure) when ServerException is thrown', () async {
        // Arrange
        when(mockRemoteDataSource.sendJoinRequest(testEventId, testUserId))
            .thenThrow(ServerException('Send request failed'));

        // Act
        final result = await repository.sendJoinRequest(testEventId, testUserId);

        // Assert
        expect(result.isLeft, true);
        expect(result.left, isA<ServerFailure>());
        expect(result.left.message, 'Send request failed');
      });
    });

    group('approveJoinRequest', () {
      const testEventId = 'event-123';
      const testUserId = 'user-123';

      test('should return Right(void) when approval is successful', () async {
        // Arrange
        when(mockRemoteDataSource.approveJoinRequest(testEventId, testUserId))
            .thenAnswer((_) async => Future.value());

        // Act
        final result = await repository.approveJoinRequest(testEventId, testUserId);

        // Assert
        expect(result.isRight, true);
        verify(mockRemoteDataSource.approveJoinRequest(testEventId, testUserId)).called(1);
      });

      test('should return Left(ServerFailure) when ServerException is thrown', () async {
        // Arrange
        when(mockRemoteDataSource.approveJoinRequest(testEventId, testUserId))
            .thenThrow(ServerException('Approve failed'));

        // Act
        final result = await repository.approveJoinRequest(testEventId, testUserId);

        // Assert
        expect(result.isLeft, true);
        expect(result.left, isA<ServerFailure>());
        expect(result.left.message, 'Approve failed');
      });
    });

    group('rejectJoinRequest', () {
      const testEventId = 'event-123';
      const testUserId = 'user-123';

      test('should return Right(void) when rejection is successful', () async {
        // Arrange
        when(mockRemoteDataSource.rejectJoinRequest(testEventId, testUserId))
            .thenAnswer((_) async => Future.value());

        // Act
        final result = await repository.rejectJoinRequest(testEventId, testUserId);

        // Assert
        expect(result.isRight, true);
        verify(mockRemoteDataSource.rejectJoinRequest(testEventId, testUserId)).called(1);
      });

      test('should return Left(ServerFailure) when ServerException is thrown', () async {
        // Arrange
        when(mockRemoteDataSource.rejectJoinRequest(testEventId, testUserId))
            .thenThrow(ServerException('Reject failed'));

        // Act
        final result = await repository.rejectJoinRequest(testEventId, testUserId);

        // Assert
        expect(result.isLeft, true);
        expect(result.left, isA<ServerFailure>());
        expect(result.left.message, 'Reject failed');
      });
    });

    group('cancelJoinRequest', () {
      const testEventId = 'event-123';
      const testUserId = 'user-123';

      test('should return Right(void) when cancellation is successful', () async {
        // Arrange
        when(mockRemoteDataSource.cancelJoinRequest(testEventId, testUserId))
            .thenAnswer((_) async => Future.value());

        // Act
        final result = await repository.cancelJoinRequest(testEventId, testUserId);

        // Assert
        expect(result.isRight, true);
        verify(mockRemoteDataSource.cancelJoinRequest(testEventId, testUserId)).called(1);
      });

      test('should return Left(ServerFailure) when ServerException is thrown', () async {
        // Arrange
        when(mockRemoteDataSource.cancelJoinRequest(testEventId, testUserId))
            .thenThrow(ServerException('Cancel failed'));

        // Act
        final result = await repository.cancelJoinRequest(testEventId, testUserId);

        // Assert
        expect(result.isLeft, true);
        expect(result.left, isA<ServerFailure>());
        expect(result.left.message, 'Cancel failed');
      });
    });

    group('fetchNextEvents', () {
      final testEvents = [testEvent];

      test('should return Right(List<EventModel>) when fetch is successful', () async {
        // Arrange
        when(mockRemoteDataSource.fetchNextEvents(
          startAfter: anyNamed('startAfter'),
          limit: anyNamed('limit'),
        )).thenAnswer((_) async => testEvents);

        // Act
        final result = await repository.fetchNextEvents(limit: 50);

        // Assert
        expect(result.isRight, true);
        expect(result.right, testEvents);
        verify(mockRemoteDataSource.fetchNextEvents(
          startAfter: anyNamed('startAfter'),
          limit: 50,
        )).called(1);
      });

      test('should return Left(ServerFailure) when ServerException is thrown', () async {
        // Arrange
        when(mockRemoteDataSource.fetchNextEvents(
          startAfter: anyNamed('startAfter'),
          limit: anyNamed('limit'),
        )).thenThrow(ServerException('Fetch failed'));

        // Act
        final result = await repository.fetchNextEvents();

        // Assert
        expect(result.isLeft, true);
        expect(result.left, isA<ServerFailure>());
        expect(result.left.message, 'Fetch failed');
      });
    });

    group('getUserEventsStream', () {
      const testUserId = 'user-123';
      final testEvents = [testEvent];

      test('should return stream of user events when successful', () async {
        // Arrange
        when(mockRemoteDataSource.getUserEventsStream(testUserId))
            .thenAnswer((_) => Stream.value(testEvents));

        // Act
        final stream = repository.getUserEventsStream(testUserId);

        // Assert
        expect(stream, isA<Stream<List<EventModel>>>());
        final result = await stream.first;
        expect(result, testEvents);
        verify(mockRemoteDataSource.getUserEventsStream(testUserId)).called(1);
      });

      test('should return empty stream when exception is thrown', () async {
        // Arrange
        when(mockRemoteDataSource.getUserEventsStream(testUserId))
            .thenThrow(Exception('Error'));

        // Act
        final stream = repository.getUserEventsStream(testUserId);

        // Assert
        final result = await stream.first;
        expect(result, isEmpty);
        verify(mockRemoteDataSource.getUserEventsStream(testUserId)).called(1);
      });
    });
  });
}

