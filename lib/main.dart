import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'firebase_options.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/event_viewmodel.dart';
import 'services/event_service.dart';
import 'services/language_service.dart';
import 'views/home_page.dart';
import 'views/auth_page.dart';
import 'views/complete_profile_page.dart';
import 'services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/di/service_locator.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/datasources/auth_local_data_source.dart';
import 'models/user_model.dart';

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
  
  // Service Locator'ı başlat ve servisleri kaydet
  _setupServiceLocator();
  
  runApp(const MyApp());
}

/// Service Locator'ı başlatır ve tüm servisleri kaydeder
/// 
/// ŞU AN: Bu fonksiyon sadece servisleri kaydediyor, mevcut kod çalışmaya devam ediyor
/// İleride Service Locator'dan servisleri alacağız
void _setupServiceLocator() {
  final sl = ServiceLocator();
  
  // Event servisini kaydet
  sl.registerSingleton<IEventService>(EventService());
  
  // Language servisini kaydet
  sl.registerSingleton<LanguageService>(LanguageService());
  
  // Not: AuthService artık kullanılmıyor, Clean Architecture Repository kullanılıyor
}

/// Geçici AuthRepository oluşturur (sync)
/// 
/// Bu fonksiyon sadece Provider'ın create metodunda kullanılır.
/// SharedPreferences async olduğu için geçici bir local data source kullanır.
/// Gerçek repository FutureProvider tarafından async oluşturulur.
AuthRepository _createTemporaryAuthRepository() {
  // Geçici local data source: cache işlemleri yapmaz (sadece Provider için)
  final temporaryLocalDataSource = _TemporaryAuthLocalDataSource();
  
  return AuthRepositoryImpl(
    remoteDataSource: AuthRemoteDataSourceImpl(),
    localDataSource: temporaryLocalDataSource,
  );
}

/// Geçici AuthLocalDataSource implementasyonu
/// 
/// Bu sınıf sadece Provider'ın create metodunda kullanılır.
/// Cache işlemleri yapmaz, sadece interface'i implement eder.
class _TemporaryAuthLocalDataSource implements AuthLocalDataSource {
  @override
  Future<void> cacheUser(UserModel user) async {
    // Geçici data source, cache yapmaz
  }

  @override
  Future<UserModel?> getCachedUser() async {
    // Geçici data source, cache'den okumaz
    return null;
  }

  @override
  Future<void> clearCache() async {
    // Geçici data source, cache temizlemez
  }
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Servisleri oluştur ve DI ile ViewModel'lere ver
    final IEventService eventService = EventService();
    final LanguageService languageService = LanguageService();
    
