import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:thunder/views/widgets/voice_recorder_widget.dart';

void main() {
  group('VoiceRecorderWidget Widget Tests', () {
    testWidgets('VoiceRecorderWidget - Widget render ediliyor', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VoiceRecorderWidget(
              onRecordingComplete: (filePath, duration) {},
              onCancel: () {},
            ),
          ),
        ),
      );

      // AudioService platform-specific olduğu için pumpAndSettle yerine pump kullanıyoruz
      await tester.pump();
      await tester.pump(Duration(seconds: 1));

      // Assert
      expect(find.byType(VoiceRecorderWidget), findsOneWidget);
    });

    testWidgets('VoiceRecorderWidget - Callback fonksiyonları set ediliyor', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VoiceRecorderWidget(
              onRecordingComplete: (filePath, duration) {},
              onCancel: () {},
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(Duration(seconds: 1));

      // Assert
      expect(find.byType(VoiceRecorderWidget), findsOneWidget);
      final widget = tester.widget<VoiceRecorderWidget>(find.byType(VoiceRecorderWidget));
      expect(widget.onRecordingComplete, isNotNull);
      expect(widget.onCancel, isNotNull);
    });
  });
}
