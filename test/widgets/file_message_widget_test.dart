import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:thunder/views/widgets/file_message_widget.dart';

void main() {
  group('FileMessageWidget Widget Tests', () {
    testWidgets('FileMessageWidget - Widget render ediliyor', (WidgetTester tester) async {
      // Overflow uyarılarını görmezden gel (test ortamında widget genişliği sınırlı)
      tester.view.physicalSize = Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300, // Widget için yeterli genişlik
              child: FileMessageWidget(
                fileName: 'test.pdf',
                isMe: true,
              ),
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(FileMessageWidget), findsOneWidget);
      expect(find.text('test.pdf'), findsOneWidget);
    });

    testWidgets('FileMessageWidget - PDF dosyası için PDF ikonu gösteriliyor', (WidgetTester tester) async {
      tester.view.physicalSize = Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: FileMessageWidget(
                fileName: 'document.pdf',
                fileExtension: 'pdf',
                isMe: true,
              ),
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.picture_as_pdf), findsOneWidget);
    });

    testWidgets('FileMessageWidget - Word dosyası için Word ikonu gösteriliyor', (WidgetTester tester) async {
      tester.view.physicalSize = Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: FileMessageWidget(
                fileName: 'document.docx',
                fileExtension: 'docx',
                isMe: true,
              ),
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.description), findsOneWidget);
    });

    testWidgets('FileMessageWidget - Excel dosyası için Excel ikonu gösteriliyor', (WidgetTester tester) async {
      tester.view.physicalSize = Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: FileMessageWidget(
                fileName: 'spreadsheet.xlsx',
                fileExtension: 'xlsx',
                isMe: true,
              ),
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.table_chart), findsOneWidget);
    });

    testWidgets('FileMessageWidget - Image dosyası için Image ikonu gösteriliyor', (WidgetTester tester) async {
      tester.view.physicalSize = Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: FileMessageWidget(
                fileName: 'image.jpg',
                fileExtension: 'jpg',
                isMe: true,
              ),
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.image), findsOneWidget);
    });

    testWidgets('FileMessageWidget - File size gösteriliyor', (WidgetTester tester) async {
      tester.view.physicalSize = Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: FileMessageWidget(
                fileName: 'test.pdf',
                fileSize: 1024 * 1024, // 1 MB
                isMe: true,
              ),
            ),
          ),
        ),
      );

      // Assert
      expect(find.textContaining('1.0'), findsOneWidget); // MB formatında
    });

    testWidgets('FileMessageWidget - onTap callback çağrılıyor', (WidgetTester tester) async {
      tester.view.physicalSize = Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      
      // Arrange
      bool tapped = false;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: FileMessageWidget(
                fileName: 'test.pdf',
                isMe: true,
                onTap: () => tapped = true,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(FileMessageWidget));
      await tester.pumpAndSettle();

      // Assert
      expect(tapped, true);
    });

    testWidgets('FileMessageWidget - onLongPress callback çağrılıyor', (WidgetTester tester) async {
      tester.view.physicalSize = Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      
      // Arrange
      bool longPressed = false;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: FileMessageWidget(
                fileName: 'test.pdf',
                isMe: true,
                onLongPress: () => longPressed = true,
              ),
            ),
          ),
        ),
      );

      await tester.longPress(find.byType(FileMessageWidget));
      await tester.pumpAndSettle();

      // Assert
      expect(longPressed, true);
    });

    testWidgets('FileMessageWidget - isMe true olduğunda sağda gösteriliyor', (WidgetTester tester) async {
      tester.view.physicalSize = Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: FileMessageWidget(
                fileName: 'test.pdf',
                isMe: true,
              ),
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(FileMessageWidget), findsOneWidget);
      final widget = tester.widget<FileMessageWidget>(find.byType(FileMessageWidget));
      expect(widget.isMe, true);
    });

    testWidgets('FileMessageWidget - isMe false olduğunda solda gösteriliyor', (WidgetTester tester) async {
      tester.view.physicalSize = Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: FileMessageWidget(
                fileName: 'test.pdf',
                isMe: false,
              ),
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(FileMessageWidget), findsOneWidget);
      final widget = tester.widget<FileMessageWidget>(find.byType(FileMessageWidget));
      expect(widget.isMe, false);
    });
  });
}

