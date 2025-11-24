import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:thunder/views/widgets/modern_loading_widget.dart';

void main() {
  group('ModernLoadingWidget Widget Tests', () {
    testWidgets('ModernLoadingWidget - Widget render ediliyor', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModernLoadingWidget(),
          ),
        ),
      );

      // Assert
      expect(find.byType(ModernLoadingWidget), findsOneWidget);
      expect(find.byType(AnimatedBuilder), findsWidgets); // Multiple AnimatedBuilders exist
    });

    testWidgets('ModernLoadingWidget - Message gösteriliyor', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModernLoadingWidget(
              message: 'Yükleniyor...',
              showMessage: true,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Yükleniyor...'), findsOneWidget);
    });

    testWidgets('ModernLoadingWidget - Message gösterilmiyor (showMessage: false)', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModernLoadingWidget(
              message: 'Yükleniyor...',
              showMessage: false,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Yükleniyor...'), findsNothing);
    });

    testWidgets('ModernLoadingWidget - Custom size uygulanıyor', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModernLoadingWidget(
              size: 80,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(ModernLoadingWidget), findsOneWidget);
      final widget = tester.widget<ModernLoadingWidget>(find.byType(ModernLoadingWidget));
      expect(widget.size, 80);
    });

    testWidgets('ModernLoadingWidget - Custom color uygulanıyor', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModernLoadingWidget(
              color: Colors.red,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(ModernLoadingWidget), findsOneWidget);
      final widget = tester.widget<ModernLoadingWidget>(find.byType(ModernLoadingWidget));
      expect(widget.color, Colors.red);
    });

    testWidgets('ModernLoadingOverlay - Loading true olduğunda overlay gösteriliyor', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModernLoadingOverlay(
              isLoading: true,
              message: 'Yükleniyor...',
              child: Text('Content'),
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(ModernLoadingOverlay), findsOneWidget);
      expect(find.byType(ModernLoadingWidget), findsOneWidget);
      expect(find.text('Yükleniyor...'), findsOneWidget);
    });

    testWidgets('ModernLoadingOverlay - Loading false olduğunda overlay gösterilmiyor', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModernLoadingOverlay(
              isLoading: false,
              message: 'Yükleniyor...',
              child: Text('Content'),
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(ModernLoadingOverlay), findsOneWidget);
      expect(find.byType(ModernLoadingWidget), findsNothing);
      expect(find.text('Content'), findsOneWidget);
    });
  });
}

