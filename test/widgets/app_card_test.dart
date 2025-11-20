import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:thunder/views/widgets/app_card.dart';

void main() {
  group('AppCard Widget Tests', () {
    testWidgets('AppCard - Widget render ediliyor', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppCard(
              child: Text('Test Content'),
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(AppCard), findsOneWidget);
      expect(find.text('Test Content'), findsOneWidget);
    });

    testWidgets('AppCard - onTap callback çağrılıyor', (WidgetTester tester) async {
      // Arrange
      bool tapped = false;
      
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppCard(
              onTap: () => tapped = true,
              child: Text('Tappable Card'),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(AppCard));
      await tester.pumpAndSettle();

      // Assert
      expect(tapped, true);
    });

    testWidgets('AppCard - Glassmorphism özelliği aktif', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppCard(
              enableGlassmorphism: true,
              child: Text('Glassmorphism Card'),
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(BackdropFilter), findsOneWidget);
    });

    testWidgets('AppCard - Custom padding ve margin uygulanıyor', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppCard(
              padding: EdgeInsets.all(30),
              margin: EdgeInsets.all(20),
              child: Text('Custom Padding'),
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(AppCard), findsOneWidget);
      expect(find.text('Custom Padding'), findsOneWidget);
    });
  });
}

