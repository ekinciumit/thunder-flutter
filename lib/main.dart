import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'firebase_options.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/event_viewmodel.dart';
import 'services/auth_service.dart';
import 'services/event_service.dart';
import 'services/language_service.dart';
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
    // Servisleri oluştur ve DI ile ViewModel'lere ver
    final IAuthService authService = AuthService();
    final IEventService eventService = EventService();
    final LanguageService languageService = LanguageService();
    
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel(authService: authService)),
        ChangeNotifierProvider(create: (_) => EventViewModel(eventService: eventService)),
        ChangeNotifierProvider(create: (_) => languageService),
      ],
      child: Consumer<LanguageService>(
        builder: (context, languageService, _) {
          return MaterialApp(
            title: 'Thunder',
            localizationsDelegates: const [
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
    // AuthViewModel'i dinle ve kullanıcı durumuna göre UI'ı ve servisleri yönet
    return Consumer<AuthViewModel>(
      builder: (context, authViewModel, _) {
        // Kullanıcı giriş yaptığında ve profil tamamlama gerekmediğinde bildirim servisini başlat
        if (authViewModel.user != null && !authViewModel.needsProfileCompletion) {
          final notificationService = NotificationService();
          notificationService.initialize();
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
