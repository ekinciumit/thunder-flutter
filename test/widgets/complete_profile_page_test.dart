import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:thunder/core/errors/failures.dart';
import 'package:thunder/features/auth/presentation/pages/complete_profile_page.dart';
import 'package:thunder/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:thunder/features/user/domain/entities/user_entity.dart';
import 'package:thunder/l10n/app_localizations.dart';

import 'auth_page_test.mocks.dart';

void main() {
  group('CompleteProfilePage Widget Tests', () {
    late MockAuthRepository mockRepository;
    late AuthViewModel authViewModel;

    setUp(() {
      mockRepository = MockAuthRepository();
      when(mockRepository.getCurrentUser()).thenReturn(
        UserEntity(uid: 'test-uid', email: 'test@test.com', username: 'testuser'),
      );
      when(mockRepository.fetchUserProfile(any)).thenAnswer(
        (_) async => Either.left(ServerFailure('Profile not found')),
      );
      when(mockRepository.saveUserProfile(any)).thenAnswer(
        (_) async => Either.right(null),
      );
      authViewModel = AuthViewModel(authRepository: mockRepository);
    });

    tearDown(() {
      authViewModel.dispose();
    });

    Future<void> pumpPage(WidgetTester tester) async {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => ChangeNotifierProvider<AuthViewModel>.value(
              value: authViewModel,
              child: const CompleteProfilePage(),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          locale: const Locale('tr'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('tr'), Locale('en')],
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();
    }

    Finder nameField() => find.byType(TextFormField).first;

    Finder bioField() => find.byType(TextFormField).at(1);

    testWidgets('CompleteProfilePage - Form alanları görünür', (WidgetTester tester) async {
      await pumpPage(tester);

      expect(find.text('Profilini Tamamla'), findsWidgets);
      expect(find.text('İsim Soyisim'), findsOneWidget);
      expect(find.text('Biyografi (Opsiyonel)'), findsOneWidget);
      expect(find.text('Kaydet ve Devam Et'), findsOneWidget);
    });

    testWidgets('CompleteProfilePage - İsim ve biyografi alanları mevcut', (WidgetTester tester) async {
      await pumpPage(tester);

      expect(find.byType(TextFormField), findsNWidgets(2));
    });

    testWidgets('CompleteProfilePage - Profil fotoğrafı seçme alanı görünür', (WidgetTester tester) async {
      await pumpPage(tester);

      expect(find.byType(GestureDetector), findsWidgets);
      expect(find.byIcon(Icons.camera_alt_rounded), findsOneWidget);
    });

    testWidgets('CompleteProfilePage - Form doldurulup kaydet butonu çalışıyor', (WidgetTester tester) async {
      await pumpPage(tester);

      await tester.enterText(nameField(), 'Test Kullanıcı');
      await tester.enterText(bioField(), 'Test biyografi');
      await tester.pump();

      final saveButton = find.text('Kaydet ve Devam Et');
      expect(saveButton, findsOneWidget);

      final buttonRect = tester.getRect(saveButton);
      final screenSize = tester.getSize(find.byType(MaterialApp));
      if (buttonRect.bottom > screenSize.height - 50) {
        await tester.dragUntilVisible(
          saveButton,
          find.byType(SingleChildScrollView),
          const Offset(0, -100),
        );
        await tester.pumpAndSettle();
      }

      await tester.tap(saveButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verify(mockRepository.saveUserProfile(any)).called(1);
      expect(authViewModel.user?.displayName, 'Test Kullanıcı');
      expect(authViewModel.user?.bio, 'Test biyografi');
      expect(authViewModel.needsProfileCompletion, false);
    });

    testWidgets('CompleteProfilePage - Boş form gönderilemez (validasyon çalışıyor)', (WidgetTester tester) async {
      await pumpPage(tester);

      final saveButton = find.text('Kaydet ve Devam Et');
      expect(saveButton, findsOneWidget);

      final buttonRect = tester.getRect(saveButton);
      final screenSize = tester.getSize(find.byType(MaterialApp));
      if (buttonRect.bottom > screenSize.height - 50) {
        await tester.dragUntilVisible(
          saveButton,
          find.byType(SingleChildScrollView),
          const Offset(0, -100),
        );
        await tester.pumpAndSettle();
      }

      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      verifyNever(mockRepository.saveUserProfile(any));
      expect(find.textContaining('zorunludur'), findsWidgets);
    });

    testWidgets('CompleteProfilePage - AppBar görünür', (WidgetTester tester) async {
      await pumpPage(tester);

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Profilini Tamamla'), findsWidgets);
    });
  });
}
