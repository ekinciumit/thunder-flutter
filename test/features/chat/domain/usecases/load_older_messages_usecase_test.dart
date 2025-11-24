import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:thunder/features/chat/domain/usecases/load_older_messages_usecase.dart';
import 'package:thunder/features/chat/domain/repositories/chat_repository.dart';
import 'package:thunder/models/message_model.dart';
import 'package:thunder/core/errors/failures.dart';

import 'load_older_messages_usecase_test.mocks.dart';

/// Mock classes için annotation
@GenerateMocks([ChatRepository])
void main() {
  late LoadOlderMessagesUseCase useCase;
  late MockChatRepository mockRepository;

  setUp(() {
    mockRepository = MockChatRepository();
    useCase = LoadOlderMessagesUseCase(mockRepository);
  });

  group('LoadOlderMessagesUseCase', () {
    const testChatId = 'chat-123';
    final testLastMessageTime = DateTime.now();
    final testMessages = [
      MessageModel(
        id: 'msg-1',
        chatId: testChatId,
        senderId: 'user-1',
        senderName: 'User 1',
        text: 'Message 1',
        timestamp: testLastMessageTime.subtract(const Duration(hours: 1)),
        type: MessageType.text,
        status: MessageStatus.sent,
      ),
    ];

    test('should return Right(List<MessageModel>) when messages are loaded successfully', () async {
      // Arrange
      when(mockRepository.loadOlderMessages(testChatId, any, limit: anyNamed('limit')))
          .thenAnswer((_) async => Either.right(testMessages));

      // Act
      final result = await useCase.call(testChatId, testLastMessageTime, limit: 20);

      // Assert
      expect(result.isRight, true);
      expect(result.right, testMessages);
      verify(mockRepository.loadOlderMessages(testChatId, testLastMessageTime, limit: 20)).called(1);
    });

    test('should return Left(ValidationFailure) when chatId is empty', () async {
      // Act
      final result = await useCase.call('', testLastMessageTime);

      // Assert
      expect(result.isLeft, true);
      expect(result.left, isA<ValidationFailure>());
      expect(result.left.message, 'Chat ID boş olamaz');
      verifyNever(mockRepository.loadOlderMessages(any, any, limit: anyNamed('limit')));
    });

    test('should return Left(ValidationFailure) when limit is zero', () async {
      // Act
      final result = await useCase.call(testChatId, testLastMessageTime, limit: 0);

      // Assert
      expect(result.isLeft, true);
      expect(result.left, isA<ValidationFailure>());
      expect(result.left.message, 'Limit 0\'dan büyük olmalıdır');
      verifyNever(mockRepository.loadOlderMessages(any, any, limit: anyNamed('limit')));
    });

    test('should return Left(ValidationFailure) when limit is greater than 100', () async {
      // Act
      final result = await useCase.call(testChatId, testLastMessageTime, limit: 101);

      // Assert
      expect(result.isLeft, true);
      expect(result.left, isA<ValidationFailure>());
      expect(result.left.message, 'Limit 100\'den küçük olmalıdır');
      verifyNever(mockRepository.loadOlderMessages(any, any, limit: anyNamed('limit')));
    });

    test('should return Left(ServerFailure) when repository returns failure', () async {
      // Arrange
      final failure = ServerFailure('Load older messages failed');
      when(mockRepository.loadOlderMessages(any, any, limit: anyNamed('limit')))
          .thenAnswer((_) async => Either.left(failure));

      // Act
      final result = await useCase.call(testChatId, testLastMessageTime);

      // Assert
      expect(result.isLeft, true);
      expect(result.left, isA<ServerFailure>());
      expect(result.left.message, 'Load older messages failed');
    });
  });
}

