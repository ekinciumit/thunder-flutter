import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:thunder/features/chat/domain/usecases/update_typing_status_usecase.dart';
import 'package:thunder/features/chat/domain/repositories/chat_repository.dart';
import 'package:thunder/core/errors/failures.dart';

import 'update_typing_status_usecase_test.mocks.dart';

/// Mock classes için annotation
@GenerateMocks([ChatRepository])
void main() {
  late UpdateTypingStatusUseCase useCase;
  late MockChatRepository mockRepository;

  setUp(() {
    mockRepository = MockChatRepository();
    useCase = UpdateTypingStatusUseCase(mockRepository);
  });

  group('UpdateTypingStatusUseCase', () {
    const testChatId = 'chat-123';
    const testUserId = 'user-123';
    const testIsTyping = true;

    test('should return Right(void) when typing status is updated successfully', () async {
      // Arrange
      when(mockRepository.updateTypingStatus(testChatId, testUserId, testIsTyping))
          .thenAnswer((_) async => Either.rightVoid());

      // Act
      final result = await useCase.call(testChatId, testUserId, testIsTyping);

      // Assert
      expect(result.isRight, true);
      verify(mockRepository.updateTypingStatus(testChatId, testUserId, testIsTyping)).called(1);
    });

    test('should return Left(ValidationFailure) when chatId is empty', () async {
      // Act
      final result = await useCase.call('', testUserId, testIsTyping);

      // Assert
      expect(result.isLeft, true);
      expect(result.left, isA<ValidationFailure>());
      expect(result.left.message, 'Chat ID ve kullanıcı ID boş olamaz');
      verifyNever(mockRepository.updateTypingStatus(any, any, any));
    });

    test('should return Left(ValidationFailure) when userId is empty', () async {
      // Act
      final result = await useCase.call(testChatId, '', testIsTyping);

      // Assert
      expect(result.isLeft, true);
      expect(result.left, isA<ValidationFailure>());
      expect(result.left.message, 'Chat ID ve kullanıcı ID boş olamaz');
      verifyNever(mockRepository.updateTypingStatus(any, any, any));
    });

    test('should return Left(ServerFailure) when repository returns failure', () async {
      // Arrange
      final failure = ServerFailure('Update typing status failed');
      when(mockRepository.updateTypingStatus(testChatId, testUserId, testIsTyping))
          .thenAnswer((_) async => Either.left(failure));

      // Act
      final result = await useCase.call(testChatId, testUserId, testIsTyping);

      // Assert
      expect(result.isLeft, true);
      expect(result.left, isA<ServerFailure>());
      expect(result.left.message, 'Update typing status failed');
    });
  });
}

