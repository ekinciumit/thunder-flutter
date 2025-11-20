import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:thunder/views/message_search_page.dart';
import 'package:thunder/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:thunder/features/chat/presentation/viewmodels/chat_viewmodel.dart';
import 'package:thunder/features/auth/domain/repositories/auth_repository.dart';
import 'package:thunder/features/chat/domain/repositories/chat_repository.dart';
import 'package:thunder/models/user_model.dart';
import 'package:thunder/models/message_model.dart';
import 'package:thunder/core/errors/failures.dart';

import 'message_search_page_test.mocks.dart';

@GenerateMocks([AuthRepository, ChatRepository])
void main() {
  group('MessageSearchPage Widget Tests', () {
    late MockAuthRepository mockAuthRepository;
    late MockChatRepository mockChatRepository;
    late AuthViewModel authViewModel;
    late ChatViewModel chatViewModel;
    late UserModel testUser;
    late MessageModel testMessage;

    setUp(() {
      mockAuthRepository = MockAuthRepository();
      mockChatRepository = MockChatRepository();
      
      testUser = UserModel(
        uid: 'user-1',
        email: 'test@example.com',
        displayName: 'Test User',
      );

      testMessage = MessageModel(
        id: 'msg-1',
        chatId: 'chat-1',
        senderId: 'user-1',
        senderName: 'Test User',
        text: 'Test mesajı',
        timestamp: DateTime.now(),
        type: MessageType.text,
        status: MessageStatus.sent,
      );

      // Mock repository setup - AuthViewModel constructor'ı getCurrentUser çağırıyor
      when(mockAuthRepository.getCurrentUser()).thenReturn(testUser);
      when(mockChatRepository.searchMessages(any, any)).thenAnswer((_) async => Either.right([testMessage]));
      when(mockChatRepository.searchAllMessages(any, any)).thenAnswer((_) async => Either.right([testMessage]));
      
      authViewModel = AuthViewModel(authRepository: mockAuthRepository);
      chatViewModel = ChatViewModel(chatRepository: mockChatRepository);
    });

    testWidgets('MessageSearchPage - Widget render ediliyor', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthViewModel>.value(value: authViewModel),
              ChangeNotifierProvider<ChatViewModel>.value(value: chatViewModel),
            ],
            child: MessageSearchPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(MessageSearchPage), findsOneWidget);
    });

    testWidgets('MessageSearchPage - Arama alanı görünüyor', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthViewModel>.value(value: authViewModel),
              ChangeNotifierProvider<ChatViewModel>.value(value: chatViewModel),
            ],
            child: MessageSearchPage(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(Duration(seconds: 1));

      // Assert
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('MessageSearchPage - ChatId ile render ediliyor', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthViewModel>.value(value: authViewModel),
              ChangeNotifierProvider<ChatViewModel>.value(value: chatViewModel),
            ],
            child: MessageSearchPage(
              chatId: 'chat-1',
              chatName: 'Test Chat',
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(Duration(seconds: 1));

      // Assert
      expect(find.byType(MessageSearchPage), findsOneWidget);
      final widget = tester.widget<MessageSearchPage>(find.byType(MessageSearchPage));
      expect(widget.chatId, 'chat-1');
      expect(widget.chatName, 'Test Chat');
    });
  });
}

