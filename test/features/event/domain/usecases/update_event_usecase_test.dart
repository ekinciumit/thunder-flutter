import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:thunder/features/event/domain/usecases/update_event_usecase.dart';
import 'package:thunder/features/event/domain/repositories/event_repository.dart';
import 'package:thunder/models/event_model.dart';
import 'package:thunder/core/errors/failures.dart';

import 'update_event_usecase_test.mocks.dart';

/// Mock classes için annotation
@GenerateMocks([EventRepository])
void main() {
  late UpdateEventUseCase useCase;
  late MockEventRepository mockRepository;

  setUp(() {
    mockRepository = MockEventRepository();
    useCase = UpdateEventUseCase(mockRepository);
  });

  group('UpdateEventUseCase', () {
    final testEvent = EventModel(
      id: 'event-123',
      title: 'Updated Event',
      description: 'Updated Description',
      location: const GeoPoint(41.0082, 28.9784),
      address: 'Updated Address',
      datetime: DateTime.now().add(const Duration(days: 1)),
      quota: 10,
      createdBy: 'user-123',
      participants: [],
    );

    test('should return Right(void) when event is updated successfully', () async {
      // Arrange
      when(mockRepository.updateEvent(testEvent))
          .thenAnswer((_) async => Either.rightVoid());

      // Act
      final result = await useCase.call(testEvent);

      // Assert
      expect(result.isRight, true);
      expect(result.isLeft, false);
      verify(mockRepository.updateEvent(testEvent)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return Left(ValidationFailure) when title is empty', () async {
      // Arrange
      final invalidEvent = EventModel(
        id: 'event-123',
        title: '', // Boş title
        description: 'Test Description',
        location: const GeoPoint(41.0082, 28.9784),
        address: 'Test Address',
        datetime: DateTime.now().add(const Duration(days: 1)),
        quota: 10,
        createdBy: 'user-123',
        participants: [],
      );

      // Act
      final result = await useCase.call(invalidEvent);

      // Assert
      expect(result.isLeft, true);
      expect(result.left, isA<ValidationFailure>());
      expect(result.left.message, 'Etkinlik başlığı boş olamaz');
      verifyNever(mockRepository.updateEvent(any));
    });

    test('should return Left(ValidationFailure) when description is empty', () async {
      // Arrange
      final invalidEvent = EventModel(
        id: 'event-123',
        title: 'Test Event',
        description: '', // Boş description
        location: const GeoPoint(41.0082, 28.9784),
        address: 'Test Address',
        datetime: DateTime.now().add(const Duration(days: 1)),
        quota: 10,
        createdBy: 'user-123',
        participants: [],
      );

      // Act
      final result = await useCase.call(invalidEvent);

      // Assert
      expect(result.isLeft, true);
      expect(result.left, isA<ValidationFailure>());
      expect(result.left.message, 'Etkinlik açıklaması boş olamaz');
      verifyNever(mockRepository.updateEvent(any));
    });

    test('should return Left(ServerFailure) when repository returns failure', () async {
      // Arrange
      final failure = ServerFailure('Update event failed');
      when(mockRepository.updateEvent(testEvent))
          .thenAnswer((_) async => Either.left(failure));

      // Act
      final result = await useCase.call(testEvent);

      // Assert
      expect(result.isLeft, true);
      expect(result.isRight, false);
      expect(result.left, isA<ServerFailure>());
      expect(result.left.message, 'Update event failed');
      verify(mockRepository.updateEvent(testEvent)).called(1);
    });
  });
}

