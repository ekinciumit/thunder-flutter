import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:thunder/features/chat/domain/usecases/get_user_chats_usecase.dart';
import 'package:thunder/features/chat/domain/repositories/chat_repository.dart';
import 'package:thunder/features/chat/domain/entities/chat_entity.dart';

import 'get_user_chats_usecase_test.mocks.dart';

/// Mock classes için annotation
@GenerateMocks([ChatRepository])
void main() {
  late GetUserChatsUseCase useCase;
  late MockChatRepository mockRepository;

  setUp(() {
    mockRepository = MockChatRepository();
    useCase = GetUserChatsUseCase(mockRepository);
  });

  group('GetUserChatsUseCase', () {
    const testUserId = 'user-123';
    final testChats = [
      ChatEntity(
        id: 'chat-1',
        name: 'Chat 1',
        type: ChatType.private,
        participants: [testUserId, 'user-456'],
        createdAt: DateTime.now(),
      ),
    ];

    test('should return Stream<List<ChatEntity>> when stream is successful', () async {
      // Arrange
      final streamController = StreamController<List<ChatEntity>>();
      when(mockRepository.getUserChats(testUserId))
          .thenAnswer((_) => streamController.stream);

      // Act
      final stream = useCase.call(testUserId);
      streamController.add(testChats);

      // Assert
      expect(stream, isA<Stream<List<ChatEntity>>>());
      final result = await stream.first;
      expect(result, testChats);
      verify(mockRepository.getUserChats(testUserId)).called(1);
      
      await streamController.close();
    });

    test('should return empty list when stream emits empty list', () async {
      // Arrange
      final streamController = StreamController<List<ChatEntity>>();
      when(mockRepository.getUserChats(testUserId))
          .thenAnswer((_) => streamController.stream);

      // Act
      final stream = useCase.call(testUserId);
      streamController.add([]);

      // Assert
      final result = await stream.first;
      expect(result, isEmpty);
      verify(mockRepository.getUserChats(testUserId)).called(1);
      
      await streamController.close();
    });
  });
}

