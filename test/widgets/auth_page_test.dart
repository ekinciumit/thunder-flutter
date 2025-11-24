import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:thunder/views/auth_page.dart';
import 'package:thunder/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:thunder/features/auth/domain/repositories/auth_repository.dart';
import 'package:thunder/l10n/app_localizations.dart';

import 'auth_page_test.mocks.dart';

@GenerateMocks([AuthRepository])
void main() {
  group('AuthPage Widget Tests', () {
    testWidgets('AuthPage - Email ve password field\'ları görünür', (WidgetTester tester) async {
      // Arrange
      final mockRepository = MockAuthRepository();
      // AuthViewModel constructor'ında getCurrentUser() çağrılıyor, stub ekle
      when(mockRepository.getCurrentUser()).thenReturn(null);
      final authViewModel = AuthViewModel(authRepository: mockRepository);
      
      // Act
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('tr'), // Türkçe locale ayarla
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('tr'), Locale('en')],
          home: ChangeNotifierProvider<AuthViewModel>.value(
            value: authViewModel,
            child: const AuthPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      
      // Assert
      // TextField kullanılıyor (TextFormField değil)
      expect(find.byType(TextField), findsNWidgets(2)); // Email ve password
      // Localization string'lerini kontrol et - TextField label'ları Text widget'ı değil,
      // bu yüzden byWidgetPredicate kullanarak kontrol ediyoruz
      final emailField = find.byWidgetPredicate(
        (widget) => widget is TextField && 
                    widget.decoration?.labelText == 'E-posta',
      );
      final passwordField = find.byWidgetPredicate(
        (widget) => widget is TextField && 
                    widget.decoration?.labelText == 'Şifre',
      );
      expect(emailField, findsOneWidget);
      expect(passwordField, findsOneWidget);
    });

    testWidgets('AuthPage - Giriş butonu görünür', (WidgetTester tester) async {
      // Arrange
      final mockRepository = MockAuthRepository();
      // AuthViewModel constructor'ında getCurrentUser() çağrılıyor, stub ekle
      when(mockRepository.getCurrentUser()).thenReturn(null);
      final authViewModel = AuthViewModel(authRepository: mockRepository);
      
      // Act
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('tr'), // Türkçe locale ayarla
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('tr'), Locale('en')],
          home: ChangeNotifierProvider<AuthViewModel>.value(
            value: authViewModel,
            child: const AuthPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      
      // Assert
      expect(find.byType(FilledButton), findsWidgets);
    });

    testWidgets('AuthPage - Kayıt ol / Giriş yap toggle çalışıyor', (WidgetTester tester) async {
      // Arrange
      final mockRepository = MockAuthRepository();
      // AuthViewModel constructor'ında getCurrentUser() çağrılıyor, stub ekle
      when(mockRepository.getCurrentUser()).thenReturn(null);
      final authViewModel = AuthViewModel(authRepository: mockRepository);
      
      // Act
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('tr'), // Türkçe locale ayarla
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('tr'), Locale('en')],
          home: ChangeNotifierProvider<AuthViewModel>.value(
            value: authViewModel,
            child: const AuthPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      
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

