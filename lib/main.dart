import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:async';
import 'l10n/app_localizations.dart';
import 'firebase_options.dart';
import 'features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'features/event/presentation/viewmodels/event_viewmodel.dart';
import 'services/language_service.dart';
import 'services/theme_service.dart';
import 'services/settings_service.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/app_providers.dart';
import 'views/home_page.dart';
import 'views/auth_page.dart';
import 'views/complete_profile_page.dart';
import 'services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Arka plan bildirimleri için handler (üst düzey bir fonksiyon olmalı)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // print("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  runApp(const MyApp());
}



class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ...AppProviders.getFutureProviders(),
        ...AppProviders.getProxyProviders(),
        ...AppProviders.getProviders(),
      ],
      child: Consumer2<LanguageService, ThemeService>(
        builder: (context, languageService, themeService, _) {
          return MaterialApp(
            title: 'Thunder',
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('tr', ''), // Türkçe
              Locale('en', ''), // İngilizce
            ],
            locale: languageService.currentLocale, // Dinamik dil
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeService.themeMode, // Dinamik tema
            debugShowCheckedModeBanner: false,
            home: const RootPage(),
          );
        },
      ),
    );
  }
}

class RootPage extends StatefulWidget {
  const RootPage({super.key});

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  NotificationService? _notificationService;
  bool _servicesInitialized = false;

  @override
  void initState() {
    super.initState();
    // Uygulama başlatıldığında kaydedilen ayarları yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final languageService = Provider.of<LanguageService>(context, listen: false);
      languageService.loadSavedLanguage();
      
      final themeService = Provider.of<ThemeService>(context, listen: false);
      themeService.loadSavedTheme();
      
      final settingsService = Provider.of<SettingsService>(context, listen: false);
      settingsService.loadSettings();
    });
  }

  /// Servisleri asenkron olarak başlatır (build metodunu bloklamaz)
  Future<void> _initializeServices(AuthViewModel authViewModel) async {
    if (_servicesInitialized) return;
    
    // Kullanıcı giriş yaptığında ve profil tamamlama gerekmediğinde servisleri başlat
    if (authViewModel.user != null && !authViewModel.needsProfileCompletion) {
      _servicesInitialized = true;
      
      // Bildirim servisini başlat (async, build'i bloklamaz)
      _notificationService = NotificationService();
      unawaited(_notificationService!.initialize(authViewModel));
      
      // Giriş sonrası etkinlik dinlemeyi başlat
      final eventVm = Provider.of<EventViewModel>(context, listen: false);
      eventVm.listenEvents();
    }
  }

  @override
  void dispose() {
    _notificationService?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Clean Architecture: FutureProvider'dan AuthViewModel'i kontrol et
    // ViewModel hazır olana kadar loading göster, hazır olunca kullan
    return Consumer<AuthViewModel?>(
      builder: (context, authViewModel, _) {
        // ViewModel henüz hazır değilse loading göster
        if (authViewModel == null) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        // ViewModel hazır, servisleri başlat (async, build'i bloklamaz)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _initializeServices(authViewModel);
        });
        
        return _buildHome(authViewModel, context);
      },
    );
  }

  Widget _buildHome(AuthViewModel authViewModel, BuildContext context) {
    if (authViewModel.user != null) {
      if (authViewModel.needsProfileCompletion) {
        // SignUp başarılı mesajını burada göster (sadece yeni kayıt olduysa)
        if (authViewModel.justSignedUp) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final l10n = AppLocalizations.of(context);
            if (l10n != null && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.signUpSuccess),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  duration: const Duration(seconds: 3),
                ),
              );
              // Flag'i sıfırla (bir kere göster)
              authViewModel.justSignedUp = false;
            }
          });
        }
        
        return CompleteProfilePage(
          onComplete: (name, bio, photoUrl) async {
            try {
              await authViewModel.completeProfile(
                displayName: name,
                bio: bio,
                photoUrl: photoUrl,
              );
              // Activity result işlenmesi için kısa bir gecikme
              await Future.delayed(const Duration(milliseconds: 300));
            } catch (e) {
              // Hata durumunda sessizce devam et (hata zaten ViewModel'de gösterilir)
              if (kDebugMode) {
                debugPrint('Profil tamamlama hatası: $e');
              }
            }
          },
        );
      }
      return const HomePage();
    }
    return const AuthPage();
  }
}
