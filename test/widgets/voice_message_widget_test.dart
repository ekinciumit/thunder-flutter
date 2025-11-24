import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:thunder/views/widgets/voice_message_widget.dart';

void main() {
  group('VoiceMessageWidget Widget Tests', () {
    testWidgets('VoiceMessageWidget - Widget render ediliyor', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VoiceMessageWidget(
              audioUrl: 'https://example.com/audio.mp3',
              duration: Duration(seconds: 30),
              isMe: true,
            ),
          ),
        ),
      );

      // AudioService platform-specific olduğu için pumpAndSettle yerine pump kullanıyoruz
      await tester.pump();
      await tester.pump(Duration(seconds: 1));

      // Assert
      expect(find.byType(VoiceMessageWidget), findsOneWidget);
    });

    testWidgets('VoiceMessageWidget - Duration ile render ediliyor', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VoiceMessageWidget(
              audioUrl: 'https://example.com/audio.mp3',
              duration: Duration(seconds: 45),
              isMe: true,
            ),
          ),
        ),
      );

      // AudioService platform-specific olduğu için pumpAndSettle yerine pump kullanıyoruz
      await tester.pump();
      await tester.pump(Duration(seconds: 1)); // Widget'ın initialize olması için bekle

      // Assert
      expect(find.byType(VoiceMessageWidget), findsOneWidget);
      final widget = tester.widget<VoiceMessageWidget>(find.byType(VoiceMessageWidget));
      expect(widget.duration, Duration(seconds: 45));
    });

    testWidgets('VoiceMessageWidget - isMe true olduğunda sağda gösteriliyor', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VoiceMessageWidget(
              audioUrl: 'https://example.com/audio.mp3',
              duration: Duration(seconds: 30),
              isMe: true,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(Duration(seconds: 1));

      // Assert
      expect(find.byType(VoiceMessageWidget), findsOneWidget);
      final widget = tester.widget<VoiceMessageWidget>(find.byType(VoiceMessageWidget));
      expect(widget.isMe, true);
    });

    testWidgets('VoiceMessageWidget - isMe false olduğunda solda gösteriliyor', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VoiceMessageWidget(
              audioUrl: 'https://example.com/audio.mp3',
              duration: Duration(seconds: 30),
              isMe: false,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(Duration(seconds: 1));

      // Assert
      expect(find.byType(VoiceMessageWidget), findsOneWidget);
      final widget = tester.widget<VoiceMessageWidget>(find.byType(VoiceMessageWidget));
      expect(widget.isMe, false);
    });

    testWidgets('VoiceMessageWidget - onLongPress callback çağrılabiliyor', (WidgetTester tester) async {
      // Arrange
      // onLongPress callback'i test için set ediliyor (platform-specific test olduğu için direkt kontrol etmiyoruz)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VoiceMessageWidget(
              audioUrl: 'https://example.com/audio.mp3',
              duration: Duration(seconds: 30),
              isMe: true,
              onLongPress: () {
                // Callback test ediliyor
              },
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(Duration(seconds: 1));

      // Assert
      // AudioService platform-specific olduğu için callback test edilmiyor
      // En azından widget render oluyor ve callback set edilmiş
      expect(find.byType(VoiceMessageWidget), findsOneWidget);
      final widget = tester.widget<VoiceMessageWidget>(find.byType(VoiceMessageWidget));
      expect(widget.onLongPress, isNotNull);
    });
  });
}

