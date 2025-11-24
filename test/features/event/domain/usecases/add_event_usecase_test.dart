import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:thunder/features/event/domain/usecases/add_event_usecase.dart';
import 'package:thunder/features/event/domain/repositories/event_repository.dart';
import 'package:thunder/models/event_model.dart';
import 'package:thunder/core/errors/failures.dart';

import 'add_event_usecase_test.mocks.dart';

/// Mock classes için annotation
@GenerateMocks([EventRepository])
void main() {
  late AddEventUseCase useCase;
  late MockEventRepository mockRepository;

  setUp(() {
    mockRepository = MockEventRepository();
    useCase = AddEventUseCase(mockRepository);
  });

  group('AddEventUseCase', () {
    final testEvent = EventModel(
      id: 'event-123',
      title: 'Test Event',
      description: 'Test Description',
      location: const GeoPoint(41.0082, 28.9784), // İstanbul
      address: 'Test Address',
      datetime: DateTime.now().add(const Duration(days: 1)),
      quota: 10,
      createdBy: 'user-123',
      participants: [],
    );

    test('should return Right(void) when event is added successfully', () async {
      // Arrange
      when(mockRepository.addEvent(testEvent))
          .thenAnswer((_) async => Either.rightVoid());

      // Act
      final result = await useCase.call(testEvent);

      // Assert
      expect(result.isRight, true);
      expect(result.isLeft, false);
      verify(mockRepository.addEvent(testEvent)).called(1);
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
      verifyNever(mockRepository.addEvent(any));
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
      verifyNever(mockRepository.addEvent(any));
    });

    test('should return Left(ValidationFailure) when quota is zero', () async {
      // Arrange
      final invalidEvent = EventModel(
        id: 'event-123',
        title: 'Test Event',
        description: 'Test Description',
        location: const GeoPoint(41.0082, 28.9784),
        address: 'Test Address',
        datetime: DateTime.now().add(const Duration(days: 1)),
        quota: 0, // Sıfır quota
        createdBy: 'user-123',
        participants: [],
      );

      // Act
      final result = await useCase.call(invalidEvent);

      // Assert
      expect(result.isLeft, true);
      expect(result.left, isA<ValidationFailure>());
      expect(result.left.message, 'Kota 0\'dan büyük olmalıdır');
      verifyNever(mockRepository.addEvent(any));
    });

    test('should return Left(ValidationFailure) when quota is negative', () async {
      // Arrange
      final invalidEvent = EventModel(
        id: 'event-123',
        title: 'Test Event',
        description: 'Test Description',
        location: const GeoPoint(41.0082, 28.9784),
        address: 'Test Address',
        datetime: DateTime.now().add(const Duration(days: 1)),
        quota: -5, // Negatif quota
        createdBy: 'user-123',
        participants: [],
      );

      // Act
      final result = await useCase.call(invalidEvent);

      // Assert
      expect(result.isLeft, true);
      expect(result.left, isA<ValidationFailure>());
      expect(result.left.message, 'Kota 0\'dan büyük olmalıdır');
      verifyNever(mockRepository.addEvent(any));
    });

    test('should return Left(ServerFailure) when repository returns failure', () async {
      // Arrange
      final failure = ServerFailure('Add event failed');
      when(mockRepository.addEvent(testEvent))
          .thenAnswer((_) async => Either.left(failure));

      // Act
      final result = await useCase.call(testEvent);

      // Assert
      expect(result.isLeft, true);
      expect(result.isRight, false);
      expect(result.left, isA<ServerFailure>());
      expect(result.left.message, 'Add event failed');
      verify(mockRepository.addEvent(testEvent)).called(1);
    });

    test('should return Left(NetworkFailure) when repository returns NetworkFailure', () async {
      // Arrange
      final failure = NetworkFailure('Network error');
      when(mockRepository.addEvent(testEvent))
          .thenAnswer((_) async => Either.left(failure));

      // Act
      final result = await useCase.call(testEvent);

      // Assert
      expect(result.isLeft, true);
      expect(result.left, isA<NetworkFailure>());
      expect(result.left.message, 'Network error');
      verify(mockRepository.addEvent(testEvent)).called(1);
    });
  });
}