    return MultiProvider(
      providers: [
        // Clean Architecture: FutureProvider ile AuthRepository async oluşturuluyor
        // Repository hazır olunca ChangeNotifierProxyProvider ile ViewModel oluşturuluyor
        FutureProvider<AuthRepository?>(
          create: (_) async {
            try {
              // Repository'yi oluştur
              final repository = await createAuthRepository();
              if (kDebugMode) {
                debugPrint('✅ Yeni AuthRepository aktif edildi (Clean Architecture)');
              }
              return repository;
            } catch (e) {
              if (kDebugMode) {
                debugPrint('⚠️ AuthRepository oluşturulamadı: $e');
              }
              return null;
            }
          },
          initialData: null, // Başlangıçta null
        ),
        // ChangeNotifierProxyProvider: AuthRepository hazır olunca AuthViewModel oluştur
        // Bu sayede AuthViewModel ChangeNotifier olarak kalır ve notifyListeners() çalışır
        ChangeNotifierProxyProvider<AuthRepository?, AuthViewModel>(
          create: (_) {
            // create metodu sync olmalı, bu yüzden geçici bir repository ile geçici ViewModel oluşturuyoruz
            // update metodunda gerçek repository ile değiştirilecek
            // Geçici repository: SharedPreferences olmadan oluşturuluyor (sadece Provider için)
            final temporaryRepository = _createTemporaryAuthRepository();
            return AuthViewModel(authRepository: temporaryRepository);
          },
          update: (_, authRepository, previous) {
            // Repository hazır değilse önceki ViewModel'i koru
            if (authRepository == null) {
              return previous ?? AuthViewModel(authRepository: _createTemporaryAuthRepository());
            }
            
            // Önceki ViewModel varsa, aynı ViewModel'i döndür
            // (Bu sayede state korunur)
            if (previous != null) {
              // Repository değiştiyse ViewModel'i güncelle
              // Not: Normalde bu durum oluşmamalı çünkü repository singleton
              return previous;
            }
            
            // Yeni ViewModel oluştur (gerçek repository ile)
            return AuthViewModel(authRepository: authRepository);
          },
        ),
        ChangeNotifierProvider(create: (_) => EventViewModel(eventService: eventService)),
        ChangeNotifierProvider(create: (_) => languageService),
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
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6366F1), // Modern indigo
            brightness: Brightness.light,
            primary: const Color(0xFF6366F1), // Indigo
            onPrimary: const Color(0xFFFFFFFF), // White on primary
            primaryContainer: const Color(0xFFE0E7FF), // Light indigo
            onPrimaryContainer: const Color(0xFF1E1B93), // Dark indigo
            secondary: const Color(0xFF8B5CF6), // Purple
            onSecondary: const Color(0xFFFFFFFF), // White on secondary
            secondaryContainer: const Color(0xFFF3E8FF), // Light purple
            onSecondaryContainer: const Color(0xFF4C1D95), // Dark purple
            tertiary: const Color(0xFF06B6D4), // Cyan
            onTertiary: const Color(0xFFFFFFFF), // White on tertiary
            tertiaryContainer: const Color(0xFFCCFBF1), // Light cyan
            onTertiaryContainer: const Color(0xFF0F766E), // Dark cyan
            error: const Color(0xFFDC2626), // Red
            onError: const Color(0xFFFFFFFF), // White on error
            errorContainer: const Color(0xFFFEE2E2), // Light red
            onErrorContainer: const Color(0xFF991B1B), // Dark red
            surface: const Color(0xFFFFFBFE), // Pure white
            onSurface: const Color(0xFF1C1B1F), // Dark text
            surfaceContainerHighest: const Color(0xFFF3F4F6), // Light gray
            onSurfaceVariant: const Color(0xFF49454F), // Medium gray text
            outline: const Color(0xFF79747E), // Border color
            outlineVariant: const Color(0xFFCAC4D0), // Light border
            shadow: const Color(0xFF000000), // Black shadow
            scrim: const Color(0xFF000000), // Black scrim
            inverseSurface: const Color(0xFF313033), // Dark surface
            onInverseSurface: const Color(0xFFF4EFF4), // Light text on dark
            inversePrimary: const Color(0xFFA5B4FC), // Light indigo
          ),
          textTheme: TextTheme(
            displayLarge: TextStyle(
              fontSize: 32, 
              fontWeight: FontWeight.bold, 
              letterSpacing: -0.5,
              color: const Color(0xFF1C1B1F), // High contrast dark
            ),
            displayMedium: TextStyle(
              fontSize: 28, 
              fontWeight: FontWeight.bold, 
              letterSpacing: -0.25,
              color: const Color(0xFF1C1B1F),
            ),
            displaySmall: TextStyle(
              fontSize: 24, 
              fontWeight: FontWeight.w600, 
              letterSpacing: 0,
              color: const Color(0xFF1C1B1F),
            ),
            headlineLarge: TextStyle(
              fontSize: 22, 
              fontWeight: FontWeight.w600, 
              letterSpacing: 0,
              color: const Color(0xFF1C1B1F),
            ),
            headlineMedium: TextStyle(
              fontSize: 20, 
              fontWeight: FontWeight.w600, 
              letterSpacing: 0.15,
              color: const Color(0xFF1C1B1F),
            ),
            headlineSmall: TextStyle(
              fontSize: 18, 
              fontWeight: FontWeight.w600, 
              letterSpacing: 0.15,
              color: const Color(0xFF1C1B1F),
            ),
            titleLarge: TextStyle(
              fontSize: 16, 
              fontWeight: FontWeight.w600, 
              letterSpacing: 0.15,
              color: const Color(0xFF1C1B1F),
            ),
            titleMedium: TextStyle(
              fontSize: 14, 
              fontWeight: FontWeight.w500, 
              letterSpacing: 0.1,
              color: const Color(0xFF49454F), // Medium contrast
            ),
            titleSmall: TextStyle(
              fontSize: 12, 
              fontWeight: FontWeight.w500, 
              letterSpacing: 0.1,
              color: const Color(0xFF49454F),
            ),
            bodyLarge: TextStyle(
              fontSize: 16, 
              fontWeight: FontWeight.normal, 
              letterSpacing: 0.15,
              color: const Color(0xFF1C1B1F),
            ),
            bodyMedium: TextStyle(
              fontSize: 14, 
              fontWeight: FontWeight.normal, 
              letterSpacing: 0.25,
              color: const Color(0xFF49454F),
            ),
            bodySmall: TextStyle(
              fontSize: 12, 
              fontWeight: FontWeight.normal, 
              letterSpacing: 0.4,
              color: const Color(0xFF79747E), // Lower contrast for secondary text
            ),
            labelLarge: TextStyle(
              fontSize: 14, 
              fontWeight: FontWeight.w500, 
              letterSpacing: 0.1,
              color: const Color(0xFF1C1B1F),
            ),
            labelMedium: TextStyle(
              fontSize: 12, 
              fontWeight: FontWeight.w500, 
              letterSpacing: 0.5,
              color: const Color(0xFF49454F),
            ),
            labelSmall: TextStyle(
              fontSize: 10, 
              fontWeight: FontWeight.w500, 
              letterSpacing: 0.5,
              color: const Color(0xFF79747E),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              textStyle: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.1),
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              textStyle: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.1),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              textStyle: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.1),
            ),
          ),
          cardTheme: CardThemeData(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          // ... (isteğe bağlı olarak karanlık tema tanımlanabilir)
        ),
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
  @override
  void initState() {
    super.initState();
    // Uygulama başlatıldığında kaydedilen dili yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final languageService = Provider.of<LanguageService>(context, listen: false);
      languageService.loadSavedLanguage();
    });
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
        
        // ViewModel hazır, kullan
        // Kullanıcı giriş yaptığında ve profil tamamlama gerekmediğinde bildirim servisini başlat
        if (authViewModel.user != null && !authViewModel.needsProfileCompletion) {
          final notificationService = NotificationService();
          notificationService.initialize(authViewModel);
          // Giriş sonrası etkinlik dinlemeyi başlat
          final eventVm = Provider.of<EventViewModel>(context, listen: false);
          eventVm.listenEvents();
        }
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
            await authViewModel.completeProfile(
              displayName: name,
              bio: bio,
              photoUrl: photoUrl,
            );
            WidgetsBinding.instance.addPostFrameCallback((_) {
              // İleride context tabanlı bir işlem eklenirse burada güvenli olur
            });
          },
        );
      }
      return const HomePage();
    }
    return const AuthPage();
  }
}
