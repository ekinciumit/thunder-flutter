import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:thunder/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:thunder/features/chat/data/datasources/chat_remote_data_source.dart';
import 'package:thunder/models/chat_model.dart';
import 'package:thunder/models/message_model.dart';
import 'package:thunder/core/errors/exceptions.dart';
import 'package:thunder/core/errors/failures.dart';

import 'chat_repository_impl_test.mocks.dart';

/// Mock classes için annotation
@GenerateMocks([ChatRemoteDataSource])
void main() {
  late ChatRepositoryImpl repository;
  late MockChatRemoteDataSource mockRemoteDataSource;

  setUp(() {
    mockRemoteDataSource = MockChatRemoteDataSource();
    repository = ChatRepositoryImpl(remoteDataSource: mockRemoteDataSource);
  });

  group('ChatRepositoryImpl', () {
    group('getChatId', () {
      const testUserA = 'user-a';
      const testUserB = 'user-b';
      const testChatId = 'chat-123';

      test('should return chatId from remote data source', () {
        // Arrange
        when(mockRemoteDataSource.getChatId(testUserA, testUserB))
            .thenReturn(testChatId);

        // Act
        final result = repository.getChatId(testUserA, testUserB);

        // Assert
        expect(result, testChatId);
        verify(mockRemoteDataSource.getChatId(testUserA, testUserB)).called(1);
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

      test('should return Right(ChatModel) when successful', () async {
        // Arrange
        when(mockRemoteDataSource.getOrCreatePrivateChat(testUserA, testUserB))
            .thenAnswer((_) async => testChat);

        // Act
        final result = await repository.getOrCreatePrivateChat(testUserA, testUserB);

        // Assert
        expect(result.isRight, true);
        expect(result.right, testChat);
        verify(mockRemoteDataSource.getOrCreatePrivateChat(testUserA, testUserB)).called(1);
      });

      test('should return Left(ServerFailure) when ServerException is thrown', () async {
        // Arrange
        when(mockRemoteDataSource.getOrCreatePrivateChat(testUserA, testUserB))
            .thenThrow(ServerException('Server error'));

        // Act
        final result = await repository.getOrCreatePrivateChat(testUserA, testUserB);

        // Assert
        expect(result.isLeft, true);
        expect(result.left, isA<ServerFailure>());
        expect(result.left.message, 'Server error');
      });

      test('should return Left(UnknownFailure) when unknown exception is thrown', () async {
        // Arrange
        when(mockRemoteDataSource.getOrCreatePrivateChat(testUserA, testUserB))
            .thenThrow(Exception('Unknown error'));

        // Act
        final result = await repository.getOrCreatePrivateChat(testUserA, testUserB);

        // Assert
        expect(result.isLeft, true);
        expect(result.left, isA<UnknownFailure>());
        expect(result.left.message, contains('Özel sohbet oluşturulurken bir hata oluştu'));
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

      test('should return Right(ChatModel) when successful', () async {
        // Arrange
        when(mockRemoteDataSource.createGroupChat(
          name: anyNamed('name'),
          createdBy: anyNamed('createdBy'),
          participants: anyNamed('participants'),
        )).thenAnswer((_) async => testChat);

        // Act
        final result = await repository.createGroupChat(
          name: testName,
          createdBy: testCreatedBy,
          participants: testParticipants,
        );

        // Assert
        expect(result.isRight, true);
        expect(result.right, testChat);
        verify(mockRemoteDataSource.createGroupChat(
          name: testName,
          createdBy: testCreatedBy,
          participants: testParticipants,
        )).called(1);
      });

      test('should return Left(ServerFailure) when ServerException is thrown', () async {
        // Arrange
        when(mockRemoteDataSource.createGroupChat(
          name: anyNamed('name'),
          createdBy: anyNamed('createdBy'),
          participants: anyNamed('participants'),
        )).thenThrow(ServerException('Create failed'));

        // Act
        final result = await repository.createGroupChat(
          name: testName,
          createdBy: testCreatedBy,
          participants: testParticipants,
        );

        // Assert
        expect(result.isLeft, true);
        expect(result.left, isA<ServerFailure>());
        expect(result.left.message, 'Create failed');
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

      test('should return Right(MessageModel) when successful', () async {
        // Arrange
        when(mockRemoteDataSource.sendMessage(
          chatId: anyNamed('chatId'),
          senderId: anyNamed('senderId'),
          senderName: anyNamed('senderName'),
          text: anyNamed('text'),
        )).thenAnswer((_) async => testMessage);

        // Act
        final result = await repository.sendMessage(
          chatId: testChatId,
          senderId: testSenderId,
          senderName: testSenderName,
          text: testText,
        );

        // Assert
        expect(result.isRight, true);
        expect(result.right, testMessage);
        verify(mockRemoteDataSource.sendMessage(
          chatId: testChatId,
          senderId: testSenderId,
          senderName: testSenderName,
          text: testText,
          type: MessageType.text,
        )).called(1);
      });

      test('should return Left(ServerFailure) when ServerException is thrown', () async {
        // Arrange
        when(mockRemoteDataSource.sendMessage(
          chatId: anyNamed('chatId'),
          senderId: anyNamed('senderId'),
          senderName: anyNamed('senderName'),
        )).thenThrow(ServerException('Send failed'));

        // Act
        final result = await repository.sendMessage(
          chatId: testChatId,
          senderId: testSenderId,
          senderName: testSenderName,
        );

        // Assert
        expect(result.isLeft, true);
        expect(result.left, isA<ServerFailure>());
        expect(result.left.message, 'Send failed');
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

      test('should return stream of messages when successful', () async {
        // Arrange
        when(mockRemoteDataSource.getMessagesStream(testChatId, limit: anyNamed('limit')))
            .thenAnswer((_) => Stream.value(testMessages));

        // Act
        final stream = repository.getMessagesStream(testChatId);

        // Assert
        expect(stream, isA<Stream<List<MessageModel>>>());
        final result = await stream.first;
        expect(result, testMessages);
        verify(mockRemoteDataSource.getMessagesStream(testChatId, limit: 50)).called(1);
      });

      test('should return empty stream when exception is thrown', () async {
        // Arrange
        when(mockRemoteDataSource.getMessagesStream(testChatId, limit: anyNamed('limit')))
            .thenThrow(Exception('Error'));

        // Act
        final stream = repository.getMessagesStream(testChatId);

        // Assert
        final result = await stream.first;
        expect(result, isEmpty);
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

      test('should return Right(List<MessageModel>) when successful', () async {
        // Arrange
        when(mockRemoteDataSource.loadOlderMessages(testChatId, any, limit: anyNamed('limit')))
            .thenAnswer((_) async => testMessages);

        // Act
        final result = await repository.loadOlderMessages(testChatId, testLastMessageTime);

        // Assert
        expect(result.isRight, true);
        expect(result.right, testMessages);
        verify(mockRemoteDataSource.loadOlderMessages(testChatId, testLastMessageTime, limit: 20)).called(1);
      });

      test('should return Left(ServerFailure) when ServerException is thrown', () async {
        // Arrange
        when(mockRemoteDataSource.loadOlderMessages(testChatId, any, limit: anyNamed('limit')))
            .thenThrow(ServerException('Load failed'));

        // Act
        final result = await repository.loadOlderMessages(testChatId, testLastMessageTime);

        // Assert
        expect(result.isLeft, true);
        expect(result.left, isA<ServerFailure>());
        expect(result.left.message, 'Load failed');
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

      test('should return stream of chats when successful', () async {
        // Arrange
        when(mockRemoteDataSource.getUserChats(testUserId))
            .thenAnswer((_) => Stream.value(testChats));

        // Act
        final stream = repository.getUserChats(testUserId);

        // Assert
        expect(stream, isA<Stream<List<ChatModel>>>());
        final result = await stream.first;
        expect(result, testChats);
        verify(mockRemoteDataSource.getUserChats(testUserId)).called(1);
      });

      test('should return empty stream when exception is thrown', () async {
        // Arrange
        when(mockRemoteDataSource.getUserChats(testUserId))
            .thenThrow(Exception('Error'));

        // Act
        final stream = repository.getUserChats(testUserId);

        // Assert
        final result = await stream.first;
        expect(result, isEmpty);
      });
    });

    group('markMessageAsRead', () {
      const testMessageId = 'msg-123';
      const testUserId = 'user-123';

      test('should return Right(void) when successful', () async {
        // Arrange
        when(mockRemoteDataSource.markMessageAsRead(testMessageId, testUserId))
            .thenAnswer((_) async => Future.value());

        // Act
        final result = await repository.markMessageAsRead(testMessageId, testUserId);

        // Assert
        expect(result.isRight, true);
        verify(mockRemoteDataSource.markMessageAsRead(testMessageId, testUserId)).called(1);
      });

      test('should return Left(ServerFailure) when ServerException is thrown', () async {
        // Arrange
        when(mockRemoteDataSource.markMessageAsRead(testMessageId, testUserId))
            .thenThrow(ServerException('Mark failed'));

        // Act
        final result = await repository.markMessageAsRead(testMessageId, testUserId);

        // Assert
        expect(result.isLeft, true);
        expect(result.left, isA<ServerFailure>());
        expect(result.left.message, 'Mark failed');
      });
    });

    group('deleteMessage', () {
      const testMessageId = 'msg-123';
      const testUserId = 'user-123';

      test('should return Right(void) when successful', () async {
        // Arrange
        when(mockRemoteDataSource.deleteMessage(testMessageId, testUserId))
            .thenAnswer((_) async => Future.value());

        // Act
        final result = await repository.deleteMessage(testMessageId, testUserId);

        // Assert
        expect(result.isRight, true);
        verify(mockRemoteDataSource.deleteMessage(testMessageId, testUserId)).called(1);
      });

      test('should return Left(ServerFailure) when ServerException is thrown', () async {
        // Arrange
        when(mockRemoteDataSource.deleteMessage(testMessageId, testUserId))
            .thenThrow(ServerException('Delete failed'));

        // Act
        final result = await repository.deleteMessage(testMessageId, testUserId);

        // Assert
        expect(result.isLeft, true);
        expect(result.left, isA<ServerFailure>());
        expect(result.left.message, 'Delete failed');
      });
    });

    group('editMessage', () {
      const testMessageId = 'msg-123';
      const testNewText = 'Updated message';

      test('should return Right(void) when successful', () async {
        // Arrange
        when(mockRemoteDataSource.editMessage(testMessageId, testNewText))
            .thenAnswer((_) async => Future.value());

        // Act
        final result = await repository.editMessage(testMessageId, testNewText);

        // Assert
        expect(result.isRight, true);
        verify(mockRemoteDataSource.editMessage(testMessageId, testNewText)).called(1);
      });

      test('should return Left(ServerFailure) when ServerException is thrown', () async {
        // Arrange
        when(mockRemoteDataSource.editMessage(testMessageId, testNewText))
            .thenThrow(ServerException('Edit failed'));

        // Act
        final result = await repository.editMessage(testMessageId, testNewText);

        // Assert
        expect(result.isLeft, true);
        expect(result.left, isA<ServerFailure>());
        expect(result.left.message, 'Edit failed');
      });
    });

    group('updateTypingStatus', () {
      const testChatId = 'chat-123';
      const testUserId = 'user-123';
      const testIsTyping = true;

      test('should return Right(void) when successful', () async {
        // Arrange
        when(mockRemoteDataSource.updateTypingStatus(testChatId, testUserId, testIsTyping))
            .thenAnswer((_) async => Future.value());

        // Act
        final result = await repository.updateTypingStatus(testChatId, testUserId, testIsTyping);

        // Assert
        expect(result.isRight, true);
        verify(mockRemoteDataSource.updateTypingStatus(testChatId, testUserId, testIsTyping)).called(1);
      });

      test('should return Left(ServerFailure) when ServerException is thrown', () async {
        // Arrange
        when(mockRemoteDataSource.updateTypingStatus(testChatId, testUserId, testIsTyping))
            .thenThrow(ServerException('Update failed'));

        // Act
        final result = await repository.updateTypingStatus(testChatId, testUserId, testIsTyping);

        // Assert
        expect(result.isLeft, true);
        expect(result.left, isA<ServerFailure>());
        expect(result.left.message, 'Update failed');
      });
    });

    group('addReaction', () {
      const testMessageId = 'msg-123';
      const testUserId = 'user-123';
      const testEmoji = '👍';

      test('should return Right(void) when successful', () async {
        // Arrange
        when(mockRemoteDataSource.addReaction(testMessageId, testUserId, testEmoji))
            .thenAnswer((_) async => Future.value());

        // Act
        final result = await repository.addReaction(testMessageId, testUserId, testEmoji);

        // Assert
        expect(result.isRight, true);
        verify(mockRemoteDataSource.addReaction(testMessageId, testUserId, testEmoji)).called(1);
      });

      test('should return Left(ServerFailure) when ServerException is thrown', () async {
        // Arrange
        when(mockRemoteDataSource.addReaction(testMessageId, testUserId, testEmoji))
            .thenThrow(ServerException('Add failed'));

        // Act
        final result = await repository.addReaction(testMessageId, testUserId, testEmoji);

        // Assert
        expect(result.isLeft, true);
        expect(result.left, isA<ServerFailure>());
        expect(result.left.message, 'Add failed');
      });
    });

    group('removeReaction', () {
      const testMessageId = 'msg-123';
      const testUserId = 'user-123';
      const testEmoji = '👍';

      test('should return Right(void) when successful', () async {
        // Arrange
        when(mockRemoteDataSource.removeReaction(testMessageId, testUserId, testEmoji))
            .thenAnswer((_) async => Future.value());

        // Act
        final result = await repository.removeReaction(testMessageId, testUserId, testEmoji);

        // Assert
        expect(result.isRight, true);
        verify(mockRemoteDataSource.removeReaction(testMessageId, testUserId, testEmoji)).called(1);
      });

      test('should return Left(ServerFailure) when ServerException is thrown', () async {
        // Arrange
        when(mockRemoteDataSource.removeReaction(testMessageId, testUserId, testEmoji))
            .thenThrow(ServerException('Remove failed'));

        // Act
        final result = await repository.removeReaction(testMessageId, testUserId, testEmoji);

        // Assert
        expect(result.isLeft, true);
        expect(result.left, isA<ServerFailure>());
        expect(result.left.message, 'Remove failed');
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

      test('should return Right(MessageModel) when successful', () async {
        // Arrange
        when(mockRemoteDataSource.sendVoiceMessage(
          chatId: anyNamed('chatId'),
          senderId: anyNamed('senderId'),
          senderName: anyNamed('senderName'),
          audioUrl: anyNamed('audioUrl'),
          duration: anyNamed('duration'),
        )).thenAnswer((_) async => testMessage);

        // Act
        final result = await repository.sendVoiceMessage(
          chatId: testChatId,
          senderId: testSenderId,
          senderName: testSenderName,
          audioUrl: testAudioUrl,
          duration: testDuration,
        );

        // Assert
        expect(result.isRight, true);
        expect(result.right, testMessage);
        verify(mockRemoteDataSource.sendVoiceMessage(
          chatId: testChatId,
          senderId: testSenderId,
          senderName: testSenderName,
          audioUrl: testAudioUrl,
          duration: testDuration,
        )).called(1);
      });

      test('should return Left(ServerFailure) when ServerException is thrown', () async {
        // Arrange
        when(mockRemoteDataSource.sendVoiceMessage(
          chatId: anyNamed('chatId'),
          senderId: anyNamed('senderId'),
          senderName: anyNamed('senderName'),
          audioUrl: anyNamed('audioUrl'),
          duration: anyNamed('duration'),
        )).thenThrow(ServerException('Send voice failed'));

        // Act
        final result = await repository.sendVoiceMessage(
          chatId: testChatId,
          senderId: testSenderId,
          senderName: testSenderName,
          audioUrl: testAudioUrl,
          duration: testDuration,
        );

        // Assert
        expect(result.isLeft, true);
        expect(result.left, isA<ServerFailure>());
        expect(result.left.message, 'Send voice failed');
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

      test('should return Right(MessageModel) when successful', () async {
        // Arrange
        when(mockRemoteDataSource.sendFileMessage(
          chatId: anyNamed('chatId'),
          senderId: anyNamed('senderId'),
          senderName: anyNamed('senderName'),
          fileUrl: anyNamed('fileUrl'),
          fileName: anyNamed('fileName'),
          fileSize: anyNamed('fileSize'),
        )).thenAnswer((_) async => testMessage);

        // Act
        final result = await repository.sendFileMessage(
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
        verify(mockRemoteDataSource.sendFileMessage(
          chatId: testChatId,
          senderId: testSenderId,
          senderName: testSenderName,
          fileUrl: testFileUrl,
          fileName: testFileName,
          fileSize: testFileSize,
        )).called(1);
      });

      test('should return Left(ServerFailure) when ServerException is thrown', () async {
        // Arrange
        when(mockRemoteDataSource.sendFileMessage(
          chatId: anyNamed('chatId'),
          senderId: anyNamed('senderId'),
          senderName: anyNamed('senderName'),
          fileUrl: anyNamed('fileUrl'),
          fileName: anyNamed('fileName'),
          fileSize: anyNamed('fileSize'),
        )).thenThrow(ServerException('Send file failed'));

        // Act
        final result = await repository.sendFileMessage(
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
        expect(result.left.message, 'Send file failed');
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

      test('should return Right(MessageModel) when successful', () async {
        // Arrange
        when(mockRemoteDataSource.forwardMessage(
          originalMessage: anyNamed('originalMessage'),
          targetChatId: anyNamed('targetChatId'),
          senderId: anyNamed('senderId'),
          senderName: anyNamed('senderName'),
        )).thenAnswer((_) async => testForwardedMessage);

        // Act
        final result = await repository.forwardMessage(
          originalMessage: testOriginalMessage,
          targetChatId: testTargetChatId,
          senderId: testSenderId,
          senderName: testSenderName,
        );

        // Assert
        expect(result.isRight, true);
        expect(result.right, testForwardedMessage);
        verify(mockRemoteDataSource.forwardMessage(
          originalMessage: testOriginalMessage,
          targetChatId: testTargetChatId,
          senderId: testSenderId,
          senderName: testSenderName,
        )).called(1);
      });

      test('should return Left(ServerFailure) when ServerException is thrown', () async {
        // Arrange
        when(mockRemoteDataSource.forwardMessage(
          originalMessage: anyNamed('originalMessage'),
          targetChatId: anyNamed('targetChatId'),
          senderId: anyNamed('senderId'),
          senderName: anyNamed('senderName'),
        )).thenThrow(ServerException('Forward failed'));

        // Act
        final result = await repository.forwardMessage(
          originalMessage: testOriginalMessage,
          targetChatId: testTargetChatId,
          senderId: testSenderId,
          senderName: testSenderName,
        );

        // Assert
        expect(result.isLeft, true);
        expect(result.left, isA<ServerFailure>());
        expect(result.left.message, 'Forward failed');
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

      test('should return Right(List<MessageModel>) when successful', () async {
        // Arrange
        when(mockRemoteDataSource.searchMessages(testChatId, testQuery, limit: anyNamed('limit')))
            .thenAnswer((_) async => testMessages);

        // Act
        final result = await repository.searchMessages(testChatId, testQuery);

        // Assert
        expect(result.isRight, true);
        expect(result.right, testMessages);
        verify(mockRemoteDataSource.searchMessages(testChatId, testQuery, limit: 50)).called(1);
      });

      test('should return Left(ServerFailure) when ServerException is thrown', () async {
        // Arrange
        when(mockRemoteDataSource.searchMessages(testChatId, testQuery, limit: anyNamed('limit')))
            .thenThrow(ServerException('Search failed'));

        // Act
        final result = await repository.searchMessages(testChatId, testQuery);

        // Assert
        expect(result.isLeft, true);
        expect(result.left, isA<ServerFailure>());
        expect(result.left.message, 'Search failed');
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

      test('should return Right(List<MessageModel>) when successful', () async {
        // Arrange
        when(mockRemoteDataSource.searchAllMessages(testUserId, testQuery, limit: anyNamed('limit')))
            .thenAnswer((_) async => testMessages);

        // Act
        final result = await repository.searchAllMessages(testUserId, testQuery);

        // Assert
        expect(result.isRight, true);
        expect(result.right, testMessages);
        verify(mockRemoteDataSource.searchAllMessages(testUserId, testQuery, limit: 100)).called(1);
      });

      test('should return Left(ServerFailure) when ServerException is thrown', () async {
        // Arrange
        when(mockRemoteDataSource.searchAllMessages(testUserId, testQuery, limit: anyNamed('limit')))
            .thenThrow(ServerException('Search all failed'));

        // Act
        final result = await repository.searchAllMessages(testUserId, testQuery);

        // Assert
        expect(result.isLeft, true);
        expect(result.left, isA<ServerFailure>());
        expect(result.left.message, 'Search all failed');
      });
    });
  });
}

