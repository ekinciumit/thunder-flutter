import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:thunder/features/chat/domain/usecases/send_message_usecase.dart';
import 'package:thunder/features/chat/domain/repositories/chat_repository.dart';
import 'package:thunder/models/message_model.dart';
import 'package:thunder/core/errors/failures.dart';

import 'send_message_usecase_test.mocks.dart';

/// Mock classes için annotation
@GenerateMocks([ChatRepository])
void main() {
  late SendMessageUseCase useCase;
  late MockChatRepository mockRepository;

  setUp(() {
    mockRepository = MockChatRepository();
    useCase = SendMessageUseCase(mockRepository);
  });

  group('SendMessageUseCase', () {
    const testChatId = 'chat-123';
    const testSenderId = 'user-123';
    const testSenderName = 'Test User';
    const testText = 'Test message';
    final testMessage = MessageModel(
      id: 'msg-123',
      chatId: testChatId,
      senderId: testSenderId,
      senderName: testSenderName,
      text: testText,
      timestamp: DateTime.now(),
      type: MessageType.text,
      status: MessageStatus.sent,
    );

    test('should return Right(MessageModel) when message is sent successfully', () async {
      // Arrange
      when(mockRepository.sendMessage(
        chatId: anyNamed('chatId'),
        senderId: anyNamed('senderId'),
        senderName: anyNamed('senderName'),
        text: anyNamed('text'),
        type: anyNamed('type'),
      )).thenAnswer((_) async => Either.right(testMessage));

      // Act
      final result = await useCase.call(
        chatId: testChatId,
        senderId: testSenderId,
        senderName: testSenderName,
        text: testText,
      );

      // Assert
      expect(result.isRight, true);
      expect(result.right, testMessage);
      verify(mockRepository.sendMessage(
        chatId: testChatId,
        senderId: testSenderId,
        senderName: testSenderName,
        text: testText,
        type: MessageType.text,
      )).called(1);
    });

    test('should return Left(ValidationFailure) when chatId is empty', () async {
      // Act
      final result = await useCase.call(
        chatId: '',
        senderId: testSenderId,
        senderName: testSenderName,
        text: testText,
      );

      // Assert
      expect(result.isLeft, true);
      expect(result.left, isA<ValidationFailure>());
      expect(result.left.message, 'Chat ID boş olamaz');
      verifyNever(mockRepository.sendMessage(chatId: anyNamed('chatId'), senderId: anyNamed('senderId'), senderName: anyNamed('senderName'), text: anyNamed('text'), type: anyNamed('type')));
    });

    test('should return Left(ValidationFailure) when senderId is empty', () async {
      // Act
      final result = await useCase.call(
        chatId: testChatId,
        senderId: '',
        senderName: testSenderName,
        text: testText,
      );

      // Assert
      expect(result.isLeft, true);
      expect(result.left, isA<ValidationFailure>());
      expect(result.left.message, 'Gönderen bilgileri boş olamaz');
      verifyNever(mockRepository.sendMessage(chatId: anyNamed('chatId'), senderId: anyNamed('senderId'), senderName: anyNamed('senderName'), text: anyNamed('text'), type: anyNamed('type')));
    });

    test('should return Left(ValidationFailure) when senderName is empty', () async {
      // Act
      final result = await useCase.call(
        chatId: testChatId,
        senderId: testSenderId,
        senderName: '',
        text: testText,
      );

      // Assert
      expect(result.isLeft, true);
      expect(result.left, isA<ValidationFailure>());
      expect(result.left.message, 'Gönderen bilgileri boş olamaz');
      verifyNever(mockRepository.sendMessage(chatId: anyNamed('chatId'), senderId: anyNamed('senderId'), senderName: anyNamed('senderName'), text: anyNamed('text'), type: anyNamed('type')));
    });

    test('should return Left(ValidationFailure) when text message has empty text', () async {
      // Act
      final result = await useCase.call(
        chatId: testChatId,
        senderId: testSenderId,
        senderName: testSenderName,
        text: '',
        type: MessageType.text,
      );

      // Assert
      expect(result.isLeft, true);
      expect(result.left, isA<ValidationFailure>());
      expect(result.left.message, 'Metin mesajı için metin boş olamaz');
      verifyNever(mockRepository.sendMessage(chatId: anyNamed('chatId'), senderId: anyNamed('senderId'), senderName: anyNamed('senderName'), text: anyNamed('text'), type: anyNamed('type')));
    });

    test('should return Left(ValidationFailure) when image message has no imageUrl', () async {
      // Act
      final result = await useCase.call(
        chatId: testChatId,
        senderId: testSenderId,
        senderName: testSenderName,
        type: MessageType.image,
      );

      // Assert
      expect(result.isLeft, true);
      expect(result.left, isA<ValidationFailure>());
      expect(result.left.message, 'Resim mesajı için resim URL\'si gerekli');
      verifyNever(mockRepository.sendMessage(chatId: anyNamed('chatId'), senderId: anyNamed('senderId'), senderName: anyNamed('senderName'), type: anyNamed('type')));
    });

    test('should return Left(ValidationFailure) when file message has no fileUrl', () async {
      // Act
      final result = await useCase.call(
        chatId: testChatId,
        senderId: testSenderId,
        senderName: testSenderName,
        type: MessageType.file,
      );

      // Assert
      expect(result.isLeft, true);
      expect(result.left, isA<ValidationFailure>());
      expect(result.left.message, 'Dosya mesajı için dosya bilgileri gerekli');
      verifyNever(mockRepository.sendMessage(chatId: anyNamed('chatId'), senderId: anyNamed('senderId'), senderName: anyNamed('senderName'), type: anyNamed('type')));
    });

    test('should return Left(ServerFailure) when repository returns failure', () async {
      // Arrange
      final failure = ServerFailure('Send message failed');
      when(mockRepository.sendMessage(chatId: anyNamed('chatId'), senderId: anyNamed('senderId'), senderName: anyNamed('senderName'), text: anyNamed('text'), type: anyNamed('type')))
          .thenAnswer((_) async => Either.left(failure));

      // Act
      final result = await useCase.call(
        chatId: testChatId,
        senderId: testSenderId,
        senderName: testSenderName,
        text: testText,
      );

      // Assert
      expect(result.isLeft, true);
      expect(result.left, isA<ServerFailure>());
      expect(result.left.message, 'Send message failed');
    });
  });
}

