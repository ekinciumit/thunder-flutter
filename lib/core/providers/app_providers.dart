import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import '../../features/auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/datasources/auth_local_data_source.dart';
import '../../features/event/presentation/viewmodels/event_viewmodel.dart';
import '../../features/event/domain/repositories/event_repository.dart';
import '../../features/event/data/repositories/event_repository_impl.dart';
import '../../features/event/data/datasources/event_remote_data_source.dart';
import '../../features/chat/presentation/viewmodels/chat_viewmodel.dart';
import '../../features/chat/domain/repositories/chat_repository.dart';
import '../../features/chat/data/repositories/chat_repository_impl.dart';
import '../../features/chat/data/datasources/chat_remote_data_source.dart';
import '../../services/language_service.dart';
import '../../services/theme_service.dart';
import '../../services/settings_service.dart';
import '../../features/user/data/models/user_model.dart';

/// App Providers Configuration
/// 
/// Clean Architecture: Tüm Provider'lar burada yönetiliyor
class AppProviders {
  /// Tüm Provider'ları döndürür
  /// 
  /// Eğer servisler önceden oluşturulmuşsa (main'de), onları kullan
  /// Değilse yeni oluştur (geriye dönük uyumluluk için)
  static List<SingleChildWidget> getProviders({
    LanguageService? languageService,
    ThemeService? themeService,
    SettingsService? settingsService,
  }) {
    final langService = languageService ?? LanguageService();
    final themeSvc = themeService ?? ThemeService();
    final settingsSvc = settingsService ?? SettingsService();
    
    return [
      ChangeNotifierProvider.value(value: langService),
      ChangeNotifierProvider.value(value: themeSvc),
      ChangeNotifierProvider.value(value: settingsSvc),
    ];
  }

  /// FutureProvider'ları döndürür (async repository'ler için)
  static List<SingleChildWidget> getFutureProviders() {
    return [
      // Clean Architecture: FutureProvider ile AuthRepository async oluşturuluyor
      FutureProvider<AuthRepository?>(
        create: (_) async {
          try {
            final repository = await createAuthRepository();
            return repository;
          } catch (e) {
            if (kDebugMode) {
              debugPrint('❌ [APP_PROVIDERS] AuthRepository oluşturulurken hata: $e');
            }
            return null;
          }
        },
        initialData: null,
      ),
      // Clean Architecture: FutureProvider ile EventRepository async oluşturuluyor
      FutureProvider<EventRepository?>(
        create: (_) async {
          try {
            final repository = await createEventRepository();
            return repository;
          } catch (e) {
            if (kDebugMode) {
              debugPrint('❌ [APP_PROVIDERS] EventRepository oluşturulurken hata: $e');
            }
            return null;
          }
        },
        initialData: null,
      ),
      // Clean Architecture: FutureProvider ile ChatRepository async oluşturuluyor
      FutureProvider<ChatRepository?>(
        create: (_) async {
          try {
            final repository = await createChatRepository();
            return repository;
          } catch (e) {
            if (kDebugMode) {
              debugPrint('❌ [APP_PROVIDERS] ChatRepository oluşturulurken hata: $e');
            }
            return null;
          }
        },
        initialData: null,
      ),
    ];
  }

  /// ChangeNotifierProxyProvider'ları döndürür (Repository'ye bağımlı ViewModel'ler için)
  static List<SingleChildWidget> getProxyProviders() {
    return [
      // ChangeNotifierProxyProvider: AuthRepository hazır olunca AuthViewModel oluştur
      ChangeNotifierProxyProvider<AuthRepository?, AuthViewModel>(
        create: (_) {
          final temporaryRepository = _createTemporaryAuthRepository();
          return AuthViewModel(authRepository: temporaryRepository);
        },
        update: (_, authRepository, previous) {
          if (authRepository == null) {
            // Repository henüz hazır değil, temporary ile devam et
            return previous ?? AuthViewModel(authRepository: _createTemporaryAuthRepository());
          }
          // Repository hazır - yeni ViewModel oluştur (state kaybı kabul edilebilir, uygulama başlangıcında)
          // NOT: previous varsa bile yeni oluştur çünkü repository değişti
          return AuthViewModel(authRepository: authRepository);
        },
      ),
      // ChangeNotifierProxyProvider: EventRepository hazır olunca EventViewModel oluştur
      ChangeNotifierProxyProvider<EventRepository?, EventViewModel>(
        create: (_) {
          final temporaryRepository = EventRepositoryImpl(
            remoteDataSource: EventRemoteDataSourceImpl(),
          );
          return EventViewModel(eventRepository: temporaryRepository);
        },
        update: (_, eventRepository, previous) {
          if (eventRepository == null) {
            // Repository henüz hazır değil, temporary ile devam et
            final temporaryRepository = EventRepositoryImpl(
              remoteDataSource: EventRemoteDataSourceImpl(),
            );
            return previous ?? EventViewModel(eventRepository: temporaryRepository);
          }
          // Repository hazır - yeni ViewModel oluştur (state kaybı kabul edilebilir, uygulama başlangıcında)
          // NOT: previous varsa bile yeni oluştur çünkü repository değişti
          return EventViewModel(eventRepository: eventRepository);
        },
      ),
      // ChangeNotifierProxyProvider: ChatRepository hazır olunca ChatViewModel oluştur
      ChangeNotifierProxyProvider<ChatRepository?, ChatViewModel>(
        create: (_) {
          final temporaryRepository = ChatRepositoryImpl(
            remoteDataSource: ChatRemoteDataSourceImpl(),
          );
          return ChatViewModel(chatRepository: temporaryRepository);
        },
        update: (_, chatRepository, previous) {
          if (chatRepository == null) {
            // Repository henüz hazır değil, temporary ile devam et
            final temporaryRepository = ChatRepositoryImpl(
              remoteDataSource: ChatRemoteDataSourceImpl(),
            );
            return previous ?? ChatViewModel(chatRepository: temporaryRepository);
          }
          // Repository hazır - yeni ViewModel oluştur (state kaybı kabul edilebilir, uygulama başlangıcında)
          // NOT: previous varsa bile yeni oluştur çünkü repository değişti
          return ChatViewModel(chatRepository: chatRepository);
        },
      ),
    ];
  }

  /// Geçici AuthRepository oluşturur (sync)
  /// 
  /// Bu fonksiyon sadece Provider'ın create metodunda kullanılır.
  /// SharedPreferences async olduğu için geçici bir local data source kullanır.
  static AuthRepository _createTemporaryAuthRepository() {
    // Geçici local data source: SharedPreferences olmadan çalışır
    final temporaryLocalDataSource = _TemporaryAuthLocalDataSource();
    return AuthRepositoryImpl(
      remoteDataSource: AuthRemoteDataSourceImpl(),
      localDataSource: temporaryLocalDataSource,
    );
  }
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

