import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thunder/views/complete_profile_page.dart';

void main() {
  group('CompleteProfilePage Widget Tests', () {
    late bool onCompleteCalled;
    late String? completedName;
    late String? completedBio;
    late String? completedPhotoUrl;

    setUp(() {
      onCompleteCalled = false;
      completedName = null;
      completedBio = null;
      completedPhotoUrl = null;
    });

    testWidgets('CompleteProfilePage - Form alanları görünür', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: CompleteProfilePage(
            onComplete: (name, bio, photoUrl) {
              onCompleteCalled = true;
              completedName = name;
              completedBio = bio;
              completedPhotoUrl = photoUrl;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Profilini Tamamla'), findsWidgets); // AppBar'da ve içerikte görünür
      // Label'lar TextField içinde labelText olarak gösteriliyor, text olarak değil
      expect(find.byWidgetPredicate(
        (widget) => widget is TextField && widget.decoration?.labelText == 'İsim Soyisim',
      ), findsOneWidget);
      expect(find.byWidgetPredicate(
        (widget) => widget is TextField && widget.decoration?.labelText == 'Biyografi (Opsiyonel)',
      ), findsOneWidget);
      expect(find.text('Kaydet ve Devam Et'), findsOneWidget);
    });

    testWidgets('CompleteProfilePage - İsim ve biyografi alanları mevcut', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: CompleteProfilePage(
            onComplete: (name, bio, photoUrl) {
              onCompleteCalled = true;
              completedName = name;
              completedBio = bio;
              completedPhotoUrl = photoUrl;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(TextField), findsNWidgets(2)); // İsim ve biyografi alanları
    });

    testWidgets('CompleteProfilePage - Profil fotoğrafı seçme alanı görünür', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: CompleteProfilePage(
            onComplete: (name, bio, photoUrl) {
              onCompleteCalled = true;
              completedName = name;
              completedBio = bio;
              completedPhotoUrl = photoUrl;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      // CircleAvatar veya GestureDetector olmalı
      expect(find.byType(CircleAvatar), findsWidgets);
      expect(find.byIcon(Icons.camera_alt), findsWidgets);
    });

    testWidgets('CompleteProfilePage - Form doldurulup kaydet butonu çalışıyor', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: CompleteProfilePage(
            onComplete: (name, bio, photoUrl) {
              onCompleteCalled = true;
              completedName = name;
              completedBio = bio;
              completedPhotoUrl = photoUrl;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act
      final nameField = find.byWidgetPredicate(
        (widget) => widget is TextField && 
                    widget.decoration?.labelText == 'İsim Soyisim',
      );
      final bioField = find.byWidgetPredicate(
        (widget) => widget is TextField && 
                    widget.decoration?.labelText == 'Biyografi (Opsiyonel)',
      );

      await tester.enterText(nameField, 'Test Kullanıcı');
      await tester.enterText(bioField, 'Test biyografi');
      await tester.pump();

      // Kaydet butonunu bul - SingleChildScrollView içinde scroll yapmamız gerekebilir
      var saveButton = find.text('Kaydet ve Devam Et');
      expect(saveButton, findsOneWidget, reason: 'Kaydet butonu bulunmalı');
      
      // Butonun pozisyonunu kontrol et ve gerekirse scroll yap
      final buttonRect = tester.getRect(saveButton);
      final screenSize = tester.getSize(find.byType(MaterialApp));
      
      // Eğer buton ekranın altında ise yukarı scroll yap
      if (buttonRect.bottom > screenSize.height - 50) {
        await tester.dragUntilVisible(
          saveButton,
          find.byType(SingleChildScrollView),
          const Offset(0, -100),
        );
        await tester.pumpAndSettle();
      }
      
      // Butonu tıkla
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Assert
      expect(onCompleteCalled, true, reason: 'onComplete callback çağrılmalı');
      expect(completedName, 'Test Kullanıcı');
      expect(completedBio, 'Test biyografi');
      expect(completedPhotoUrl, null);
    });

    testWidgets('CompleteProfilePage - Boş form gönderilemez (validasyon çalışıyor)', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: CompleteProfilePage(
            onComplete: (name, bio, photoUrl) {
              onCompleteCalled = true;
              completedName = name;
              completedBio = bio;
              completedPhotoUrl = photoUrl;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act
      var saveButton = find.text('Kaydet ve Devam Et');
      expect(saveButton, findsOneWidget, reason: 'Kaydet butonu bulunmalı');
      
      // Butonun pozisyonunu kontrol et ve gerekirse scroll yap
      final buttonRect = tester.getRect(saveButton);
      final screenSize = tester.getSize(find.byType(MaterialApp));
      
      // Eğer buton ekranın altında ise yukarı scroll yap
      if (buttonRect.bottom > screenSize.height - 50) {
        await tester.dragUntilVisible(
          saveButton,
          find.byType(SingleChildScrollView),
          const Offset(0, -100),
        );
        await tester.pumpAndSettle();
      }
      
      // Butonu tıkla (boş form ile)
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Assert
      // Boş form gönderilemez (validasyon hatası gösterilmeli, onComplete çağrılmamalı)
      expect(onCompleteCalled, false, reason: 'onComplete callback çağrılmamalı (validasyon hatası)');
      // Validasyon hatası mesajı gösterilmeli
      expect(find.textContaining('zorunludur'), findsWidgets);
    });

    testWidgets('CompleteProfilePage - AppBar görünür', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: CompleteProfilePage(
            onComplete: (name, bio, photoUrl) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Profilini Tamamla'), findsWidgets); // AppBar'da ve içerikte
    });
  });
}

