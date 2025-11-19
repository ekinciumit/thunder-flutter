import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:thunder/features/chat/domain/usecases/delete_message_usecase.dart';
import 'package:thunder/features/chat/domain/repositories/chat_repository.dart';
import 'package:thunder/core/errors/failures.dart';

import 'delete_message_usecase_test.mocks.dart';

/// Mock classes için annotation
@GenerateMocks([ChatRepository])
void main() {
  late DeleteMessageUseCase useCase;
  late MockChatRepository mockRepository;

  setUp(() {
    mockRepository = MockChatRepository();
    useCase = DeleteMessageUseCase(mockRepository);
  });

  group('DeleteMessageUseCase', () {
    const testMessageId = 'msg-123';
    const testUserId = 'user-123';

    test('should return Right(void) when message is deleted successfully', () async {
      // Arrange
      when(mockRepository.deleteMessage(testMessageId, testUserId))
          .thenAnswer((_) async => Either.rightVoid());

      // Act
      final result = await useCase.call(testMessageId, testUserId);

      // Assert
      expect(result.isRight, true);
      verify(mockRepository.deleteMessage(testMessageId, testUserId)).called(1);
    });

    test('should return Left(ValidationFailure) when messageId is empty', () async {
      // Act
      final result = await useCase.call('', testUserId);

      // Assert
      expect(result.isLeft, true);
      expect(result.left, isA<ValidationFailure>());
      expect(result.left.message, 'Mesaj ID ve kullanıcı ID boş olamaz');
      verifyNever(mockRepository.deleteMessage(any, any));
    });

    test('should return Left(ValidationFailure) when userId is empty', () async {
      // Act
      final result = await useCase.call(testMessageId, '');

      // Assert
      expect(result.isLeft, true);
      expect(result.left, isA<ValidationFailure>());
      expect(result.left.message, 'Mesaj ID ve kullanıcı ID boş olamaz');
      verifyNever(mockRepository.deleteMessage(any, any));
    });

    test('should return Left(ServerFailure) when repository returns failure', () async {
      // Arrange
      final failure = ServerFailure('Delete message failed');
      when(mockRepository.deleteMessage(testMessageId, testUserId))
          .thenAnswer((_) async => Either.left(failure));

      // Act
      final result = await useCase.call(testMessageId, testUserId);

      // Assert
      expect(result.isLeft, true);
      expect(result.left, isA<ServerFailure>());
      expect(result.left.message, 'Delete message failed');
    });
  });
}

