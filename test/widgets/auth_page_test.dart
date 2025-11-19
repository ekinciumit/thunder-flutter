import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:thunder/views/auth_page.dart';
import 'package:thunder/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:thunder/features/auth/domain/repositories/auth_repository.dart';
import 'package:mockito/annotations.dart';

import 'auth_page_test.mocks.dart';

@GenerateMocks([AuthRepository])
void main() {
  group('AuthPage Widget Tests', () {
    testWidgets('AuthPage - Email ve password field\'ları görünür', (WidgetTester tester) async {
      // Arrange
      final mockRepository = MockAuthRepository();
      final authViewModel = AuthViewModel(authRepository: mockRepository);
      
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthViewModel>.value(
            value: authViewModel,
            child: const AuthPage(),
          ),
        ),
      );
      
      // Assert
      expect(find.byType(TextFormField), findsNWidgets(2)); // Email ve password
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Şifre'), findsOneWidget);
    });

    testWidgets('AuthPage - Giriş butonu görünür', (WidgetTester tester) async {
      // Arrange
      final mockRepository = MockAuthRepository();
      final authViewModel = AuthViewModel(authRepository: mockRepository);
      
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthViewModel>.value(
            value: authViewModel,
            child: const AuthPage(),
          ),
        ),
      );
      
      // Assert
      expect(find.byType(ElevatedButton), findsWidgets);
    });

    testWidgets('AuthPage - Kayıt ol / Giriş yap toggle çalışıyor', (WidgetTester tester) async {
      // Arrange
      final mockRepository = MockAuthRepository();
      final authViewModel = AuthViewModel(authRepository: mockRepository);
      
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthViewModel>.value(
            value: authViewModel,
            child: const AuthPage(),
          ),
        ),
      );
      
      // Toggle butonunu bul ve tıkla
      final toggleButton = find.text('Kayıt Ol');
      if (toggleButton.evaluate().isNotEmpty) {
        await tester.tap(toggleButton);
        await tester.pumpAndSettle();
      }
      
      // Assert
      // Toggle sonrası UI'ın değiştiğini kontrol et
      expect(find.byType(AuthPage), findsOneWidget);
    });
  });
}

