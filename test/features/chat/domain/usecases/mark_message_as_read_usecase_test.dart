import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:thunder/features/chat/domain/usecases/mark_message_as_read_usecase.dart';
import 'package:thunder/features/chat/domain/repositories/chat_repository.dart';
import 'package:thunder/core/errors/failures.dart';

import 'mark_message_as_read_usecase_test.mocks.dart';

/// Mock classes için annotation
@GenerateMocks([ChatRepository])
void main() {
  late MarkMessageAsReadUseCase useCase;
  late MockChatRepository mockRepository;

  setUp(() {
    mockRepository = MockChatRepository();
    useCase = MarkMessageAsReadUseCase(mockRepository);
  });

  group('MarkMessageAsReadUseCase', () {
    const testMessageId = 'msg-123';
    const testUserId = 'user-123';

    test('should return Right(void) when message is marked as read successfully', () async {
      // Arrange
      when(mockRepository.markMessageAsRead(testMessageId, testUserId))
          .thenAnswer((_) async => Either.rightVoid());

      // Act
      final result = await useCase.call(testMessageId, testUserId);

      // Assert
      expect(result.isRight, true);
      verify(mockRepository.markMessageAsRead(testMessageId, testUserId)).called(1);
    });

    test('should return Left(ValidationFailure) when messageId is empty', () async {
      // Act
      final result = await useCase.call('', testUserId);

      // Assert
      expect(result.isLeft, true);
      expect(result.left, isA<ValidationFailure>());
      expect(result.left.message, 'Mesaj ID ve kullanıcı ID boş olamaz');
      verifyNever(mockRepository.markMessageAsRead(any, any));
    });

    test('should return Left(ValidationFailure) when userId is empty', () async {
      // Act
      final result = await useCase.call(testMessageId, '');

      // Assert
      expect(result.isLeft, true);
      expect(result.left, isA<ValidationFailure>());
      expect(result.left.message, 'Mesaj ID ve kullanıcı ID boş olamaz');
      verifyNever(mockRepository.markMessageAsRead(any, any));
    });

    test('should return Left(ServerFailure) when repository returns failure', () async {
      // Arrange
      final failure = ServerFailure('Mark as read failed');
      when(mockRepository.markMessageAsRead(testMessageId, testUserId))
          .thenAnswer((_) async => Either.left(failure));

      // Act
      final result = await useCase.call(testMessageId, testUserId);

      // Assert
      expect(result.isLeft, true);
      expect(result.left, isA<ServerFailure>());
      expect(result.left.message, 'Mark as read failed');
    });
  });
}

