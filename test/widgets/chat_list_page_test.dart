import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:thunder/views/chat_list_page.dart';
import 'package:thunder/features/chat/presentation/viewmodels/chat_viewmodel.dart';
import 'package:thunder/features/chat/domain/repositories/chat_repository.dart';
import 'package:thunder/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:thunder/features/auth/domain/repositories/auth_repository.dart';
import 'package:thunder/models/user_model.dart';

import 'chat_list_page_test.mocks.dart';

@GenerateMocks([ChatRepository, AuthRepository])
void main() {
  group('ChatListPage Widget Tests', () {
    late MockChatRepository mockChatRepository;
    late MockAuthRepository mockAuthRepository;
    late ChatViewModel chatViewModel;
    late AuthViewModel authViewModel;

    setUp(() {
      mockChatRepository = MockChatRepository();
      mockAuthRepository = MockAuthRepository();
      
      // ChatViewModel oluştur
      chatViewModel = ChatViewModel(chatRepository: mockChatRepository);
    });

    tearDown(() {
      chatViewModel.dispose();
    });

    testWidgets('ChatListPage - Kullanıcı yoksa hata mesajı gösteriliyor', (WidgetTester tester) async {
      // Arrange
      when(mockAuthRepository.getCurrentUser()).thenReturn(null);
      authViewModel = AuthViewModel(authRepository: mockAuthRepository);
      
      // Act
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('tr'),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('tr'), Locale('en')],
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<ChatViewModel>.value(value: chatViewModel),
              ChangeNotifierProvider<AuthViewModel>.value(value: authViewModel),
            ],
            child: const ChatListPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(ChatListPage), findsOneWidget);
      expect(find.text('Kullanıcı bilgisi bulunamadı'), findsOneWidget);
    });

    testWidgets('ChatListPage - Kullanıcı varsa widget render ediliyor', (WidgetTester tester) async {
      // Arrange
      final testUser = UserModel(uid: 'test-uid', email: 'test@test.com');
      when(mockAuthRepository.getCurrentUser()).thenReturn(testUser);
      authViewModel = AuthViewModel(authRepository: mockAuthRepository);
      
      // getUserChats stream'ini mock'la
      when(mockChatRepository.getUserChats(any)).thenAnswer(
        (_) => Stream.value([]), // Boş liste döndür
      );
      
      // Act
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('tr'),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('tr'), Locale('en')],
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<ChatViewModel>.value(value: chatViewModel),
              ChangeNotifierProvider<AuthViewModel>.value(value: authViewModel),
            ],
            child: const ChatListPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(ChatListPage), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('ChatListPage - AppBar görünür', (WidgetTester tester) async {
      // Arrange
      final testUser = UserModel(uid: 'test-uid', email: 'test@test.com');
      when(mockAuthRepository.getCurrentUser()).thenReturn(testUser);
      authViewModel = AuthViewModel(authRepository: mockAuthRepository);
      
      // getUserChats stream'ini mock'la
      when(mockChatRepository.getUserChats(any)).thenAnswer(
        (_) => Stream.value([]),
      );
      
      // Act
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('tr'),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('tr'), Locale('en')],
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<ChatViewModel>.value(value: chatViewModel),
              ChangeNotifierProvider<AuthViewModel>.value(value: authViewModel),
            ],
            child: const ChatListPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(AppBar), findsOneWidget);
    });
  });
}

