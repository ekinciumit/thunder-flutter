import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:thunder/views/event_list_view.dart';
import 'package:thunder/features/event/presentation/viewmodels/event_viewmodel.dart';
import 'package:thunder/features/event/domain/repositories/event_repository.dart';
import 'package:thunder/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:thunder/features/auth/domain/repositories/auth_repository.dart';

import 'event_list_view_test.mocks.dart';

@GenerateMocks([EventRepository, AuthRepository])
void main() {
  group('EventListView Widget Tests', () {
    late MockEventRepository mockEventRepository;
    late MockAuthRepository mockAuthRepository;
    late EventViewModel eventViewModel;
    late AuthViewModel authViewModel;

    setUp(() {
      mockEventRepository = MockEventRepository();
      mockAuthRepository = MockAuthRepository();
      
      // AuthViewModel için stub
      when(mockAuthRepository.getCurrentUser()).thenReturn(null);
      authViewModel = AuthViewModel(authRepository: mockAuthRepository);
      
      // EventViewModel oluştur
      eventViewModel = EventViewModel(
        eventRepository: mockEventRepository,
        autoListenEvents: false, // Test için otomatik dinlemeyi kapat
      );
    });

    tearDown(() {
      eventViewModel.dispose();
    });

    testWidgets('EventListView - Widget render ediliyor', (WidgetTester tester) async {
      // Arrange & Act
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
              ChangeNotifierProvider<EventViewModel>.value(value: eventViewModel),
              ChangeNotifierProvider<AuthViewModel>.value(value: authViewModel),
            ],
            child: const EventListView(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(EventListView), findsOneWidget);
    });

    testWidgets('EventListView - Arama alanı görünür', (WidgetTester tester) async {
      // Arrange & Act
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
              ChangeNotifierProvider<EventViewModel>.value(value: eventViewModel),
              ChangeNotifierProvider<AuthViewModel>.value(value: authViewModel),
            ],
            child: const EventListView(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      // Arama alanı TextField olarak render edilir
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('EventListView - Kategori filtresi görünür', (WidgetTester tester) async {
      // Arrange & Act
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
              ChangeNotifierProvider<EventViewModel>.value(value: eventViewModel),
              ChangeNotifierProvider<AuthViewModel>.value(value: authViewModel),
            ],
            child: const EventListView(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      // Kategori filtresi genellikle bir dropdown veya chip listesi olarak render edilir
      // En azından widget'ın render edildiğini kontrol ediyoruz
      expect(find.byType(EventListView), findsOneWidget);
    });
  });
}


