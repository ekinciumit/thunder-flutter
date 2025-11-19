import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:thunder/models/message_model.dart';

void main() {
  group('MessageModel', () {
    final testDatetime = DateTime.now();

    test('should create MessageModel with all fields', () {
      // Arrange & Act
      final message = MessageModel(
        id: 'msg-123',
        chatId: 'chat-123',
        senderId: 'user-123',
        senderName: 'Test User',
        senderPhotoUrl: 'https://example.com/photo.jpg',
        text: 'Test message',
        type: MessageType.text,
        status: MessageStatus.sent,
        timestamp: testDatetime,
        readAt: testDatetime,
        imageUrl: 'https://example.com/image.jpg',
        videoUrl: 'https://example.com/video.mp4',
        audioUrl: 'https://example.com/audio.m4a',
        fileUrl: 'https://example.com/file.pdf',
        fileName: 'document.pdf',
        fileSize: 1024,
        gifUrl: 'https://example.com/gif.gif',
        stickerUrl: 'https://example.com/sticker.png',
        location: {'lat': 41.0082, 'lng': 28.9784},
        contact: {'name': 'John Doe', 'phone': '+1234567890'},
        replyToMessageId: 'msg-456',
        forwardFromUserId: 'user-456',
        forwardFromUserName: 'Forward User',
        reactions: {'user-1': ['👍', '❤️']},
        isEdited: true,
        editedAt: testDatetime,
        isDeleted: false,
        isPinned: true,
        pinnedAt: testDatetime,
        metadata: {'key': 'value'},
      );

      // Assert
      expect(message.id, 'msg-123');
      expect(message.chatId, 'chat-123');
      expect(message.senderId, 'user-123');
      expect(message.text, 'Test message');
      expect(message.type, MessageType.text);
      expect(message.status, MessageStatus.sent);
      expect(message.imageUrl, 'https://example.com/image.jpg');
      expect(message.reactions, {'user-1': ['👍', '❤️']});
      expect(message.isEdited, true);
      expect(message.isPinned, true);
    });

    test('should create MessageModel with minimal fields', () {
      // Arrange & Act
      final message = MessageModel(
        id: 'msg-123',
        chatId: 'chat-123',
        senderId: 'user-123',
        senderName: 'Test User',
        text: 'Test message',
        type: MessageType.text,
        status: MessageStatus.sent,
        timestamp: testDatetime,
      );

      // Assert
      expect(message.id, 'msg-123');
      expect(message.chatId, 'chat-123');
      expect(message.text, 'Test message');
      expect(message.senderPhotoUrl, isNull);
      expect(message.readAt, isNull);
      expect(message.imageUrl, isNull);
      expect(message.reactions, isEmpty);
      expect(message.isEdited, false);
      expect(message.isDeleted, false);
      expect(message.isPinned, false);
    });

    group('fromMap', () {
      test('should create MessageModel from map with all fields', () {
        // Arrange
        const id = 'msg-123';
        final map = {
          'chatId': 'chat-123',
          'senderId': 'user-123',
          'senderName': 'Test User',
          'senderPhotoUrl': 'https://example.com/photo.jpg',
          'text': 'Test message',
          'type': 'text',
          'status': 'sent',
          'timestamp': Timestamp.fromDate(testDatetime),
          'readAt': Timestamp.fromDate(testDatetime),
          'imageUrl': 'https://example.com/image.jpg',
          'audioUrl': 'https://example.com/audio.m4a',
          'reactions': {'user-1': ['👍', '❤️']},
          'isEdited': true,
          'editedAt': Timestamp.fromDate(testDatetime),
          'isDeleted': false,
          'isPinned': true,
          'pinnedAt': Timestamp.fromDate(testDatetime),
        };

        // Act
        final message = MessageModel.fromMap(map, id);

        // Assert
        expect(message.id, id);
        expect(message.chatId, map['chatId']);
        expect(message.senderId, map['senderId']);
        expect(message.text, map['text']);
        expect(message.type, MessageType.text);
        expect(message.status, MessageStatus.sent);
        expect(message.imageUrl, map['imageUrl']);
        expect(message.reactions['user-1'], ['👍', '❤️']);
        expect(message.isEdited, true);
        expect(message.isPinned, true);
      });

      test('should create MessageModel from map with minimal fields', () {
        // Arrange
        const id = 'msg-123';
        final map = {
          'chatId': 'chat-123',
          'senderId': 'user-123',
          'senderName': 'Test User',
          'text': 'Test message',
          'type': 'text',
          'status': 'sent',
          'timestamp': Timestamp.fromDate(testDatetime),
        };

        // Act
        final message = MessageModel.fromMap(map, id);

        // Assert
        expect(message.id, id);
        expect(message.chatId, map['chatId']);
        expect(message.text, map['text']);
        expect(message.reactions, isEmpty);
        expect(message.isEdited, false);
        expect(message.isDeleted, false);
      });

      test('should handle invalid type with default', () {
        // Arrange
        const id = 'msg-123';
        final map = {
          'chatId': 'chat-123',
          'senderId': 'user-123',
          'senderName': 'Test User',
          'text': 'Test message',
          'type': 'invalid_type',
          'status': 'sent',
          'timestamp': Timestamp.fromDate(testDatetime),
        };

        // Act
        final message = MessageModel.fromMap(map, id);

        // Assert
        expect(message.type, MessageType.text);
      });

      test('should handle invalid status with default', () {
        // Arrange
        const id = 'msg-123';
        final map = {
          'chatId': 'chat-123',
          'senderId': 'user-123',
          'senderName': 'Test User',
          'text': 'Test message',
          'type': 'text',
          'status': 'invalid_status',
          'timestamp': Timestamp.fromDate(testDatetime),
        };

        // Act
        final message = MessageModel.fromMap(map, id);

        // Assert
        expect(message.status, MessageStatus.sent);
      });

      test('should parse reactions correctly', () {
        // Arrange
        const id = 'msg-123';
        final map = {
          'chatId': 'chat-123',
          'senderId': 'user-123',
          'senderName': 'Test User',
          'text': 'Test message',
          'type': 'text',
          'status': 'sent',
          'timestamp': Timestamp.fromDate(testDatetime),
          'reactions': {
            'user-1': ['👍', '❤️'],
            'user-2': ['😂'],
          },
        };

        // Act
        final message = MessageModel.fromMap(map, id);

        // Assert
        expect(message.reactions.length, 2);
        expect(message.reactions['user-1'], ['👍', '❤️']);
        expect(message.reactions['user-2'], ['😂']);
      });

      test('should handle empty reactions', () {
        // Arrange
        const id = 'msg-123';
        final map = {
          'chatId': 'chat-123',
          'senderId': 'user-123',
          'senderName': 'Test User',
          'text': 'Test message',
          'type': 'text',
          'status': 'sent',
          'timestamp': Timestamp.fromDate(testDatetime),
          'reactions': null,
        };

        // Act
        final message = MessageModel.fromMap(map, id);

        // Assert
        expect(message.reactions, isEmpty);
      });
    });

    group('toMap', () {
      test('should convert MessageModel to map with all fields', () {
        // Arrange
        final message = MessageModel(
          id: 'msg-123',
          chatId: 'chat-123',
          senderId: 'user-123',
          senderName: 'Test User',
          text: 'Test message',
          type: MessageType.image,
          status: MessageStatus.read,
          timestamp: testDatetime,
          readAt: testDatetime,
          imageUrl: 'https://example.com/image.jpg',
          reactions: {'user-1': ['👍']},
          isEdited: true,
          editedAt: testDatetime,
          isDeleted: false,
          isPinned: true,
          pinnedAt: testDatetime,
        );

        // Act
        final map = message.toMap();

        // Assert
        expect(map['chatId'], message.chatId);
        expect(map['senderId'], message.senderId);
        expect(map['text'], message.text);
        expect(map['type'], 'image');
        expect(map['status'], 'read');
        expect(map['imageUrl'], message.imageUrl);
        expect(map['reactions'], message.reactions);
        expect(map['isEdited'], true);
        expect(map['isPinned'], true);
      });

      test('should round-trip correctly (fromMap -> toMap -> fromMap)', () {
        // Arrange
        const id = 'msg-123';
        final originalMap = {
          'chatId': 'chat-123',
          'senderId': 'user-123',
          'senderName': 'Test User',
          'text': 'Test message',
          'type': 'text',
          'status': 'sent',
          'timestamp': Timestamp.fromDate(testDatetime),
          'reactions': {'user-1': ['👍', '❤️']},
          'isEdited': true,
          'editedAt': Timestamp.fromDate(testDatetime),
          'isDeleted': false,
          'isPinned': true,
          'pinnedAt': Timestamp.fromDate(testDatetime),
        };

        // Act
        final message = MessageModel.fromMap(originalMap, id);
        final map = message.toMap();
        final roundTripMessage = MessageModel.fromMap(map, id);

        // Assert
        expect(roundTripMessage.id, id);
        expect(roundTripMessage.chatId, message.chatId);
        expect(roundTripMessage.senderId, message.senderId);
        expect(roundTripMessage.text, message.text);
        expect(roundTripMessage.type, message.type);
        expect(roundTripMessage.status, message.status);
        expect(roundTripMessage.reactions, message.reactions);
        expect(roundTripMessage.isEdited, message.isEdited);
        expect(roundTripMessage.isPinned, message.isPinned);
      });
    });

    group('copyWith', () {
      test('should copy MessageModel with updated fields', () {
        // Arrange
        final original = MessageModel(
          id: 'msg-123',
          chatId: 'chat-123',
          senderId: 'user-123',
          senderName: 'Test User',
          text: 'Original text',
          type: MessageType.text,
          status: MessageStatus.sent,
          timestamp: testDatetime,
        );

        // Act
        final copied = original.copyWith(
          text: 'Edited text',
          status: MessageStatus.read,
          isEdited: true,
          editedAt: testDatetime,
        );

        // Assert
        expect(copied.id, original.id);
        expect(copied.chatId, original.chatId);
        expect(copied.text, 'Edited text');
        expect(copied.status, MessageStatus.read);
        expect(copied.isEdited, true);
        expect(copied.type, original.type);
      });

      test('should copy MessageModel without changes when no parameters', () {
        // Arrange
        final original = MessageModel(
          id: 'msg-123',
          chatId: 'chat-123',
          senderId: 'user-123',
          senderName: 'Test User',
          text: 'Test message',
          type: MessageType.text,
          status: MessageStatus.sent,
          timestamp: testDatetime,
        );

        // Act
        final copied = original.copyWith();

        // Assert
        expect(copied.id, original.id);
        expect(copied.chatId, original.chatId);
        expect(copied.text, original.text);
        expect(copied.type, original.type);
        expect(copied.status, original.status);
      });

      test('should update all fields with copyWith', () {
        // Arrange
        final original = MessageModel(
          id: 'msg-123',
          chatId: 'chat-123',
          senderId: 'user-123',
          senderName: 'Old User',
          text: 'Old text',
          type: MessageType.text,
          status: MessageStatus.sent,
          timestamp: testDatetime,
        );

        final newDatetime = DateTime.now().add(const Duration(days: 1));

        // Act
        final copied = original.copyWith(
          id: 'msg-456',
          chatId: 'chat-456',
          senderId: 'user-456',
          senderName: 'New User',
          text: 'New text',
          type: MessageType.image,
          status: MessageStatus.read,
          timestamp: newDatetime,
          readAt: newDatetime,
          imageUrl: 'https://new.com/image.jpg',
          reactions: {'user-2': ['👍']},
          isEdited: true,
          editedAt: newDatetime,
          isDeleted: true,
          isPinned: true,
        );

        // Assert
        expect(copied.id, 'msg-456');
        expect(copied.chatId, 'chat-456');
        expect(copied.senderId, 'user-456');
        expect(copied.senderName, 'New User');
        expect(copied.text, 'New text');
        expect(copied.type, MessageType.image);
        expect(copied.status, MessageStatus.read);
        expect(copied.imageUrl, 'https://new.com/image.jpg');
        expect(copied.isEdited, true);
        expect(copied.isDeleted, true);
        expect(copied.isPinned, true);
      });

      test('should preserve original value when null is passed to copyWith', () {
        // Arrange
        final original = MessageModel(
          id: 'msg-123',
          chatId: 'chat-123',
          senderId: 'user-123',
          senderName: 'Test User',
          text: 'Test message',
          type: MessageType.text,
          status: MessageStatus.sent,
          timestamp: testDatetime,
          imageUrl: 'https://old.com/image.jpg',
        );

        // Act
        final copied = original.copyWith(
          text: null,
          imageUrl: null,
        );

        // Assert - copyWith preserves original value when null is passed
        // This is standard Dart copyWith behavior (null means "don't change")
        expect(copied.text, original.text);
        expect(copied.imageUrl, original.imageUrl);
      });
    });

    group('equality', () {
      test('should be equal when ids are same', () {
        // Arrange
        final message1 = MessageModel(
          id: 'msg-123',
          chatId: 'chat-123',
          senderId: 'user-123',
          senderName: 'Test User',
          text: 'Test message',
          type: MessageType.text,
          status: MessageStatus.sent,
          timestamp: testDatetime,
        );

        final message2 = MessageModel(
          id: 'msg-123',
          chatId: 'chat-456',
          senderId: 'user-456',
          senderName: 'Different User',
          text: 'Different text',
          type: MessageType.image,
          status: MessageStatus.read,
          timestamp: DateTime.now(),
        );

        // Assert
        expect(message1 == message2, true);
        expect(message1.hashCode, message2.hashCode);
      });

      test('should not be equal when ids are different', () {
        // Arrange
        final message1 = MessageModel(
          id: 'msg-123',
          chatId: 'chat-123',
          senderId: 'user-123',
          senderName: 'Test User',
          text: 'Test message',
          type: MessageType.text,
          status: MessageStatus.sent,
          timestamp: testDatetime,
        );

        final message2 = MessageModel(
          id: 'msg-456',
          chatId: 'chat-123',
          senderId: 'user-123',
          senderName: 'Test User',
          text: 'Test message',
          type: MessageType.text,
          status: MessageStatus.sent,
          timestamp: testDatetime,
        );

        // Assert
        expect(message1 == message2, false);
      });
    });
  });
}

