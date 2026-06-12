import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
import 'package:thunder/l10n/app_localizations.dart';

import 'message_forward_page_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<AuthRepository>(),
  MockSpec<ChatRepository>(),
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MessageForwardPage Widget Tests', () {
    late MockAuthRepository mockAuthRepository;
    late MockChatRepository mockChatRepository;
    late AuthViewModel authViewModel;
    late ChatViewModel chatViewModel;
    late UserEntity testUser;
    late MessageEntity testMessage;

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
        text: 'Test mesaji',
        timestamp: DateTime.now(),
        type: MessageType.text,
        status: MessageStatus.sent,
      );

      when(mockAuthRepository.getCurrentUser()).thenReturn(testUser);
      when(mockAuthRepository.fetchUserProfile(any)).thenAnswer(
        (_) async => Either.right(testUser),
      );
      // Bos stream: loading state sabit kalir, async setState race yok
      when(mockChatRepository.getUserChats(any)).thenAnswer(
        (_) => Stream<List<ChatEntity>>.empty(),
      );

      authViewModel = AuthViewModel(authRepository: mockAuthRepository);
      chatViewModel = ChatViewModel(chatRepository: mockChatRepository);
    });

    tearDown(() {
      authViewModel.dispose();
      chatViewModel.dispose();
    });

    Future<void> pumpPage(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('tr'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('tr'), Locale('en')],
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthViewModel>.value(value: authViewModel),
              ChangeNotifierProvider<ChatViewModel>.value(value: chatViewModel),
            ],
            child: MessageForwardPage(message: testMessage),
          ),
        ),
      );
      await tester.pump();
    }

    Future<void> unloadPage(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }

    testWidgets('MessageForwardPage - Widget render ediliyor', (WidgetTester tester) async {
      await pumpPage(tester);

      expect(find.byType(MessageForwardPage), findsOneWidget);
      expect(find.byType(Scaffold), findsWidgets);

      await unloadPage(tester);
    });

    testWidgets('MessageForwardPage - Loading state gösteriliyor', (WidgetTester tester) async {
      await pumpPage(tester);

      expect(find.byType(MessageForwardPage), findsOneWidget);
      expect(find.text('Sohbetler yükleniyor...'), findsOneWidget);

      await unloadPage(tester);
    });
  });
}
