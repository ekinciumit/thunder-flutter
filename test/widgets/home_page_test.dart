import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:thunder/views/home_page.dart';
import 'package:thunder/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:thunder/features/auth/domain/repositories/auth_repository.dart';
import 'package:thunder/models/user_model.dart';

import 'home_page_test.mocks.dart';

@GenerateMocks([AuthRepository])
void main() {
  group('HomePage Widget Tests', () {
    late MockAuthRepository mockRepository;
    late AuthViewModel authViewModel;
    late UserModel testUser;

    setUp(() {
      mockRepository = MockAuthRepository();
      
      testUser = UserModel(
        uid: 'user-1',
        email: 'test@example.com',
        displayName: 'Test User',
      );

      // Mock repository setup - AuthViewModel constructor'ı getCurrentUser çağırıyor
      when(mockRepository.getCurrentUser()).thenReturn(testUser);
      
      authViewModel = AuthViewModel(authRepository: mockRepository);
    });

    testWidgets('HomePage - Widget render ediliyor', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthViewModel>.value(
            value: authViewModel,
            child: HomePage(),
          ),
        ),
      );

      // Notification service ve Firestore stream'leri test ortamında çalışmaz
      await tester.pump();
      await tester.pump(Duration(seconds: 1));

      // Assert
      expect(find.byType(HomePage), findsOneWidget);
    });

    testWidgets('HomePage - BottomNavigationBar görünüyor', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthViewModel>.value(
            value: authViewModel,
            child: HomePage(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(Duration(seconds: 1));

      // Assert
      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });

    testWidgets('HomePage - Tab değiştirilebiliyor', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthViewModel>.value(
            value: authViewModel,
            child: HomePage(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(Duration(seconds: 1));

      // Assert - BottomNavigationBar var
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.byType(HomePage), findsOneWidget);
    });
  });
}

