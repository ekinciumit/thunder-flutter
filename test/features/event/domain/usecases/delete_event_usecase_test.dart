import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:thunder/features/event/domain/usecases/delete_event_usecase.dart';
import 'package:thunder/features/event/domain/repositories/event_repository.dart';
import 'package:thunder/core/errors/failures.dart';

import 'delete_event_usecase_test.mocks.dart';

/// Mock classes için annotation
@GenerateMocks([EventRepository])
void main() {
  late DeleteEventUseCase useCase;
  late MockEventRepository mockRepository;

  setUp(() {
    mockRepository = MockEventRepository();
    useCase = DeleteEventUseCase(mockRepository);
  });

  group('DeleteEventUseCase', () {
    const testEventId = 'event-123';

    test('should return Right(void) when event is deleted successfully', () async {
      // Arrange
      when(mockRepository.deleteEvent(testEventId))
          .thenAnswer((_) async => Either.rightVoid());

      // Act
      final result = await useCase.call(testEventId);

      // Assert
      expect(result.isRight, true);
      expect(result.isLeft, false);
      verify(mockRepository.deleteEvent(testEventId)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return Left(ValidationFailure) when eventId is empty', () async {
      // Arrange
      const emptyEventId = '';

      // Act
      final result = await useCase.call(emptyEventId);

      // Assert
      expect(result.isLeft, true);
      expect(result.left, isA<ValidationFailure>());
      expect(result.left.message, 'Etkinlik ID boş olamaz');
      verifyNever(mockRepository.deleteEvent(any));
    });

    test('should return Left(ServerFailure) when repository returns failure', () async {
      // Arrange
      final failure = ServerFailure('Delete event failed');
      when(mockRepository.deleteEvent(testEventId))
          .thenAnswer((_) async => Either.left(failure));

      // Act
      final result = await useCase.call(testEventId);

      // Assert
      expect(result.isLeft, true);
      expect(result.isRight, false);
      expect(result.left, isA<ServerFailure>());
      expect(result.left.message, 'Delete event failed');
      verify(mockRepository.deleteEvent(testEventId)).called(1);
    });

    test('should return Left(NetworkFailure) when repository returns NetworkFailure', () async {
      // Arrange
      final failure = NetworkFailure('Network error');
      when(mockRepository.deleteEvent(testEventId))
          .thenAnswer((_) async => Either.left(failure));

      // Act
      final result = await useCase.call(testEventId);

      // Assert
      expect(result.isLeft, true);
      expect(result.left, isA<NetworkFailure>());
      expect(result.left.message, 'Network error');
      verify(mockRepository.deleteEvent(testEventId)).called(1);
    });
  });
}

