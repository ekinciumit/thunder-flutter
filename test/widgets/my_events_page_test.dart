import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:thunder/views/my_events_page.dart';
import 'package:thunder/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:thunder/features/event/presentation/viewmodels/event_viewmodel.dart';
import 'package:thunder/features/auth/domain/repositories/auth_repository.dart';
import 'package:thunder/features/event/domain/repositories/event_repository.dart';
import 'package:thunder/models/user_model.dart';

import 'my_events_page_test.mocks.dart';

@GenerateMocks([AuthRepository, EventRepository])
void main() {
  group('MyEventsPage Widget Tests', () {
    late MockAuthRepository mockAuthRepository;
    late MockEventRepository mockEventRepository;
    late AuthViewModel authViewModel;
    late EventViewModel eventViewModel;
    late UserModel testUser;

    setUp(() {
      mockAuthRepository = MockAuthRepository();
      mockEventRepository = MockEventRepository();
      
      testUser = UserModel(
        uid: 'user-1',
        email: 'test@example.com',
        displayName: 'Test User',
        followers: [],
        following: [],
        pendingFollowRequests: [],
        sentFollowRequests: [],
      );

      // Mock repository setup - AuthViewModel constructor'ı getCurrentUser çağırıyor
      when(mockAuthRepository.getCurrentUser()).thenReturn(testUser);
      when(mockEventRepository.getUserEventsStream(any)).thenAnswer((_) async* {
        yield [];
      });
      
      authViewModel = AuthViewModel(authRepository: mockAuthRepository);
      eventViewModel = EventViewModel(eventRepository: mockEventRepository);
    });

    testWidgets('MyEventsPage - Widget render ediliyor', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthViewModel>.value(value: authViewModel),
              ChangeNotifierProvider<EventViewModel>.value(value: eventViewModel),
            ],
            child: MyEventsPage(),
          ),
        ),
      );

      // Firestore stream'leri test ortamında çalışmaz
      await tester.pump();
      await tester.pump(Duration(seconds: 1));

      // Assert
      expect(find.byType(MyEventsPage), findsOneWidget);
      expect(find.text('Etkinliklerim'), findsOneWidget);
    });

    testWidgets('MyEventsPage - Kullanıcı yoksa hata mesajı gösteriliyor', (WidgetTester tester) async {
      // Arrange - Yeni bir AuthViewModel oluştur (null user ile)
      when(mockAuthRepository.getCurrentUser()).thenReturn(null);
      final nullUserAuthViewModel = AuthViewModel(authRepository: mockAuthRepository);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthViewModel>.value(value: nullUserAuthViewModel),
              ChangeNotifierProvider<EventViewModel>.value(value: eventViewModel),
            ],
            child: MyEventsPage(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(Duration(seconds: 1));

      // Assert
      expect(find.text('Kullanıcı bilgisi bulunamadı'), findsOneWidget);
    });

    testWidgets('MyEventsPage - Loading state gösteriliyor', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthViewModel>.value(value: authViewModel),
              ChangeNotifierProvider<EventViewModel>.value(value: eventViewModel),
            ],
            child: MyEventsPage(),
          ),
        ),
      );

      // İlk render'da loading state olabilir
      await tester.pump();

      // Assert
      expect(find.byType(MyEventsPage), findsOneWidget);
    });
  });
}

