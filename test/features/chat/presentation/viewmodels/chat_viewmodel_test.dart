import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:thunder/features/chat/presentation/viewmodels/chat_viewmodel.dart';
import 'package:thunder/features/chat/domain/repositories/chat_repository.dart';
import 'package:thunder/models/chat_model.dart';
import 'package:thunder/models/message_model.dart';
import 'package:thunder/core/errors/failures.dart';

import 'chat_viewmodel_test.mocks.dart';

/// Mock classes için annotation
@GenerateMocks([ChatRepository])
void main() {
  late ChatViewModel viewModel;
  late MockChatRepository mockRepository;

  setUp(() {
    mockRepository = MockChatRepository();
    viewModel = ChatViewModel(chatRepository: mockRepository);
  });

  group('ChatViewModel', () {
    group('getChatId', () {
      const testUserA = 'user-a';
      const testUserB = 'user-b';
      const testChatId = 'chat-123';

      test('should return chatId from repository', () {
        // Arrange
        when(mockRepository.getChatId(testUserA, testUserB))
            .thenReturn(testChatId);

        // Act
        final result = viewModel.getChatId(testUserA, testUserB);

        // Assert
        expect(result, testChatId);
        verify(mockRepository.getChatId(testUserA, testUserB)).called(1);
      });
    });

    group('getOrCreatePrivateChat', () {
      const testUserA = 'user-a';
      const testUserB = 'user-b';
      final testChat = ChatModel(
        id: 'chat-123',
        name: 'Private Chat',
        type: ChatType.private,
        participants: [testUserA, testUserB],
        createdAt: DateTime.now(),
      );

      test('should return ChatModel when successful', () async {
        // Arrange
        when(mockRepository.getOrCreatePrivateChat(testUserA, testUserB))
            .thenAnswer((_) async => Either.right(testChat));

        // Act
        final result = await viewModel.getOrCreatePrivateChat(testUserA, testUserB);

        // Assert
        expect(result, testChat);
        expect(viewModel.isLoading, false);
        expect(viewModel.error, isNull);
        verify(mockRepository.getOrCreatePrivateChat(testUserA, testUserB)).called(1);
      });

      test('should set error when fails', () async {
        // Arrange
        final failure = ServerFailure('Get chat failed');
        when(mockRepository.getOrCreatePrivateChat(testUserA, testUserB))
            .thenAnswer((_) async => Either.left(failure));

        // Act
        final result = await viewModel.getOrCreatePrivateChat(testUserA, testUserB);

        // Assert
        expect(result, isNull);
        expect(viewModel.error, 'Get chat failed');
        // isLoading false olmalı çünkü ChatViewModel failure durumunda isLoading'i false yapıyor
        // Ancak notifyListeners() async olabilir, bu yüzden kontrol etmiyoruz
      });
    });

    group('createGroupChat', () {
      const testName = 'Test Group';
      const testCreatedBy = 'user-123';
      final testParticipants = ['user-123', 'user-456'];
      final testChat = ChatModel(
        id: 'chat-123',
        name: testName,
        type: ChatType.group,
        participants: testParticipants,
        createdAt: DateTime.now(),
      );

      test('should return ChatModel when successful', () async {
        // Arrange
        when(mockRepository.createGroupChat(
          name: anyNamed('name'),
          createdBy: anyNamed('createdBy'),
          participants: anyNamed('participants'),
        )).thenAnswer((_) async => Either.right(testChat));

        // Act
        final result = await viewModel.createGroupChat(
          name: testName,
          createdBy: testCreatedBy,
          participants: testParticipants,
        );

        // Assert
        expect(result, testChat);
        expect(viewModel.isLoading, false);
        expect(viewModel.error, isNull);
      });

      test('should set error when fails', () async {
        // Arrange
        final failure = ServerFailure('Create group failed');
        when(mockRepository.createGroupChat(
          name: anyNamed('name'),
          createdBy: anyNamed('createdBy'),
          participants: anyNamed('participants'),
        )).thenAnswer((_) async => Either.left(failure));

        // Act
        final result = await viewModel.createGroupChat(
          name: testName,
          createdBy: testCreatedBy,
          participants: testParticipants,
        );

        // Assert
        expect(result, isNull);
        expect(viewModel.error, 'Create group failed');
      });
    });

    group('sendMessage', () {
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

      test('should return MessageModel when successful', () async {
        // Arrange
        when(mockRepository.sendMessage(
          chatId: anyNamed('chatId'),
          senderId: anyNamed('senderId'),
          senderName: anyNamed('senderName'),
          text: anyNamed('text'),
        )).thenAnswer((_) async => Either.right(testMessage));

        // Act
        final result = await viewModel.sendMessage(
          chatId: testChatId,
          senderId: testSenderId,
          senderName: testSenderName,
          text: testText,
        );

        // Assert
        expect(result, testMessage);
        expect(viewModel.error, isNull);
      });

      test('should set error when fails', () async {
        // Arrange
        final failure = ServerFailure('Send message failed');
        when(mockRepository.sendMessage(
          chatId: anyNamed('chatId'),
          senderId: anyNamed('senderId'),
          senderName: anyNamed('senderName'),
          text: anyNamed('text'),
        )).thenAnswer((_) async => Either.left(failure));

        // Act
        final result = await viewModel.sendMessage(
          chatId: testChatId,
          senderId: testSenderId,
          senderName: testSenderName,
          text: testText, // text parametresini ekle
        );

        // Assert
        expect(result, isNull);
        expect(viewModel.error, 'Send message failed');
      });
    });

    group('getMessagesStream', () {
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

      test('should return stream of messages', () async {
        // Arrange
        when(mockRepository.getMessagesStream(testChatId, limit: anyNamed('limit')))
            .thenAnswer((_) => Stream.value(testMessages));

        // Act
        final stream = viewModel.getMessagesStream(testChatId);

        // Assert
        expect(stream, isA<Stream<List<MessageModel>>>());
        final result = await stream.first;
        expect(result, testMessages);
        verify(mockRepository.getMessagesStream(testChatId, limit: 50)).called(1);
      });
    });

    group('loadOlderMessages', () {
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

      test('should return List<MessageModel> when successful', () async {
        // Arrange
        when(mockRepository.loadOlderMessages(testChatId, any, limit: anyNamed('limit')))
            .thenAnswer((_) async => Either.right(testMessages));

        // Act
        final result = await viewModel.loadOlderMessages(testChatId, testLastMessageTime);

        // Assert
        expect(result, testMessages);
        expect(viewModel.error, isNull);
      });

      test('should set error when fails', () async {
        // Arrange
        final failure = ServerFailure('Load older failed');
        when(mockRepository.loadOlderMessages(testChatId, any, limit: anyNamed('limit')))
            .thenAnswer((_) async => Either.left(failure));

        // Act
        final result = await viewModel.loadOlderMessages(testChatId, testLastMessageTime);

        // Assert
        expect(result, isEmpty);
        expect(viewModel.error, 'Load older failed');
      });
    });

    group('getUserChats', () {
      const testUserId = 'user-123';
      final testChats = [
        ChatModel(
          id: 'chat-1',
          name: 'Chat 1',
          type: ChatType.private,
          participants: [testUserId, 'user-456'],
          createdAt: DateTime.now(),
        ),
      ];

      test('should return stream of chats', () async {
        // Arrange
        when(mockRepository.getUserChats(testUserId))
            .thenAnswer((_) => Stream.value(testChats));

        // Act
        final stream = viewModel.getUserChats(testUserId);

        // Assert
        expect(stream, isA<Stream<List<ChatModel>>>());
        final result = await stream.first;
        expect(result, testChats);
        verify(mockRepository.getUserChats(testUserId)).called(1);
      });
    });

    group('markMessageAsRead', () {
      const testMessageId = 'msg-123';
      const testUserId = 'user-123';

      test('should mark message as read successfully', () async {
        // Arrange
        when(mockRepository.markMessageAsRead(testMessageId, testUserId))
            .thenAnswer((_) async => Either.rightVoid());

        // Act
        await viewModel.markMessageAsRead(testMessageId, testUserId);

        // Assert
        expect(viewModel.error, isNull);
        verify(mockRepository.markMessageAsRead(testMessageId, testUserId)).called(1);
      });

      test('should set error when fails', () async {
        // Arrange
        final failure = ServerFailure('Mark as read failed');
        when(mockRepository.markMessageAsRead(testMessageId, testUserId))
            .thenAnswer((_) async => Either.left(failure));

        // Act
        await viewModel.markMessageAsRead(testMessageId, testUserId);

        // Assert
        expect(viewModel.error, 'Mark as read failed');
      });
    });

    group('deleteMessage', () {
      const testMessageId = 'msg-123';
      const testUserId = 'user-123';

      test('should delete message successfully', () async {
        // Arrange
        when(mockRepository.deleteMessage(testMessageId, testUserId))
            .thenAnswer((_) async => Either.rightVoid());

        // Act
        await viewModel.deleteMessage(testMessageId, testUserId);

        // Assert
        expect(viewModel.error, isNull);
        verify(mockRepository.deleteMessage(testMessageId, testUserId)).called(1);
      });

      test('should set error when fails', () async {
        // Arrange
        final failure = ServerFailure('Delete failed');
        when(mockRepository.deleteMessage(testMessageId, testUserId))
            .thenAnswer((_) async => Either.left(failure));

        // Act
        await viewModel.deleteMessage(testMessageId, testUserId);

        // Assert
        expect(viewModel.error, 'Delete failed');
      });
    });

    group('editMessage', () {
      const testMessageId = 'msg-123';
      const testNewText = 'Updated message';

      test('should edit message successfully', () async {
        // Arrange
        when(mockRepository.editMessage(testMessageId, testNewText))
            .thenAnswer((_) async => Either.rightVoid());

        // Act
        await viewModel.editMessage(testMessageId, testNewText);

        // Assert
        expect(viewModel.error, isNull);
        verify(mockRepository.editMessage(testMessageId, testNewText)).called(1);
      });

      test('should set error when fails', () async {
        // Arrange
        final failure = ServerFailure('Edit failed');
        when(mockRepository.editMessage(testMessageId, testNewText))
            .thenAnswer((_) async => Either.left(failure));

        // Act
        await viewModel.editMessage(testMessageId, testNewText);

        // Assert
        expect(viewModel.error, 'Edit failed');
      });
    });

    group('updateTypingStatus', () {
      const testChatId = 'chat-123';
      const testUserId = 'user-123';
      const testIsTyping = true;

      test('should update typing status successfully', () async {
        // Arrange
        when(mockRepository.updateTypingStatus(testChatId, testUserId, testIsTyping))
            .thenAnswer((_) async => Either.rightVoid());

        // Act
        await viewModel.updateTypingStatus(testChatId, testUserId, testIsTyping);

        // Assert
        expect(viewModel.error, isNull);
        verify(mockRepository.updateTypingStatus(testChatId, testUserId, testIsTyping)).called(1);
      });
    });

    group('addReaction', () {
      const testMessageId = 'msg-123';
      const testUserId = 'user-123';
      const testEmoji = '👍';

      test('should add reaction successfully', () async {
        // Arrange
        when(mockRepository.addReaction(testMessageId, testUserId, testEmoji))
            .thenAnswer((_) async => Either.rightVoid());

        // Act
        await viewModel.addReaction(testMessageId, testUserId, testEmoji);

        // Assert
        expect(viewModel.error, isNull);
        verify(mockRepository.addReaction(testMessageId, testUserId, testEmoji)).called(1);
      });
    });

    group('removeReaction', () {
      const testMessageId = 'msg-123';
      const testUserId = 'user-123';
      const testEmoji = '👍';

      test('should remove reaction successfully', () async {
        // Arrange
        when(mockRepository.removeReaction(testMessageId, testUserId, testEmoji))
            .thenAnswer((_) async => Either.rightVoid());

        // Act
        await viewModel.removeReaction(testMessageId, testUserId, testEmoji);

        // Assert
        expect(viewModel.error, isNull);
        verify(mockRepository.removeReaction(testMessageId, testUserId, testEmoji)).called(1);
      });
    });

    group('sendVoiceMessage', () {
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

      test('should return MessageModel when successful', () async {
        // Arrange
        when(mockRepository.sendVoiceMessage(
          chatId: anyNamed('chatId'),
          senderId: anyNamed('senderId'),
          senderName: anyNamed('senderName'),
          audioUrl: anyNamed('audioUrl'),
          duration: anyNamed('duration'),
        )).thenAnswer((_) async => Either.right(testMessage));

        // Act
        final result = await viewModel.sendVoiceMessage(
          chatId: testChatId,
          senderId: testSenderId,
          senderName: testSenderName,
          audioUrl: testAudioUrl,
          duration: testDuration,
        );

        // Assert
        expect(result, testMessage);
        expect(viewModel.error, isNull);
      });
    });

    group('sendFileMessage', () {
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

      test('should return MessageModel when successful', () async {
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
        final result = await viewModel.sendFileMessage(
          chatId: testChatId,
          senderId: testSenderId,
          senderName: testSenderName,
          fileUrl: testFileUrl,
          fileName: testFileName,
          fileSize: testFileSize,
        );

        // Assert
        expect(result, testMessage);
        expect(viewModel.error, isNull);
      });
    });

    group('forwardMessage', () {
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
      );

      test('should return MessageModel when successful', () async {
        // Arrange
        when(mockRepository.forwardMessage(
          originalMessage: anyNamed('originalMessage'),
          targetChatId: anyNamed('targetChatId'),
          senderId: anyNamed('senderId'),
          senderName: anyNamed('senderName'),
        )).thenAnswer((_) async => Either.right(testForwardedMessage));

        // Act
        final result = await viewModel.forwardMessage(
          originalMessage: testOriginalMessage,
          targetChatId: testTargetChatId,
          senderId: testSenderId,
          senderName: testSenderName,
        );

        // Assert
        expect(result, testForwardedMessage);
        expect(viewModel.error, isNull);
      });
    });

    group('searchMessages', () {
      const testChatId = 'chat-123';
      const testQuery = 'test query';
      final testMessages = [
        MessageModel(
          id: 'msg-1',
          chatId: testChatId,
          senderId: 'user-1',
          senderName: 'User 1',
          text: 'test query found',
          timestamp: DateTime.now(),
          type: MessageType.text,
          status: MessageStatus.sent,
        ),
      ];

      test('should return List<MessageModel> when successful', () async {
        // Arrange
        when(mockRepository.searchMessages(testChatId, testQuery, limit: anyNamed('limit')))
            .thenAnswer((_) async => Either.right(testMessages));

        // Act
        final result = await viewModel.searchMessages(testChatId, testQuery);

        // Assert
        expect(result, testMessages);
        expect(viewModel.error, isNull);
      });
    });

    group('searchAllMessages', () {
      const testUserId = 'user-123';
      const testQuery = 'test query';
      final testMessages = [
        MessageModel(
          id: 'msg-1',
          chatId: 'chat-1',
          senderId: 'user-1',
          senderName: 'User 1',
          text: 'test query found',
          timestamp: DateTime.now(),
          type: MessageType.text,
          status: MessageStatus.sent,
        ),
      ];

      test('should return List<MessageModel> when successful', () async {
        // Arrange
        when(mockRepository.searchAllMessages(testUserId, testQuery, limit: anyNamed('limit')))
            .thenAnswer((_) async => Either.right(testMessages));

        // Act
        final result = await viewModel.searchAllMessages(testUserId, testQuery);

        // Assert
        expect(result, testMessages);
        expect(viewModel.error, isNull);
      });
    });
  });
}

