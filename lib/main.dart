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
import 'features/event/domain/repositories/event_repository.dart';
import 'features/event/data/repositories/event_repository_impl.dart';
import 'features/chat/domain/repositories/chat_repository.dart';
import 'features/chat/data/repositories/chat_repository_impl.dart';
import 'services/language_service.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/app_providers.dart';
import 'views/home_page.dart';
import 'views/auth_page.dart';
import 'views/complete_profile_page.dart';
import 'services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/di/service_locator.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';

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
  
  // Service Locator'ı başlat ve servisleri kaydet (async, uygulama başlamasını engellemez)
  unawaited(_setupServiceLocator());
  
  runApp(const MyApp());
}

/// Service Locator'ı başlatır ve tüm servisleri kaydeder
/// 
/// Clean Architecture: Repository'ler ve servisler Service Locator'a kaydediliyor
Future<void> _setupServiceLocator() async {
  final sl = ServiceLocator();
  
  // Language servisini kaydet
  sl.registerSingleton<LanguageService>(LanguageService());
  
  // Clean Architecture: Repository'leri kaydet
  try {
    final authRepository = await createAuthRepository();
    sl.registerSingleton<AuthRepository>(authRepository);
    
    final eventRepository = await createEventRepository();
    sl.registerSingleton<EventRepository>(eventRepository);
    
    final chatRepository = await createChatRepository();
    sl.registerSingleton<ChatRepository>(chatRepository);
    
    if (kDebugMode) {
      debugPrint('✅ Service Locator: Tüm repository\'ler kaydedildi');
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('⚠️ Service Locator: Repository kayıt hatası: $e');
    }
  }
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
      child: Consumer<LanguageService>(
        builder: (context, languageService, _) {
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
            themeMode: ThemeMode.light, // Şimdilik sadece aydınlık mod
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
    // Uygulama başlatıldığında kaydedilen dili yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final languageService = Provider.of<LanguageService>(context, listen: false);
      languageService.loadSavedLanguage();
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
