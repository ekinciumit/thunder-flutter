import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:thunder/views/widgets/modern_button.dart';

void main() {
  group('ModernButton Widget Tests', () {
    testWidgets('ModernButton - Widget render ediliyor', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModernButton(
              text: 'Test Button',
              onPressed: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(ModernButton), findsOneWidget);
      expect(find.text('Test Button'), findsOneWidget);
    });

    testWidgets('ModernButton - onPressed callback çağrılıyor', (WidgetTester tester) async {
      // Arrange
      bool pressed = false;
      
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModernButton(
              text: 'Press Me',
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ModernButton));
      await tester.pumpAndSettle();

      // Assert
      expect(pressed, true);
    });

    testWidgets('ModernButton - Loading state gösteriliyor', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModernButton(
              text: 'Loading',
              isLoading: true,
              onPressed: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('ModernButton - Icon gösteriliyor', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModernButton(
              text: 'Icon Button',
              icon: Icons.add,
              onPressed: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('ModernButton - Outlined style uygulanıyor', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModernButton(
              text: 'Outlined',
              isOutlined: true,
              onPressed: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(ModernButton), findsOneWidget);
      expect(find.text('Outlined'), findsOneWidget);
    });

    testWidgets('ModernIconButton - Widget render ediliyor', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModernIconButton(
              icon: Icons.favorite,
              onPressed: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(ModernIconButton), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    testWidgets('ModernIconButton - Tooltip gösteriliyor', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModernIconButton(
              icon: Icons.settings,
              tooltip: 'Settings',
              onPressed: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(Tooltip), findsOneWidget);
    });
  });
}

