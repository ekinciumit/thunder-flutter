import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:thunder/features/chat/domain/usecases/get_messages_usecase.dart';
import 'package:thunder/features/chat/domain/repositories/chat_repository.dart';
import 'package:thunder/models/message_model.dart';

import 'get_messages_usecase_test.mocks.dart';

/// Mock classes için annotation
@GenerateMocks([ChatRepository])
void main() {
  late GetMessagesUseCase useCase;
  late MockChatRepository mockRepository;

  setUp(() {
    mockRepository = MockChatRepository();
    useCase = GetMessagesUseCase(mockRepository);
  });

  group('GetMessagesUseCase', () {
    const testChatId = 'chat-123';
    final testMessages = [
      MessageModel(
        id: 'msg-1',
        chatId: testChatId,
        senderId: 'user-1',
        senderName: 'User 1',
        text: 'Message 1',
        timestamp: DateTime.now(),
        type: MessageType.text,
        status: MessageStatus.sent,
      ),
    ];

    test('should return Stream<List<MessageModel>> when stream is successful', () async {
      // Arrange
      final streamController = StreamController<List<MessageModel>>();
      when(mockRepository.getMessagesStream(testChatId, limit: anyNamed('limit')))
          .thenAnswer((_) => streamController.stream);

      // Act
      final stream = useCase.call(testChatId, limit: 50);
      streamController.add(testMessages);

      // Assert
      expect(stream, isA<Stream<List<MessageModel>>>());
      final result = await stream.first;
      expect(result, testMessages);
      verify(mockRepository.getMessagesStream(testChatId, limit: 50)).called(1);
      
      await streamController.close();
    });

    test('should return empty list when stream emits empty list', () async {
      // Arrange
      final streamController = StreamController<List<MessageModel>>();
      when(mockRepository.getMessagesStream(testChatId, limit: anyNamed('limit')))
          .thenAnswer((_) => streamController.stream);

      // Act
      final stream = useCase.call(testChatId);
      streamController.add([]);

      // Assert
      final result = await stream.first;
      expect(result, isEmpty);
      verify(mockRepository.getMessagesStream(testChatId, limit: 50)).called(1);
      
      await streamController.close();
    });
  });
}

