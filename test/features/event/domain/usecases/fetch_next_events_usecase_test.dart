import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:thunder/features/event/domain/usecases/fetch_next_events_usecase.dart';
import 'package:thunder/features/event/domain/repositories/event_repository.dart';
import 'package:thunder/models/event_model.dart';
import 'package:thunder/core/errors/failures.dart';

import 'fetch_next_events_usecase_test.mocks.dart';

/// Mock classes için annotation
@GenerateMocks([EventRepository])
void main() {
  late FetchNextEventsUseCase useCase;
  late MockEventRepository mockRepository;

  setUp(() {
    mockRepository = MockEventRepository();
    useCase = FetchNextEventsUseCase(mockRepository);
  });

  group('FetchNextEventsUseCase', () {
    final testEvents = [
      EventModel(
        id: 'event-1',
        title: 'Event 1',
        description: 'Description 1',
        location: const GeoPoint(41.0082, 28.9784),
        address: 'Address 1',
        datetime: DateTime.now().add(const Duration(days: 1)),
        quota: 10,
        createdBy: 'user-1',
        participants: [],
      ),
      EventModel(
        id: 'event-2',
        title: 'Event 2',
        description: 'Description 2',
        location: const GeoPoint(41.0082, 28.9784),
        address: 'Address 2',
        datetime: DateTime.now().add(const Duration(days: 2)),
        quota: 20,
        createdBy: 'user-2',
        participants: [],
      ),
    ];

    test('should return Right(List<EventModel>) when fetch is successful', () async {
      // Arrange
      when(mockRepository.fetchNextEvents(startAfter: anyNamed('startAfter'), limit: anyNamed('limit')))
          .thenAnswer((_) async => Either.right(testEvents));

      // Act
      final result = await useCase.call(limit: 50);

      // Assert
      expect(result.isRight, true);
      expect(result.isLeft, false);
      expect(result.right, testEvents);
      verify(mockRepository.fetchNextEvents(startAfter: anyNamed('startAfter'), limit: 50)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return Left(ValidationFailure) when limit is zero', () async {
      // Act
      final result = await useCase.call(limit: 0);

      // Assert
      expect(result.isLeft, true);
      expect(result.left, isA<ValidationFailure>());
      expect(result.left.message, 'Limit 0\'dan büyük olmalıdır');
      verifyNever(mockRepository.fetchNextEvents(startAfter: anyNamed('startAfter'), limit: anyNamed('limit')));
    });

    test('should return Left(ValidationFailure) when limit is negative', () async {
      // Act
      final result = await useCase.call(limit: -5);

      // Assert
      expect(result.isLeft, true);
      expect(result.left, isA<ValidationFailure>());
      expect(result.left.message, 'Limit 0\'dan büyük olmalıdır');
      verifyNever(mockRepository.fetchNextEvents(startAfter: anyNamed('startAfter'), limit: anyNamed('limit')));
    });

    test('should return Left(ValidationFailure) when limit is greater than 100', () async {
      // Act
      final result = await useCase.call(limit: 101);

      // Assert
      expect(result.isLeft, true);
      expect(result.left, isA<ValidationFailure>());
      expect(result.left.message, 'Limit 100\'den küçük olmalıdır');
      verifyNever(mockRepository.fetchNextEvents(startAfter: anyNamed('startAfter'), limit: anyNamed('limit')));
    });

    test('should return Right(List<EventModel>) when limit is exactly 100', () async {
      // Arrange
      when(mockRepository.fetchNextEvents(startAfter: anyNamed('startAfter'), limit: anyNamed('limit')))
          .thenAnswer((_) async => Either.right(testEvents));

      // Act
      final result = await useCase.call(limit: 100);

      // Assert
      expect(result.isRight, true);
      expect(result.right, testEvents);
      verify(mockRepository.fetchNextEvents(startAfter: anyNamed('startAfter'), limit: 100)).called(1);
    });

    test('should pass startAfter parameter to repository', () async {
      // Arrange
      final startAfter = DateTime.now();
      when(mockRepository.fetchNextEvents(startAfter: anyNamed('startAfter'), limit: anyNamed('limit')))
          .thenAnswer((_) async => Either.right(testEvents));

      // Act
      final result = await useCase.call(startAfter: startAfter, limit: 50);

      // Assert
      expect(result.isRight, true);
      verify(mockRepository.fetchNextEvents(startAfter: startAfter, limit: 50)).called(1);
    });

    test('should return Left(ServerFailure) when repository returns failure', () async {
      // Arrange
      final failure = ServerFailure('Fetch next events failed');
      when(mockRepository.fetchNextEvents(startAfter: anyNamed('startAfter'), limit: anyNamed('limit')))
          .thenAnswer((_) async => Either.left(failure));

      // Act
      final result = await useCase.call(limit: 50);

      // Assert
      expect(result.isLeft, true);
      expect(result.isRight, false);
      expect(result.left, isA<ServerFailure>());
      expect(result.left.message, 'Fetch next events failed');
      verify(mockRepository.fetchNextEvents(startAfter: anyNamed('startAfter'), limit: 50)).called(1);
    });
  });
}

