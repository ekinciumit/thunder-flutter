import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:thunder/features/chat/presentation/widgets/file_picker_widget.dart';
import 'package:thunder/l10n/app_localizations.dart';

void main() {
  group('FilePickerWidget Widget Tests', () {
    Future<void> pumpWidget(WidgetTester tester, Widget child) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('tr'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('tr'), Locale('en')],
          home: Scaffold(body: child),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('FilePickerWidget - Widget render ediliyor', (WidgetTester tester) async {
      await pumpWidget(
        tester,
        FilePickerWidget(
          onFileSelected: (_) {},
          onClose: () {},
        ),
      );

      expect(find.text('Dosya Seç'), findsOneWidget);
      expect(find.byType(FilePickerWidget), findsOneWidget);
    });

    testWidgets('FilePickerWidget - Dosya tipi seçenekleri görünür', (WidgetTester tester) async {
      await pumpWidget(
        tester,
        FilePickerWidget(
          onFileSelected: (_) {},
          onClose: () {},
        ),
      );

      expect(find.text('Tüm Dosyalar'), findsOneWidget);
      expect(find.text('PDF'), findsOneWidget);
    });

    testWidgets('FilePickerWidget - Handle bar görünür', (WidgetTester tester) async {
      await pumpWidget(
        tester,
        FilePickerWidget(
          onFileSelected: (_) {},
          onClose: () {},
        ),
      );

      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('FilePickerWidget - Dosya tipi butonları render ediliyor', (WidgetTester tester) async {
      await pumpWidget(
        tester,
        FilePickerWidget(
          onFileSelected: (_) {},
          onClose: () {},
        ),
      );

      expect(find.byType(GridView), findsOneWidget);
      expect(find.byIcon(Icons.folder_open), findsOneWidget);
    });

    testWidgets('FilePickerWidget - Container decoration doğru', (WidgetTester tester) async {
      await pumpWidget(
        tester,
        FilePickerWidget(
          onFileSelected: (_) {},
          onClose: () {},
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(FilePickerWidget),
          matching: find.byType(Container).first,
        ),
      );
      expect(container.decoration, isNotNull);
    });

    testWidgets('FilePickerWidget - Butonlar tıklanabilir', (WidgetTester tester) async {
      await pumpWidget(
        tester,
        FilePickerWidget(
          onFileSelected: (_) {},
          onClose: () {},
        ),
      );

      expect(find.text('Tüm Dosyalar'), findsOneWidget);
      await tester.tap(find.text('Tüm Dosyalar'));
      await tester.pump();
    });
  });
}
