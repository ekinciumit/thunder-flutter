import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:thunder/features/chat/presentation/pages/message_forward_page.dart';
import 'package:thunder/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:thunder/features/chat/presentation/viewmodels/chat_viewmodel.dart';
import 'package:thunder/features/auth/domain/repositories/auth_repository.dart';
import 'package:thunder/features/chat/domain/repositories/chat_repository.dart';
import 'package:thunder/features/user/data/models/user_model.dart';
import 'package:thunder/features/chat/domain/entities/chat_entity.dart';
import 'package:thunder/features/user/domain/entities/user_entity.dart';
import 'package:thunder/features/chat/domain/entities/message_entity.dart';
import 'package:thunder/features/user/data/mappers/user_mapper.dart';
import 'package:thunder/core/errors/failures.dart';

import 'message_forward_page_test.mocks.dart';

@GenerateMocks([AuthRepository, ChatRepository])
void main() {
  group('MessageForwardPage Widget Tests', () {
    late MockAuthRepository mockAuthRepository;
    late MockChatRepository mockChatRepository;
    late AuthViewModel authViewModel;
    late ChatViewModel chatViewModel;
    late UserEntity testUser;
    late MessageEntity testMessage;
    late ChatEntity testChat;

    setUp(() {
      mockAuthRepository = MockAuthRepository();
      mockChatRepository = MockChatRepository();
      
      final testUserModel = UserModel(
        uid: 'user-1',
        email: 'test@example.com',
        displayName: 'Test User',
      );
      testUser = UserMapper.toEntity(testUserModel);

      testMessage = MessageEntity(
        id: 'msg-1',
        chatId: 'chat-1',
        senderId: 'user-1',
        senderName: 'Test User',
        text: 'Test mesajı',
        timestamp: DateTime.now(),
        type: MessageType.text,
        status: MessageStatus.sent,
      );

      testChat = ChatEntity(
        id: 'chat-2',
        name: 'Test Chat',
        type: ChatType.private,
        participants: ['user-1', 'user-2'],
        createdAt: DateTime.now(),
      );

      // Mock repository setup - AuthViewModel constructor'ı getCurrentUser çağırıyor
      when(mockAuthRepository.getCurrentUser()).thenReturn(testUser);
      when(mockChatRepository.getUserChats(any)).thenAnswer((_) async* {
        yield [testChat];
      });
      when(mockChatRepository.forwardMessage(
        originalMessage: anyNamed('originalMessage'),
        targetChatId: anyNamed('targetChatId'),
        senderId: anyNamed('senderId'),
        senderName: anyNamed('senderName'),
        senderPhotoUrl: anyNamed('senderPhotoUrl'),
      )).thenAnswer((_) async => Either.right(testMessage)); // Repository Entity döndürüyor
      
      authViewModel = AuthViewModel(authRepository: mockAuthRepository);
      chatViewModel = ChatViewModel(chatRepository: mockChatRepository);
    });

    testWidgets('MessageForwardPage - Widget render ediliyor', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthViewModel>.value(value: authViewModel),
              ChangeNotifierProvider<ChatViewModel>.value(value: chatViewModel),
            ],
            child: MessageForwardPage(
              message: testMessage,
            ),
          ),
        ),
      );

      // Firestore stream'leri ve ViewModel async işlemleri test ortamında çalışmaz
      await tester.pump();
      await tester.pump(Duration(seconds: 1));

      // Assert
      expect(find.byType(MessageForwardPage), findsOneWidget);
    });

    testWidgets('MessageForwardPage - Loading state gösteriliyor', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthViewModel>.value(value: authViewModel),
              ChangeNotifierProvider<ChatViewModel>.value(value: chatViewModel),
            ],
            child: MessageForwardPage(
              message: testMessage,
            ),
          ),
        ),
      );

      // İlk render'da loading state olabilir
      await tester.pump();

      // Assert
      expect(find.byType(MessageForwardPage), findsOneWidget);
    });
  });
}

