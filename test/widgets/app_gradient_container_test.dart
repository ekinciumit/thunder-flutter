import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:thunder/views/widgets/app_gradient_container.dart';

void main() {
  group('AppGradientContainer Widget Tests', () {
    testWidgets('AppGradientContainer - Widget render ediliyor', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppGradientContainer(
              child: Text('Test Content'),
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(AppGradientContainer), findsOneWidget);
      expect(find.text('Test Content'), findsOneWidget);
    });

    testWidgets('AppGradientContainer - Custom gradient colors uygulanıyor', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppGradientContainer(
              gradientColors: [Colors.red, Colors.blue, Colors.green],
              child: Text('Custom Gradient'),
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(AppGradientContainer), findsOneWidget);
      expect(find.text('Custom Gradient'), findsOneWidget);
    });

    testWidgets('AppGradientContainer - Animated gradient aktif', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppGradientContainer(
              enableAnimatedGradient: true,
              child: Text('Animated Gradient'),
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(AnimatedContainer), findsOneWidget);
    });

    testWidgets('AppGradientContainer - Custom padding uygulanıyor', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppGradientContainer(
              padding: EdgeInsets.all(20),
              child: Text('Custom Padding'),
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(AppGradientContainer), findsOneWidget);
      expect(find.text('Custom Padding'), findsOneWidget);
    });
  });
}

