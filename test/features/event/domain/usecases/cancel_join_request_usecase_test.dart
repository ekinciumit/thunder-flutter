import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:thunder/features/event/domain/usecases/cancel_join_request_usecase.dart';
import 'package:thunder/features/event/domain/repositories/event_repository.dart';
import 'package:thunder/core/errors/failures.dart';

import 'cancel_join_request_usecase_test.mocks.dart';

/// Mock classes için annotation
@GenerateMocks([EventRepository])
void main() {
  late CancelJoinRequestUseCase useCase;
  late MockEventRepository mockRepository;

  setUp(() {
    mockRepository = MockEventRepository();
    useCase = CancelJoinRequestUseCase(mockRepository);
  });

  group('CancelJoinRequestUseCase', () {
    const testEventId = 'event-123';
    const testUserId = 'user-123';

    test('should return Right(void) when cancellation is successful', () async {
      // Arrange
      when(mockRepository.cancelJoinRequest(testEventId, testUserId))
          .thenAnswer((_) async => Either.rightVoid());

      // Act
      final result = await useCase.call(testEventId, testUserId);

      // Assert
      expect(result.isRight, true);
      expect(result.isLeft, false);
      verify(mockRepository.cancelJoinRequest(testEventId, testUserId)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return Left(ValidationFailure) when eventId is empty', () async {
      // Arrange
      const emptyEventId = '';

      // Act
      final result = await useCase.call(emptyEventId, testUserId);

      // Assert
      expect(result.isLeft, true);
      expect(result.left, isA<ValidationFailure>());
      expect(result.left.message, 'Etkinlik ID ve kullanıcı ID boş olamaz');
      verifyNever(mockRepository.cancelJoinRequest(any, any));
    });

    test('should return Left(ValidationFailure) when userId is empty', () async {
      // Arrange
      const emptyUserId = '';

      // Act
      final result = await useCase.call(testEventId, emptyUserId);

      // Assert
      expect(result.isLeft, true);
      expect(result.left, isA<ValidationFailure>());
      expect(result.left.message, 'Etkinlik ID ve kullanıcı ID boş olamaz');
      verifyNever(mockRepository.cancelJoinRequest(any, any));
    });

    test('should return Left(ServerFailure) when repository returns failure', () async {
      // Arrange
      final failure = ServerFailure('Cancel join request failed');
      when(mockRepository.cancelJoinRequest(testEventId, testUserId))
          .thenAnswer((_) async => Either.left(failure));

      // Act
      final result = await useCase.call(testEventId, testUserId);

      // Assert
      expect(result.isLeft, true);
      expect(result.isRight, false);
      expect(result.left, isA<ServerFailure>());
      expect(result.left.message, 'Cancel join request failed');
      verify(mockRepository.cancelJoinRequest(testEventId, testUserId)).called(1);
    });
  });
}

