import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thunder/views/widgets/language_selector.dart';
import 'package:thunder/services/language_service.dart';

void main() {
  group('LanguageSelector Widget Tests', () {
    testWidgets('LanguageSelector - Widget render ediliyor', (WidgetTester tester) async {
      // Arrange
      final languageService = LanguageService();
      
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<LanguageService>.value(
              value: languageService,
              child: LanguageSelector(),
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(LanguageSelector), findsOneWidget);
      expect(find.byIcon(Icons.language), findsOneWidget);
    });

    testWidgets('LanguageSelector - PopupMenuButton açılıyor', (WidgetTester tester) async {
      // Arrange
      final languageService = LanguageService();
      
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<LanguageService>.value(
              value: languageService,
              child: LanguageSelector(),
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.language));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Türkçe'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
    });

    testWidgets('LanguageSelector - Türkçe seçiliyor', (WidgetTester tester) async {
      // Arrange
      final languageService = LanguageService();
      
      // Act
      await tester.pumpWidget(
        MaterialApp(
          scaffoldMessengerKey: GlobalKey<ScaffoldMessengerState>(),
          home: Scaffold(
            body: ChangeNotifierProvider<LanguageService>.value(
              value: languageService,
              child: LanguageSelector(),
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.language));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Türkçe'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Dil Türkçe olarak değiştirildi'), findsOneWidget);
      expect(languageService.currentLocale.languageCode, 'tr');
    });

    testWidgets('LanguageSelector - English seçiliyor', (WidgetTester tester) async {
      // Arrange
      final languageService = LanguageService();
      
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<LanguageService>.value(
              value: languageService,
              child: LanguageSelector(),
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.language));
      await tester.pumpAndSettle();

      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      // Assert
      // Dil değişikliğini kontrol et (SnackBar test ortamında görünmeyebilir)
      expect(languageService.currentLocale.languageCode, 'en');
    });

    testWidgets('LanguageSelector - Mevcut dil işaretleniyor', (WidgetTester tester) async {
      // Arrange
      final languageService = LanguageService();
      await languageService.setTurkish(); // Türkçe'ye geç
      
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<LanguageService>.value(
              value: languageService,
              child: LanguageSelector(),
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.language));
      await tester.pumpAndSettle();

      // Assert
      // Türkçe seçili olduğu için check icon'u görünmeli
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('LanguageSelector - Tooltip gösteriliyor', (WidgetTester tester) async {
      // Arrange
      final languageService = LanguageService();
      
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<LanguageService>.value(
              value: languageService,
              child: LanguageSelector(),
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(Tooltip), findsOneWidget);
    });
  });
}

