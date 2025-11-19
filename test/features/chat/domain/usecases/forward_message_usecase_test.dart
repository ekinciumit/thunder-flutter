import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:thunder/features/chat/domain/usecases/forward_message_usecase.dart';
import 'package:thunder/features/chat/domain/repositories/chat_repository.dart';
import 'package:thunder/models/message_model.dart';
import 'package:thunder/core/errors/failures.dart';

import 'forward_message_usecase_test.mocks.dart';

/// Mock classes için annotation
@GenerateMocks([ChatRepository])
void main() {
  late ForwardMessageUseCase useCase;
  late MockChatRepository mockRepository;

  setUp(() {
    mockRepository = MockChatRepository();
    useCase = ForwardMessageUseCase(mockRepository);
  });

  group('ForwardMessageUseCase', () {
    const testTargetChatId = 'chat-456';
    const testSenderId = 'user-123';
    const testSenderName = 'Test User';
    final testOriginalMessage = MessageModel(
      id: 'msg-123',
      chatId: 'chat-123',
      senderId: 'user-456',
      senderName: 'Original Sender',
      text: 'Original message',
      timestamp: DateTime.now(),
      type: MessageType.text,
      status: MessageStatus.sent,
    );
    final testForwardedMessage = MessageModel(
      id: 'msg-789',
      chatId: testTargetChatId,
      senderId: testSenderId,
      senderName: testSenderName,
      text: 'Original message',
      timestamp: DateTime.now(),
      type: MessageType.forward,
      status: MessageStatus.sent,
      forwardFromUserId: testOriginalMessage.senderId,
      forwardFromUserName: testOriginalMessage.senderName,
    );

    test('should return Right(MessageModel) when message is forwarded successfully', () async {
      // Arrange
      when(mockRepository.forwardMessage(
        originalMessage: anyNamed('originalMessage'),
        targetChatId: anyNamed('targetChatId'),
        senderId: anyNamed('senderId'),
        senderName: anyNamed('senderName'),
      )).thenAnswer((_) async => Either.right(testForwardedMessage));

      // Act
      final result = await useCase.call(
        originalMessage: testOriginalMessage,
        targetChatId: testTargetChatId,
        senderId: testSenderId,
        senderName: testSenderName,
      );

      // Assert
      expect(result.isRight, true);
      expect(result.right, testForwardedMessage);
      verify(mockRepository.forwardMessage(
        originalMessage: testOriginalMessage,
        targetChatId: testTargetChatId,
        senderId: testSenderId,
        senderName: testSenderName,
      )).called(1);
    });

    test('should return Left(ValidationFailure) when targetChatId is empty', () async {
      // Act
      final result = await useCase.call(
        originalMessage: testOriginalMessage,
        targetChatId: '',
        senderId: testSenderId,
        senderName: testSenderName,
      );

      // Assert
      expect(result.isLeft, true);
      expect(result.left, isA<ValidationFailure>());
      expect(result.left.message, 'Hedef chat ID boş olamaz');
      verifyNever(mockRepository.forwardMessage(originalMessage: anyNamed('originalMessage'), targetChatId: anyNamed('targetChatId'), senderId: anyNamed('senderId'), senderName: anyNamed('senderName'), senderPhotoUrl: anyNamed('senderPhotoUrl')));
    });

    test('should return Left(ValidationFailure) when senderId is empty', () async {
      // Act
      final result = await useCase.call(
        originalMessage: testOriginalMessage,
        targetChatId: testTargetChatId,
        senderId: '',
        senderName: testSenderName,
      );

      // Assert
      expect(result.isLeft, true);
      expect(result.left, isA<ValidationFailure>());
      expect(result.left.message, 'Gönderen bilgileri boş olamaz');
      verifyNever(mockRepository.forwardMessage(originalMessage: anyNamed('originalMessage'), targetChatId: anyNamed('targetChatId'), senderId: anyNamed('senderId'), senderName: anyNamed('senderName'), senderPhotoUrl: anyNamed('senderPhotoUrl')));
    });

    test('should return Left(ValidationFailure) when originalMessage chatId equals targetChatId', () async {
      // Arrange
      final sameChatMessage = MessageModel(
        id: 'msg-123',
        chatId: testTargetChatId, // Aynı chat ID
        senderId: 'user-456',
        senderName: 'Original Sender',
        text: 'Original message',
        timestamp: DateTime.now(),
        type: MessageType.text,
        status: MessageStatus.sent,
      );

      // Act
      final result = await useCase.call(
        originalMessage: sameChatMessage,
        targetChatId: testTargetChatId,
        senderId: testSenderId,
        senderName: testSenderName,
      );

      // Assert
      expect(result.isLeft, true);
      expect(result.left, isA<ValidationFailure>());
      expect(result.left.message, 'Mesaj aynı sohbete iletilemez');
      verifyNever(mockRepository.forwardMessage(originalMessage: anyNamed('originalMessage'), targetChatId: anyNamed('targetChatId'), senderId: anyNamed('senderId'), senderName: anyNamed('senderName'), senderPhotoUrl: anyNamed('senderPhotoUrl')));
    });

    test('should return Left(ServerFailure) when repository returns failure', () async {
      // Arrange
      final failure = ServerFailure('Forward message failed');
      when(mockRepository.forwardMessage(originalMessage: anyNamed('originalMessage'), targetChatId: anyNamed('targetChatId'), senderId: anyNamed('senderId'), senderName: anyNamed('senderName'), senderPhotoUrl: anyNamed('senderPhotoUrl')))
          .thenAnswer((_) async => Either.left(failure));

      // Act
      final result = await useCase.call(
        originalMessage: testOriginalMessage,
        targetChatId: testTargetChatId,
        senderId: testSenderId,
        senderName: testSenderName,
      );

      // Assert
      expect(result.isLeft, true);
      expect(result.left, isA<ServerFailure>());
      expect(result.left.message, 'Forward message failed');
    });
  });
}

