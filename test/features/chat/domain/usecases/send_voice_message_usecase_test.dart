import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:thunder/features/chat/domain/usecases/send_voice_message_usecase.dart';
import 'package:thunder/features/chat/domain/repositories/chat_repository.dart';
import 'package:thunder/models/message_model.dart';
import 'package:thunder/core/errors/failures.dart';

import 'send_voice_message_usecase_test.mocks.dart';

/// Mock classes için annotation
@GenerateMocks([ChatRepository])
void main() {
  late SendVoiceMessageUseCase useCase;
  late MockChatRepository mockRepository;

  setUp(() {
    mockRepository = MockChatRepository();
    useCase = SendVoiceMessageUseCase(mockRepository);
  });

  group('SendVoiceMessageUseCase', () {
    const testChatId = 'chat-123';
    const testSenderId = 'user-123';
    const testSenderName = 'Test User';
    const testAudioUrl = 'https://example.com/audio.mp3';
    final testDuration = const Duration(seconds: 30);
    final testMessage = MessageModel(
      id: 'msg-123',
      chatId: testChatId,
      senderId: testSenderId,
      senderName: testSenderName,
      audioUrl: testAudioUrl,
      timestamp: DateTime.now(),
      type: MessageType.audio,
      status: MessageStatus.sent,
    );

    test('should return Right(MessageModel) when voice message is sent successfully', () async {
      // Arrange
      when(mockRepository.sendVoiceMessage(
        chatId: anyNamed('chatId'),
        senderId: anyNamed('senderId'),
        senderName: anyNamed('senderName'),
        audioUrl: anyNamed('audioUrl'),
        duration: anyNamed('duration'),
      )).thenAnswer((_) async => Either.right(testMessage));

      // Act
      final result = await useCase.call(
        chatId: testChatId,
        senderId: testSenderId,
        senderName: testSenderName,
        audioUrl: testAudioUrl,
        duration: testDuration,
      );

      // Assert
      expect(result.isRight, true);
      expect(result.right, testMessage);
      verify(mockRepository.sendVoiceMessage(
        chatId: testChatId,
        senderId: testSenderId,
        senderName: testSenderName,
        audioUrl: testAudioUrl,
        duration: testDuration,
      )).called(1);
    });

    test('should return Left(ValidationFailure) when chatId is empty', () async {
      // Act
      final result = await useCase.call(
        chatId: '',
        senderId: testSenderId,
        senderName: testSenderName,
        audioUrl: testAudioUrl,
        duration: testDuration,
      );

      // Assert
      expect(result.isLeft, true);
      expect(result.left, isA<ValidationFailure>());
      expect(result.left.message, 'Chat ID boş olamaz');
      verifyNever(mockRepository.sendVoiceMessage(chatId: anyNamed('chatId'), senderId: anyNamed('senderId'), senderName: anyNamed('senderName'), audioUrl: anyNamed('audioUrl'), duration: anyNamed('duration')));
    });

    test('should return Left(ValidationFailure) when senderId is empty', () async {
      // Act
      final result = await useCase.call(
        chatId: testChatId,
        senderId: '',
        senderName: testSenderName,
        audioUrl: testAudioUrl,
        duration: testDuration,
      );

      // Assert
      expect(result.isLeft, true);
      expect(result.left, isA<ValidationFailure>());
      expect(result.left.message, 'Gönderen bilgileri boş olamaz');
      verifyNever(mockRepository.sendVoiceMessage(chatId: anyNamed('chatId'), senderId: anyNamed('senderId'), senderName: anyNamed('senderName'), audioUrl: anyNamed('audioUrl'), duration: anyNamed('duration')));
    });

    test('should return Left(ValidationFailure) when audioUrl is empty', () async {
      // Act
      final result = await useCase.call(
        chatId: testChatId,
        senderId: testSenderId,
        senderName: testSenderName,
        audioUrl: '',
        duration: testDuration,
      );

      // Assert
      expect(result.isLeft, true);
      expect(result.left, isA<ValidationFailure>());
      expect(result.left.message, 'Ses URL\'si boş olamaz');
      verifyNever(mockRepository.sendVoiceMessage(chatId: anyNamed('chatId'), senderId: anyNamed('senderId'), senderName: anyNamed('senderName'), audioUrl: anyNamed('audioUrl'), duration: anyNamed('duration')));
    });

    test('should return Left(ValidationFailure) when duration is zero', () async {
      // Act
      final result = await useCase.call(
        chatId: testChatId,
        senderId: testSenderId,
        senderName: testSenderName,
        audioUrl: testAudioUrl,
        duration: Duration.zero,
      );

      // Assert
      expect(result.isLeft, true);
      expect(result.left, isA<ValidationFailure>());
      expect(result.left.message, 'Ses süresi 0\'dan büyük olmalıdır');
      verifyNever(mockRepository.sendVoiceMessage(chatId: anyNamed('chatId'), senderId: anyNamed('senderId'), senderName: anyNamed('senderName'), audioUrl: anyNamed('audioUrl'), duration: anyNamed('duration')));
    });

    test('should return Left(ServerFailure) when repository returns failure', () async {
      // Arrange
      final failure = ServerFailure('Send voice message failed');
      when(mockRepository.sendVoiceMessage(chatId: anyNamed('chatId'), senderId: anyNamed('senderId'), senderName: anyNamed('senderName'), audioUrl: anyNamed('audioUrl'), duration: anyNamed('duration')))
          .thenAnswer((_) async => Either.left(failure));

      // Act
      final result = await useCase.call(
        chatId: testChatId,
        senderId: testSenderId,
        senderName: testSenderName,
        audioUrl: testAudioUrl,
        duration: testDuration,
      );

      // Assert
      expect(result.isLeft, true);
      expect(result.left, isA<ServerFailure>());
      expect(result.left.message, 'Send voice message failed');
    });
  });
}

