import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'firebase_options.dart';
import 'features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'services/language_service.dart';
import 'services/theme_service.dart';
import 'services/settings_service.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/app_providers.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:go_router/go_router.dart';
import 'core/navigation/app_router.dart';
import 'services/crash_reporting_service.dart';

// Arka plan bildirimleri için handler (üst düzey bir fonksiyon olmalı)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await runZonedGuarded(() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await CrashReportingService.initialize();
    CrashReportingService.installGlobalHandlers();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    final languageService = LanguageService();
    final themeService = ThemeService();
    final settingsService = SettingsService();

    await Future.wait([
      languageService.loadSavedLanguage(),
      themeService.loadSavedTheme(),
      settingsService.loadSettings(),
    ]);

    runApp(MyApp(
      languageService: languageService,
      themeService: themeService,
      settingsService: settingsService,
    ));
  }, CrashReportingService.recordZoneError);
}

class MyApp extends StatefulWidget {
  final LanguageService languageService;
  final ThemeService themeService;
  final SettingsService settingsService;

  const MyApp({
    super.key,
    required this.languageService,
    required this.themeService,
    required this.settingsService,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  GoRouter? _router;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ...AppProviders.getFutureProviders(),
        ...AppProviders.getProxyProviders(),
        ...AppProviders.getProviders(
          languageService: widget.languageService,
          themeService: widget.themeService,
          settingsService: widget.settingsService,
        ),
      ],
      child: Consumer3<LanguageService, ThemeService, AuthViewModel?>(
        builder: (context, languageService, themeService, authViewModel, _) {
          _router ??= AppRouter.createRouter(authViewModel);

          return MaterialApp.router(
            title: 'Thunder',
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('tr', ''),
              Locale('en', ''),
            ],
            locale: languageService.currentLocale,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeService.themeMode,
            debugShowCheckedModeBanner: false,
            routerConfig: _router ?? AppRouter.router,
          );
        },
      ),
    );
  }
}
