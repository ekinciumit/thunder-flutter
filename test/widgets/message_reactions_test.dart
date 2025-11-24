import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:thunder/views/widgets/message_reactions.dart';

void main() {
  group('MessageReactions Widget Tests', () {
    testWidgets('MessageReactions - Boş reactions için widget gösterilmiyor', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageReactions(
              reactions: {},
              currentUserId: 'user-1',
              onReactionTap: (emoji) {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(MessageReactions), findsOneWidget);
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('MessageReactions - Reaction gösteriliyor', (WidgetTester tester) async {
      // Arrange
      final reactions = {
        'user-1': ['❤️'],
      };

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageReactions(
              reactions: reactions,
              currentUserId: 'user-1',
              onReactionTap: (emoji) {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(MessageReactions), findsOneWidget);
      expect(find.text('❤️'), findsOneWidget);
    });

    testWidgets('MessageReactions - Birden fazla reaction gösteriliyor', (WidgetTester tester) async {
      // Arrange
      final reactions = {
        'user-1': ['❤️'],
        'user-2': ['👍'],
        'user-3': ['❤️'],
      };

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageReactions(
              reactions: reactions,
              currentUserId: 'user-1',
              onReactionTap: (emoji) {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('❤️'), findsOneWidget);
      expect(find.text('👍'), findsOneWidget);
      expect(find.textContaining('2'), findsOneWidget); // Count for ❤️
    });

    testWidgets('MessageReactions - Reaction tıklanınca callback çağrılıyor', (WidgetTester tester) async {
      // Arrange
      String? tappedEmoji;
      final reactions = {
        'user-1': ['❤️'],
      };

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageReactions(
              reactions: reactions,
              currentUserId: 'user-1',
              onReactionTap: (emoji) {
                tappedEmoji = emoji;
              },
            ),
          ),
        ),
      );

      final reactionFinder = find.text('❤️');
      await tester.tap(reactionFinder);
      await tester.pumpAndSettle();

      // Assert
      expect(tappedEmoji, '❤️');
    });

    testWidgets('MessageReactions - Current user reaction highlight gösteriliyor', (WidgetTester tester) async {
      // Arrange
      final reactions = {
        'user-1': ['❤️'],
        'user-2': ['👍'],
      };

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageReactions(
              reactions: reactions,
              currentUserId: 'user-1',
              onReactionTap: (emoji) {},
            ),
          ),
        ),
      );

      // Assert
      // Current user'ın reaction'ı highlighted olmalı (border color farklı)
      expect(find.byType(MessageReactions), findsOneWidget);
      expect(find.text('❤️'), findsOneWidget);
      expect(find.text('👍'), findsOneWidget);
    });

    testWidgets('MessageReactions - Aynı emoji birden fazla kullanıcı tarafından kullanılmışsa sayı gösteriliyor', (WidgetTester tester) async {
      // Arrange
      final reactions = {
        'user-1': ['❤️'],
        'user-2': ['❤️'],
        'user-3': ['❤️'],
      };

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageReactions(
              reactions: reactions,
              currentUserId: 'user-1',
              onReactionTap: (emoji) {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('❤️'), findsOneWidget);
      expect(find.textContaining('3'), findsOneWidget); // Count
    });
  });
}

