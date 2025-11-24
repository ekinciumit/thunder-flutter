import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:thunder/models/chat_model.dart';
import 'package:thunder/models/message_model.dart';

void main() {
  group('ChatModel', () {
    final testDatetime = DateTime.now();

    test('should create ChatModel with all fields', () {
      // Arrange & Act
      final participant = ChatParticipant(
        userId: 'user-1',
        name: 'User 1',
        photoUrl: 'https://example.com/photo.jpg',
        joinedAt: testDatetime,
      );
      final lastMessage = MessageModel(
        id: 'msg-1',
        chatId: 'chat-123',
        senderId: 'user-1',
        senderName: 'User 1',
        text: 'Test message',
        timestamp: testDatetime,
        type: MessageType.text,
        status: MessageStatus.sent,
      );

      final chat = ChatModel(
        id: 'chat-123',
        name: 'Test Chat',
        description: 'Test Description',
        photoUrl: 'https://example.com/photo.jpg',
        type: ChatType.group,
        participants: ['user-1', 'user-2'],
        participantDetails: {'user-1': participant},
        createdBy: 'user-1',
        createdAt: testDatetime,
        lastMessageAt: testDatetime,
        lastMessage: lastMessage,
        unreadCounts: {'user-2': 5},
        lastSeen: {'user-1': testDatetime},
        typingStatus: {'user-2': true},
        admins: ['user-1'],
        moderators: ['user-2'],
        isArchived: false,
        isMuted: false,
        mutedBy: {'user-3': true},
        settings: {'key': 'value'},
        metadata: {'meta': 'data'},
      );

      // Assert
      expect(chat.id, 'chat-123');
      expect(chat.name, 'Test Chat');
      expect(chat.description, 'Test Description');
      expect(chat.photoUrl, 'https://example.com/photo.jpg');
      expect(chat.type, ChatType.group);
      expect(chat.participants, ['user-1', 'user-2']);
      expect(chat.createdBy, 'user-1');
      expect(chat.admins, ['user-1']);
      expect(chat.moderators, ['user-2']);
      expect(chat.lastMessage, lastMessage);
    });

    test('should create ChatModel with minimal fields', () {
      // Arrange & Act
      final chat = ChatModel(
        id: 'chat-123',
        name: 'Test Chat',
        type: ChatType.private,
        participants: ['user-1', 'user-2'],
        createdAt: testDatetime,
      );

      // Assert
      expect(chat.id, 'chat-123');
      expect(chat.name, 'Test Chat');
      expect(chat.type, ChatType.private);
      expect(chat.participants, ['user-1', 'user-2']);
      expect(chat.description, isNull);
      expect(chat.photoUrl, isNull);
      expect(chat.participantDetails, isEmpty);
      expect(chat.createdBy, isNull);
      expect(chat.lastMessageAt, isNull);
      expect(chat.lastMessage, isNull);
      expect(chat.isArchived, false);
      expect(chat.isMuted, false);
    });

    group('fromMap', () {
      test('should create ChatModel from map with all fields', () {
        // Arrange
        const id = 'chat-123';
        final map = {
          'name': 'Test Chat',
          'description': 'Test Description',
          'photoUrl': 'https://example.com/photo.jpg',
          'type': 'group',
          'participants': ['user-1', 'user-2'],
          'participantDetails': {
            'user-1': {
              'userId': 'user-1',
              'name': 'User 1',
              'photoUrl': 'https://example.com/photo.jpg',
              'joinedAt': Timestamp.fromDate(testDatetime),
            },
          },
          'createdBy': 'user-1',
          'createdAt': Timestamp.fromDate(testDatetime),
          'lastMessageAt': Timestamp.fromDate(testDatetime),
          'lastMessage': {
            'chatId': 'chat-123',
            'senderId': 'user-1',
            'senderName': 'User 1',
            'text': 'Test message',
            'timestamp': Timestamp.fromDate(testDatetime),
            'type': 'text',
            'status': 'sent',
          },
          'unreadCounts': {'user-2': 5},
          'lastSeen': {'user-1': Timestamp.fromDate(testDatetime)},
          'typingStatus': {'user-2': true},
          'admins': ['user-1'],
          'moderators': ['user-2'],
          'isArchived': false,
          'isMuted': false,
          'mutedBy': {'user-3': true},
        };

        // Act
        final chat = ChatModel.fromMap(map, id);

        // Assert
        expect(chat.id, id);
        expect(chat.name, map['name']);
        expect(chat.type, ChatType.group);
        expect(chat.participants, map['participants']);
        expect(chat.createdBy, map['createdBy']);
        expect(chat.admins, map['admins']);
        expect(chat.moderators, map['moderators']);
        expect(chat.unreadCounts, map['unreadCounts']);
        expect(chat.isArchived, false);
        expect(chat.isMuted, false);
      });

      test('should create ChatModel from map with minimal fields', () {
        // Arrange
        const id = 'chat-123';
        final map = {
          'name': 'Test Chat',
          'type': 'private',
          'participants': ['user-1', 'user-2'],
          'createdAt': Timestamp.fromDate(testDatetime),
        };

        // Act
        final chat = ChatModel.fromMap(map, id);

        // Assert
        expect(chat.id, id);
        expect(chat.name, map['name']);
        expect(chat.type, ChatType.private);
        expect(chat.participants, map['participants']);
        expect(chat.description, isNull);
        expect(chat.photoUrl, isNull);
        expect(chat.participantDetails, isEmpty);
      });

      test('should handle missing type with default', () {
        // Arrange
        const id = 'chat-123';
        final map = {
          'name': 'Test Chat',
          'participants': ['user-1', 'user-2'],
          'createdAt': Timestamp.fromDate(testDatetime),
        };

        // Act
        final chat = ChatModel.fromMap(map, id);

        // Assert
        expect(chat.type, ChatType.private);
      });

      test('should handle invalid type with default', () {
        // Arrange
        const id = 'chat-123';
        final map = {
          'name': 'Test Chat',
          'type': 'invalid_type',
          'participants': ['user-1', 'user-2'],
          'createdAt': Timestamp.fromDate(testDatetime),
        };

        // Act
        final chat = ChatModel.fromMap(map, id);

        // Assert
        expect(chat.type, ChatType.private);
      });
    });

    group('toMap', () {
      test('should convert ChatModel to map with all fields', () {
        // Arrange
        final participant = ChatParticipant(
          userId: 'user-1',
          name: 'User 1',
          joinedAt: testDatetime,
        );
        final chat = ChatModel(
          id: 'chat-123',
          name: 'Test Chat',
          description: 'Test Description',
          photoUrl: 'https://example.com/photo.jpg',
          type: ChatType.group,
          participants: ['user-1', 'user-2'],
          participantDetails: {'user-1': participant},
          createdBy: 'user-1',
          createdAt: testDatetime,
          lastMessageAt: testDatetime,
          admins: ['user-1'],
          moderators: ['user-2'],
        );

        // Act
        final map = chat.toMap();

        // Assert
        expect(map['name'], chat.name);
        expect(map['description'], chat.description);
        expect(map['photoUrl'], chat.photoUrl);
        expect(map['type'], 'group');
        expect(map['participants'], chat.participants);
        expect(map['createdBy'], chat.createdBy);
        expect(map['admins'], chat.admins);
        expect(map['moderators'], chat.moderators);
        expect((map['createdAt'] as Timestamp).toDate(), chat.createdAt);
      });

      test('should round-trip correctly (fromMap -> toMap -> fromMap)', () {
        // Arrange
        const id = 'chat-123';
        final originalMap = {
          'name': 'Test Chat',
          'type': 'group',
          'participants': ['user-1', 'user-2'],
          'createdBy': 'user-1',
          'createdAt': Timestamp.fromDate(testDatetime),
          'admins': ['user-1'],
          'moderators': ['user-2'],
        };

        // Act
        final chat = ChatModel.fromMap(originalMap, id);
        final map = chat.toMap();
        final roundTripChat = ChatModel.fromMap(map, id);

        // Assert
        expect(roundTripChat.id, id);
        expect(roundTripChat.name, chat.name);
        expect(roundTripChat.type, chat.type);
        expect(roundTripChat.participants, chat.participants);
        expect(roundTripChat.createdBy, chat.createdBy);
        expect(roundTripChat.admins, chat.admins);
        expect(roundTripChat.moderators, chat.moderators);
      });
    });

    group('copyWith', () {
      test('should copy ChatModel with updated fields', () {
        // Arrange
        final original = ChatModel(
          id: 'chat-123',
          name: 'Original Chat',
          type: ChatType.private,
          participants: ['user-1'],
          createdAt: testDatetime,
        );

        // Act
        final copied = original.copyWith(
          name: 'New Chat',
          type: ChatType.group,
          description: 'New Description',
        );

        // Assert
        expect(copied.id, original.id);
        expect(copied.name, 'New Chat');
        expect(copied.type, ChatType.group);
        expect(copied.description, 'New Description');
        expect(copied.participants, original.participants);
        expect(copied.createdAt, original.createdAt);
      });

      test('should copy ChatModel without changes when no parameters', () {
        // Arrange
        final original = ChatModel(
          id: 'chat-123',
          name: 'Test Chat',
          type: ChatType.group,
          participants: ['user-1', 'user-2'],
          createdAt: testDatetime,
        );

        // Act
        final copied = original.copyWith();

        // Assert
        expect(copied.id, original.id);
        expect(copied.name, original.name);
        expect(copied.type, original.type);
        expect(copied.participants, original.participants);
      });

      test('should update all fields with copyWith', () {
        // Arrange
        final original = ChatModel(
          id: 'chat-123',
          name: 'Old Chat',
          type: ChatType.private,
          participants: ['old1'],
          createdAt: testDatetime,
        );

        final newDatetime = DateTime.now().add(const Duration(days: 1));

        // Act
        final copied = original.copyWith(
          id: 'chat-456',
          name: 'New Chat',
          description: 'New Description',
          photoUrl: 'https://new.com/photo.jpg',
          type: ChatType.group,
          participants: ['new1', 'new2'],
          createdBy: 'user-456',
          createdAt: newDatetime,
          lastMessageAt: newDatetime,
          admins: ['new1'],
          moderators: ['new2'],
          isArchived: true,
          isMuted: true,
        );

        // Assert
        expect(copied.id, 'chat-456');
        expect(copied.name, 'New Chat');
        expect(copied.description, 'New Description');
        expect(copied.type, ChatType.group);
        expect(copied.participants, ['new1', 'new2']);
        expect(copied.createdBy, 'user-456');
        expect(copied.isArchived, true);
        expect(copied.isMuted, true);
      });
    });

    group('ChatParticipant', () {
      test('should create ChatParticipant with all fields', () {
        // Arrange & Act
        final participant = ChatParticipant(
          userId: 'user-123',
          name: 'Test User',
          photoUrl: 'https://example.com/photo.jpg',
          joinedAt: testDatetime,
          role: 'admin',
          isActive: true,
          lastSeen: testDatetime,
          metadata: {'key': 'value'},
        );

        // Assert
        expect(participant.userId, 'user-123');
        expect(participant.name, 'Test User');
        expect(participant.photoUrl, 'https://example.com/photo.jpg');
        expect(participant.joinedAt, testDatetime);
        expect(participant.role, 'admin');
        expect(participant.isActive, true);
        expect(participant.lastSeen, testDatetime);
        expect(participant.metadata, {'key': 'value'});
      });

      test('should create ChatParticipant with minimal fields', () {
        // Arrange & Act
        final participant = ChatParticipant(
          userId: 'user-123',
          name: 'Test User',
          joinedAt: testDatetime,
        );

        // Assert
        expect(participant.userId, 'user-123');
        expect(participant.name, 'Test User');
        expect(participant.photoUrl, isNull);
        expect(participant.role, isNull);
        expect(participant.isActive, true);
        expect(participant.lastSeen, isNull);
        expect(participant.metadata, isNull);
      });

      group('fromMap', () {
        test('should create ChatParticipant from map', () {
          // Arrange
          final map = {
            'userId': 'user-123',
            'name': 'Test User',
            'photoUrl': 'https://example.com/photo.jpg',
            'joinedAt': Timestamp.fromDate(testDatetime),
            'role': 'admin',
            'isActive': true,
            'lastSeen': Timestamp.fromDate(testDatetime),
          };

          // Act
          final participant = ChatParticipant.fromMap(map);

          // Assert
          expect(participant.userId, map['userId']);
          expect(participant.name, map['name']);
          expect(participant.photoUrl, map['photoUrl']);
          expect(participant.role, map['role']);
          expect(participant.isActive, map['isActive']);
        });

        test('should handle missing fields with defaults', () {
          // Arrange
          final map = {
            'userId': 'user-123',
            'name': 'Test User',
            'joinedAt': Timestamp.fromDate(testDatetime),
          };

          // Act
          final participant = ChatParticipant.fromMap(map);

          // Assert
          expect(participant.userId, 'user-123');
          expect(participant.name, 'Test User');
          expect(participant.isActive, true);
          expect(participant.photoUrl, isNull);
          expect(participant.role, isNull);
        });
      });

      group('toMap', () {
        test('should convert ChatParticipant to map', () {
          // Arrange
          final participant = ChatParticipant(
            userId: 'user-123',
            name: 'Test User',
            photoUrl: 'https://example.com/photo.jpg',
            joinedAt: testDatetime,
            role: 'admin',
            isActive: true,
            lastSeen: testDatetime,
          );

          // Act
          final map = participant.toMap();

          // Assert
          expect(map['userId'], participant.userId);
          expect(map['name'], participant.name);
          expect(map['photoUrl'], participant.photoUrl);
          expect(map['role'], participant.role);
          expect(map['isActive'], participant.isActive);
          expect((map['joinedAt'] as Timestamp).toDate(), participant.joinedAt);
        });

        test('should round-trip correctly (fromMap -> toMap -> fromMap)', () {
          // Arrange
          final originalMap = {
            'userId': 'user-123',
            'name': 'Test User',
            'photoUrl': 'https://example.com/photo.jpg',
            'joinedAt': Timestamp.fromDate(testDatetime),
            'role': 'admin',
            'isActive': true,
          };

          // Act
          final participant = ChatParticipant.fromMap(originalMap);
          final map = participant.toMap();
          final roundTripParticipant = ChatParticipant.fromMap(map);

          // Assert
          expect(roundTripParticipant.userId, participant.userId);
          expect(roundTripParticipant.name, participant.name);
          expect(roundTripParticipant.photoUrl, participant.photoUrl);
          expect(roundTripParticipant.role, participant.role);
          expect(roundTripParticipant.isActive, participant.isActive);
        });
      });
    });
  });
}

