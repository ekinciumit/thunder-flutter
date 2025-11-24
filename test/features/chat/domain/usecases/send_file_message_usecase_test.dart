import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:thunder/features/chat/domain/usecases/send_file_message_usecase.dart';
import 'package:thunder/features/chat/domain/repositories/chat_repository.dart';
import 'package:thunder/models/message_model.dart';
import 'package:thunder/core/errors/failures.dart';

import 'send_file_message_usecase_test.mocks.dart';

/// Mock classes için annotation
@GenerateMocks([ChatRepository])
void main() {
  late SendFileMessageUseCase useCase;
  late MockChatRepository mockRepository;

  setUp(() {
    mockRepository = MockChatRepository();
    useCase = SendFileMessageUseCase(mockRepository);
  });

  group('SendFileMessageUseCase', () {
    const testChatId = 'chat-123';
    const testSenderId = 'user-123';
    const testSenderName = 'Test User';
    const testFileUrl = 'https://example.com/file.pdf';
    const testFileName = 'document.pdf';
    const testFileSize = 1024;
    final testMessage = MessageModel(
      id: 'msg-123',
      chatId: testChatId,
      senderId: testSenderId,
      senderName: testSenderName,
      fileUrl: testFileUrl,
      fileName: testFileName,
      fileSize: testFileSize,
      timestamp: DateTime.now(),
      type: MessageType.file,
      status: MessageStatus.sent,
    );

    test('should return Right(MessageModel) when file message is sent successfully', () async {
      // Arrange
      when(mockRepository.sendFileMessage(
        chatId: anyNamed('chatId'),
        senderId: anyNamed('senderId'),
        senderName: anyNamed('senderName'),
        fileUrl: anyNamed('fileUrl'),
        fileName: anyNamed('fileName'),
        fileSize: anyNamed('fileSize'),
      )).thenAnswer((_) async => Either.right(testMessage));

      // Act
      final result = await useCase.call(
        chatId: testChatId,
        senderId: testSenderId,
        senderName: testSenderName,
        fileUrl: testFileUrl,
        fileName: testFileName,
        fileSize: testFileSize,
      );

      // Assert
      expect(result.isRight, true);
      expect(result.right, testMessage);
      verify(mockRepository.sendFileMessage(
        chatId: testChatId,
        senderId: testSenderId,
        senderName: testSenderName,
        fileUrl: testFileUrl,
        fileName: testFileName,
        fileSize: testFileSize,
      )).called(1);
    });

    test('should return Left(ValidationFailure) when chatId is empty', () async {
      // Act
      final result = await useCase.call(
        chatId: '',
        senderId: testSenderId,
        senderName: testSenderName,
        fileUrl: testFileUrl,
        fileName: testFileName,
        fileSize: testFileSize,
      );

      // Assert
      expect(result.isLeft, true);
      expect(result.left, isA<ValidationFailure>());
      expect(result.left.message, 'Chat ID boş olamaz');
      verifyNever(mockRepository.sendFileMessage(chatId: anyNamed('chatId'), senderId: anyNamed('senderId'), senderName: anyNamed('senderName'), fileUrl: anyNamed('fileUrl'), fileName: anyNamed('fileName'), fileSize: anyNamed('fileSize')));
    });

    test('should return Left(ValidationFailure) when fileUrl is empty', () async {
      // Act
      final result = await useCase.call(
        chatId: testChatId,
        senderId: testSenderId,
        senderName: testSenderName,
        fileUrl: '',
        fileName: testFileName,
        fileSize: testFileSize,
      );

      // Assert
      expect(result.isLeft, true);
      expect(result.left, isA<ValidationFailure>());
      expect(result.left.message, 'Dosya URL\'si boş olamaz');
      verifyNever(mockRepository.sendFileMessage(chatId: anyNamed('chatId'), senderId: anyNamed('senderId'), senderName: anyNamed('senderName'), fileUrl: anyNamed('fileUrl'), fileName: anyNamed('fileName'), fileSize: anyNamed('fileSize')));
    });

    test('should return Left(ValidationFailure) when fileName is empty', () async {
      // Act
      final result = await useCase.call(
        chatId: testChatId,
        senderId: testSenderId,
        senderName: testSenderName,
        fileUrl: testFileUrl,
        fileName: '',
        fileSize: testFileSize,
      );

      // Assert
      expect(result.isLeft, true);
      expect(result.left, isA<ValidationFailure>());
      expect(result.left.message, 'Dosya adı boş olamaz');
      verifyNever(mockRepository.sendFileMessage(chatId: anyNamed('chatId'), senderId: anyNamed('senderId'), senderName: anyNamed('senderName'), fileUrl: anyNamed('fileUrl'), fileName: anyNamed('fileName'), fileSize: anyNamed('fileSize')));
    });

    test('should return Left(ValidationFailure) when fileSize is zero', () async {
      // Act
      final result = await useCase.call(
        chatId: testChatId,
        senderId: testSenderId,
        senderName: testSenderName,
        fileUrl: testFileUrl,
        fileName: testFileName,
        fileSize: 0,
      );

      // Assert
      expect(result.isLeft, true);
      expect(result.left, isA<ValidationFailure>());
      expect(result.left.message, 'Dosya boyutu 0\'dan büyük olmalıdır');
      verifyNever(mockRepository.sendFileMessage(chatId: anyNamed('chatId'), senderId: anyNamed('senderId'), senderName: anyNamed('senderName'), fileUrl: anyNamed('fileUrl'), fileName: anyNamed('fileName'), fileSize: anyNamed('fileSize')));
    });

    test('should return Left(ServerFailure) when repository returns failure', () async {
      // Arrange
      final failure = ServerFailure('Send file message failed');
      when(mockRepository.sendFileMessage(chatId: anyNamed('chatId'), senderId: anyNamed('senderId'), senderName: anyNamed('senderName'), fileUrl: anyNamed('fileUrl'), fileName: anyNamed('fileName'), fileSize: anyNamed('fileSize')))
          .thenAnswer((_) async => Either.left(failure));

      // Act
      final result = await useCase.call(
        chatId: testChatId,
        senderId: testSenderId,
        senderName: testSenderName,
        fileUrl: testFileUrl,
        fileName: testFileName,
        fileSize: testFileSize,
      );

      // Assert
      expect(result.isLeft, true);
      expect(result.left, isA<ServerFailure>());
      expect(result.left.message, 'Send file message failed');
    });
  });
}

