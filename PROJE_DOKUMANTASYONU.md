# 📚 Thunder Projesi - Kapsamlı Dokümantasyon

## 🏗️ 1. MİMARİ YAPISI

### Clean Architecture (Temiz Mimari)

Proje **Clean Architecture** prensiplerine göre yapılandırılmıştır. Bu mimari 3 ana katmandan oluşur:

```
┌─────────────────────────────────────────┐
│     PRESENTATION LAYER (UI)            │
│  - Views (Widgets)                     │
│  - ViewModels (State Management)       │
└─────────────────────────────────────────┘
                    ↓ ↑
┌─────────────────────────────────────────┐
│     DOMAIN LAYER (Business Logic)      │
│  - Use Cases (İş Kuralları)            │
│  - Repository Interfaces               │
│  - Entities (Domain Modelleri)         │
└─────────────────────────────────────────┘
                    ↓ ↑
┌─────────────────────────────────────────┐
│     DATA LAYER (Veri Kaynakları)       │
│  - Repository Implementations          │
│  - Remote Data Sources (Firebase)       │
│  - Local Data Sources (Cache)         │
└─────────────────────────────────────────┘
```

### Katmanların Görevleri:

#### 1. **Domain Layer** (İş Mantığı)
- **Use Cases**: Her bir iş kuralı için ayrı use case
  - `SignInUseCase`: Giriş yapma iş kuralı
  - `SignUpUseCase`: Kayıt olma iş kuralı
  - `SignOutUseCase`: Çıkış yapma iş kuralı
  - `FetchUserProfileUseCase`: Profil getirme iş kuralı
  - `SaveUserProfileUseCase`: Profil kaydetme iş kuralı

- **Repository Interfaces**: Veri kaynaklarına erişim için soyut arayüzler
  - `AuthRepository`: Authentication işlemleri için interface

- **Entities**: Domain modelleri (UserModel, EventModel, vb.)

#### 2. **Data Layer** (Veri Katmanı)
- **Repository Implementations**: Repository interface'lerinin gerçek implementasyonları
  - `AuthRepositoryImpl`: AuthRepository'nin gerçek implementasyonu

- **Remote Data Sources**: Firebase gibi uzak veri kaynakları
  - `AuthRemoteDataSource`: Firebase Auth işlemleri
  - `AuthRemoteDataSourceImpl`: Firebase Auth implementasyonu

- **Local Data Sources**: Yerel cache ve depolama
  - `AuthLocalDataSource`: SharedPreferences cache işlemleri
  - `AuthLocalDataSourceImpl`: SharedPreferences implementasyonu

#### 3. **Presentation Layer** (UI Katmanı)
- **Views**: Flutter widget'ları (UI)
  - `AuthPage`: Giriş/Kayıt sayfası
  - `HomePage`: Ana sayfa
  - `EventListView`: Etkinlik listesi

- **ViewModels**: State management (Provider pattern)
  - `AuthViewModel`: Authentication state yönetimi
  - `EventViewModel`: Event state yönetimi

---

## 🛠️ 2. TEKNOLOJİ STACK

### Ana Framework
- **Flutter**: Cross-platform UI framework (Dart)
- **Dart**: Programming language (SDK ^3.8.1)

### State Management
- **Provider** (^6.1.2): State management için
  - `ChangeNotifierProvider`: ViewModel'ler için
  - `FutureProvider`: Async işlemler için
  - `ChangeNotifierProxyProvider`: Bağımlı provider'lar için

### Backend & Services
- **Firebase Core** (^4.1.0): Firebase başlatma
- **Firebase Auth** (^6.0.2): Kimlik doğrulama
- **Cloud Firestore** (^6.0.1): NoSQL veritabanı
- **Firebase Storage** (^13.0.1): Dosya depolama
- **Firebase Messaging** (^16.0.1): Push bildirimleri

### UI & Design
- **Material Design 3**: Modern UI components
- **Cupertino Icons** (^1.0.8): iOS tarzı ikonlar
- **Cached Network Image** (^3.4.1): Resim cache'leme

### Harita & Konum
- **Google Maps Flutter** (^2.5.0): Harita entegrasyonu
- **Geolocator** (^13.0.1): Konum servisleri

### Medya & Dosya
- **Image Picker** (^1.1.2): Resim seçme
- **Video Player** (^2.10.0): Video oynatma
- **Record** (^6.1.1): Ses kaydı
- **Audio Players** (^6.5.1): Ses oynatma
- **File Picker** (^10.3.3): Dosya seçme

### Depolama & Cache
- **Shared Preferences** (^2.2.2): Key-value storage
- **Hive** (^2.2.3): NoSQL database (local)
- **Hive Flutter** (^1.1.0): Hive Flutter entegrasyonu
- **Path Provider** (^2.1.2): Dosya yolu yönetimi

### Diğer
- **Emoji Picker Flutter** (^4.3.0): Emoji seçici
- **URL Launcher** (^6.2.6): URL açma
- **Permission Handler** (^12.0.1): İzin yönetimi
- **Flutter Localizations**: Çoklu dil desteği

### Test Kütüphaneleri
- **Mockito** (^5.4.4): Mock objeler için
- **Build Runner** (^2.4.8): Code generation
- **Fake Cloud Firestore** (^4.0.0): Firestore mock
- **Integration Test**: End-to-end testler

---

## 📁 3. KLASÖR YAPISI

```
Thunder/
├── lib/                          # Ana kaynak kodları
│   ├── main.dart                 # Uygulama giriş noktası
│   │
│   ├── core/                     # Çekirdek yapılar
│   │   ├── constants/           # Sabitler
│   │   │   └── app_constants.dart
│   │   ├── di/                  # Dependency Injection
│   │   │   └── service_locator.dart
│   │   ├── errors/              # Hata yönetimi
│   │   │   ├── exceptions.dart  # Exception'lar
│   │   │   ├── failures.dart    # Failure'lar
│   │   │   └── error_mapper.dart
│   │   └── utils/               # Yardımcı fonksiyonlar
│   │       └── validators.dart
│   │
│   ├── features/                 # Feature-based yapı (Clean Architecture)
│   │   └── auth/                # Authentication feature
│   │       ├── domain/          # İş mantığı
│   │       │   ├── repositories/
│   │       │   │   └── auth_repository.dart (interface)
│   │       │   └── usecases/    # Use Cases
│   │       │       ├── sign_in_usecase.dart
│   │       │       ├── sign_up_usecase.dart
│   │       │       ├── sign_out_usecase.dart
│   │       │       ├── fetch_user_profile_usecase.dart
│   │       │       ├── save_user_profile_usecase.dart
│   │       │       └── get_current_user_usecase.dart
│   │       ├── data/            # Veri katmanı
│   │       │   ├── datasources/
│   │       │   │   ├── auth_remote_data_source.dart (interface)
│   │       │   │   ├── auth_remote_data_source_impl.dart
│   │       │   │   ├── auth_local_data_source.dart (interface)
│   │       │   │   └── auth_local_data_source_impl.dart
│   │       │   └── repositories/
│   │       │       └── auth_repository_impl.dart
│   │       └── presentation/    # UI katmanı (ileride)
│   │           ├── screens/
│   │           └── viewmodels/
│   │
│   ├── models/                   # Veri modelleri
│   │   ├── user_model.dart
│   │   ├── event_model.dart
│   │   ├── chat_model.dart
│   │   └── message_model.dart
│   │
│   ├── services/                # Servisler (eski yapı, refactor edilecek)
│   │   ├── auth_service.dart
│   │   ├── event_service.dart
│   │   ├── chat_service.dart
│   │   ├── notification_service.dart
│   │   ├── language_service.dart
│   │   ├── audio_service.dart
│   │   ├── cache_service.dart
│   │   ├── user_service.dart
│   │   ├── demo_service.dart
│   │   └── seed_data_service.dart
│   │
│   ├── viewmodels/              # ViewModel'ler (State Management)
│   │   ├── auth_viewmodel.dart  # Clean Architecture kullanıyor
│   │   └── event_viewmodel.dart
│   │
│   ├── views/                   # UI Ekranları
│   │   ├── auth_page.dart
│   │   ├── home_page.dart
│   │   ├── complete_profile_page.dart
│   │   ├── event_list_view.dart
│   │   ├── event_detail_page.dart
│   │   ├── create_event_page.dart
│   │   ├── my_events_page.dart
│   │   ├── chat_list_page.dart
│   │   ├── private_chat_page.dart
│   │   ├── message_search_page.dart
│   │   ├── message_forward_page.dart
│   │   ├── user_search_page.dart
│   │   ├── user_profile_page.dart
│   │   ├── profile_view.dart
│   │   ├── map_view.dart
│   │   └── widgets/             # Yeniden kullanılabilir widget'lar
│   │       ├── app_card.dart
│   │       ├── app_gradient_container.dart
│   │       ├── modern_button.dart
│   │       ├── modern_loading_widget.dart
│   │       ├── language_selector.dart
│   │       ├── file_picker_widget.dart
│   │       ├── file_message_widget.dart
│   │       ├── voice_recorder_widget.dart
│   │       ├── voice_message_widget.dart
│   │       ├── message_reactions.dart
│   │       └── reaction_picker.dart
│   │
│   ├── l10n/                    # Localization (Çoklu dil)
│   │   ├── app_en.arb           # İngilizce çeviriler
│   │   ├── app_tr.arb           # Türkçe çeviriler
│   │   ├── app_localizations.dart
│   │   ├── app_localizations_en.dart
│   │   └── app_localizations_tr.dart
│   │
│   └── firebase_options.dart    # Firebase yapılandırması
│
├── android/                     # Android platform dosyaları
│   ├── app/
│   │   ├── build.gradle.kts     # Android build config
│   │   ├── google-services.json # Firebase config
│   │   └── src/
│   │       └── main/
│   │           ├── AndroidManifest.xml
│   │           └── kotlin/
│   │               └── com/example/thunder/
│   │                   └── MainActivity.kt
│   └── build.gradle.kts
│
├── ios/                         # iOS platform dosyaları
│   ├── Runner/
│   │   ├── AppDelegate.swift
│   │   ├── Info.plist
│   │   └── Assets.xcassets/
│   └── Runner.xcodeproj/
│
├── web/                         # Web platform dosyaları
│   ├── index.html
│   ├── manifest.json
│   ├── firebase-messaging-sw.js
│   └── icons/
│
├── test/                        # Test dosyaları
│   ├── features/
│   ├── services/
│   └── widgets/
│
├── assets/                      # Asset dosyaları
│   └── icons/                   # Uygulama ikonları
│
├── pubspec.yaml                 # Bağımlılıklar ve yapılandırma
├── analysis_options.yaml        # Linter kuralları
└── README.md                    # Proje dokümantasyonu
```

---

## 🔄 4. VERİ AKIŞI (DATA FLOW)

### Authentication Akışı:

```
1. UI (AuthPage)
   ↓
2. ViewModel (AuthViewModel)
   ↓
3. Use Case (SignInUseCase)
   ↓
4. Repository Interface (AuthRepository)
   ↓
5. Repository Implementation (AuthRepositoryImpl)
   ↓
6. Data Sources
   ├── Remote (AuthRemoteDataSourceImpl → Firebase Auth)
   └── Local (AuthLocalDataSourceImpl → SharedPreferences)
   ↓
7. Response → Use Case → ViewModel → UI
```

### Örnek: SignIn İşlemi

```dart
// 1. UI'dan çağrı
AuthPage → authViewModel.signIn(email, password)

// 2. ViewModel
AuthViewModel.signIn() → _signInUseCase(email, password)

// 3. Use Case
SignInUseCase → _authRepository.signIn(email, password)

// 4. Repository Implementation
AuthRepositoryImpl.signIn() → 
  ├── _remoteDataSource.signIn() → Firebase Auth
  └── _localDataSource.cacheUser() → SharedPreferences

// 5. Response
Either<Failure, UserModel> → Use Case → ViewModel → UI
```

---

## 🌐 5. PLATFORM YAPILANDIRMALARI

### Android (`android/`)
- **Build Tool**: Gradle (Kotlin DSL)
- **Min SDK**: Android API level belirtilmeli
- **Target SDK**: Android API level belirtilmeli
- **MainActivity**: Kotlin ile yazılmış
- **Firebase Config**: `google-services.json`
- **Manifest**: `AndroidManifest.xml`

### iOS (`ios/`)
- **Language**: Swift
- **Deployment Target**: iOS versiyonu belirtilmeli
- **AppDelegate**: Swift ile yazılmış
- **Info.plist**: iOS yapılandırması
- **Assets**: App icon ve launch screen

### Web (`web/`)
- **Entry Point**: `index.html`
- **Manifest**: `manifest.json` (PWA için)
- **Service Worker**: `firebase-messaging-sw.js` (Push notifications için)
- **Icons**: PWA icon'ları

---

## 🔌 6. BAĞIMLILIK YÖNETİMİ

### Dependency Injection (DI)

**Service Locator Pattern** kullanılıyor:

```dart
// Service Locator
ServiceLocator()
  ├── registerSingleton<T>()  // Tek instance
  └── registerFactory<T>()    // Her seferinde yeni instance

// Kullanım
final service = ServiceLocator().get<IService>();
```

**Şu an kayıtlı servisler:**
- `IEventService` → `EventService()` (singleton)
- `LanguageService` → `LanguageService()` (singleton)

### Provider Pattern (State Management)

```dart
MultiProvider(
  providers: [
    // FutureProvider: Async işlemler için
    FutureProvider<AuthRepository?>(
      create: (_) => createAuthRepository(),
    ),
    
    // ChangeNotifierProxyProvider: Bağımlı provider'lar için
    ChangeNotifierProxyProvider<AuthRepository?, AuthViewModel>(
      create: (_) => AuthViewModel(...),
      update: (_, repo, previous) => ...,
    ),
    
    // ChangeNotifierProvider: Normal state management
    ChangeNotifierProvider(create: (_) => EventViewModel(...)),
  ],
)
```

---

## 📦 7. KÜTÜPHANELER VE KULLANIM ALANLARI

### Firebase Kütüphaneleri

| Kütüphane | Versiyon | Kullanım Alanı |
|-----------|----------|----------------|
| `firebase_core` | ^4.1.0 | Firebase başlatma |
| `firebase_auth` | ^6.0.2 | Email/Password authentication |
| `cloud_firestore` | ^6.0.1 | NoSQL veritabanı (events, chats, messages) |
| `firebase_storage` | ^13.0.1 | Dosya depolama (resimler, videolar) |
| `firebase_messaging` | ^16.0.1 | Push bildirimleri (FCM) |

### UI & Design

| Kütüphane | Versiyon | Kullanım Alanı |
|-----------|----------|----------------|
| `provider` | ^6.1.2 | State management |
| `cached_network_image` | ^3.4.1 | Resim cache'leme |
| `emoji_picker_flutter` | ^4.3.0 | Emoji seçici |

### Medya & Dosya

| Kütüphane | Versiyon | Kullanım Alanı |
|-----------|----------|----------------|
| `image_picker` | ^1.1.2 | Resim seçme (galeri/kamera) |
| `video_player` | ^2.10.0 | Video oynatma |
| `record` | ^6.1.1 | Ses kaydı |
| `audioplayers` | ^6.5.1 | Ses oynatma |
| `file_picker` | ^10.3.3 | Dosya seçme |

### Harita & Konum

| Kütüphane | Versiyon | Kullanım Alanı |
|-----------|----------|----------------|
| `google_maps_flutter` | ^2.5.0 | Google Maps entegrasyonu |
| `geolocator` | ^13.0.1 | Konum servisleri (GPS) |

### Depolama

| Kütüphane | Versiyon | Kullanım Alanı |
|-----------|----------|----------------|
| `shared_preferences` | ^2.2.2 | Key-value storage (cache) |
| `hive` | ^2.2.3 | NoSQL database (local) |
| `path_provider` | ^2.1.2 | Dosya yolu yönetimi |

### Diğer

| Kütüphane | Versiyon | Kullanım Alanı |
|-----------|----------|----------------|
| `url_launcher` | ^6.2.6 | URL açma (tarayıcı) |
| `permission_handler` | ^12.0.1 | İzin yönetimi (kamera, konum, vb.) |
| `flutter_localizations` | SDK | Çoklu dil desteği |

---

## 🎯 8. CLEAN ARCHITECTURE PRENSİPLERİ

### SOLID Prensipleri

1. **Single Responsibility**: Her sınıf tek bir sorumluluğa sahip
2. **Open/Closed**: Genişlemeye açık, değişikliğe kapalı
3. **Liskov Substitution**: Alt sınıflar üst sınıfların yerine kullanılabilir
4. **Interface Segregation**: İnce interface'ler
5. **Dependency Inversion**: Yüksek seviye modüller düşük seviye modüllere bağımlı değil

### Katman Bağımlılıkları

```
Presentation → Domain ← Data
     ↓           ↑
     └───────────┘
```

- **Presentation** sadece **Domain**'e bağımlı
- **Data** sadece **Domain**'e bağımlı
- **Domain** hiçbir katmana bağımlı değil

---

## 🔐 9. GÜVENLİK

### Authentication
- Firebase Auth ile email/password authentication
- Token-based authentication
- Secure storage için SharedPreferences

### Firestore Security Rules
- Kullanıcı bazlı erişim kontrolü
- `request.auth.uid` ile kullanıcı doğrulama

### Storage Security Rules
- Kullanıcı bazlı dosya erişimi
- Upload/download izinleri

---

## 🌍 10. ÇOKLU DİL DESTEĞİ (i18n)

### Desteklenen Diller
- **Türkçe** (tr) - Varsayılan
- **İngilizce** (en)

### Kullanım
```dart
// Localization dosyaları
lib/l10n/
  ├── app_tr.arb  # Türkçe çeviriler
  └── app_en.arb  # İngilizce çeviriler

// Kodda kullanım
AppLocalizations.of(context)!.signIn
```

### Dil Değiştirme
- `LanguageService` ile dinamik dil değiştirme
- SharedPreferences'te saklanıyor

---

## 🧪 11. TEST YAPISI

### Test Klasörleri
```
test/
├── features/          # Feature testleri
├── services/          # Service testleri
└── widgets/           # Widget testleri
```

### Test Kütüphaneleri
- `flutter_test`: Flutter widget testleri
- `mockito`: Mock objeler
- `fake_cloud_firestore`: Firestore mock
- `integration_test`: End-to-end testler

---

## 📱 12. PLATFORM ÖZELLİKLERİ

### Android
- ✅ Firebase entegrasyonu
- ✅ Google Maps
- ✅ Push notifications (FCM)
- ✅ Background services
- ✅ File picker
- ✅ Camera/Gallery access

### iOS
- ✅ Firebase entegrasyonu
- ✅ Google Maps
- ✅ Push notifications (APNs)
- ✅ File picker
- ✅ Camera/Gallery access

### Web
- ✅ Firebase entegrasyonu
- ✅ Google Maps
- ✅ Push notifications (Service Worker)
- ✅ PWA desteği

---

## 🚀 13. BUILD & DEPLOYMENT

### Build Komutları

```bash
# Debug build
flutter build apk --debug          # Android
flutter build ios --debug          # iOS
flutter build web                  # Web

# Release build
flutter build apk --release        # Android
flutter build ios --release        # iOS
flutter build web --release        # Web
```

### Platform-Specific Builds

**Android:**
- APK: `flutter build apk`
- App Bundle: `flutter build appbundle`

**iOS:**
- IPA: `flutter build ipa`
- Xcode ile build: `open ios/Runner.xcworkspace`

**Web:**
- Static files: `build/web/` klasöründe

---

## 📊 14. PERFORMANS

### Optimizasyonlar
- Image caching (`cached_network_image`)
- Lazy loading (ListView.builder)
- State management (Provider)
- Local caching (SharedPreferences, Hive)

### Memory Management
- Dispose pattern (Controller'ları dispose et)
- Image compression
- List pagination

---

## 🔧 15. GELİŞTİRME ARAÇLARI

### Linter
- `flutter_lints` (^6.0.0)
- `analysis_options.yaml` ile kurallar

### Code Generation
- `build_runner` (^2.4.8)
- Mockito code generation

### Debugging
- Flutter DevTools
- VS Code Flutter extension
- Android Studio Flutter plugin

---

## 📝 16. KOD STİLİ

### Naming Conventions
- **Classes**: PascalCase (`AuthViewModel`)
- **Variables**: camelCase (`userName`)
- **Files**: snake_case (`auth_viewmodel.dart`)
- **Constants**: UPPER_SNAKE_CASE (`MAX_RETRY_COUNT`)

### File Organization
- One class per file
- Feature-based organization
- Clear separation of concerns

---

## 🎓 17. ÖĞRENME KAYNAKLARI

### Flutter
- [Flutter Documentation](https://flutter.dev/docs)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)

### Clean Architecture
- [Clean Architecture by Robert C. Martin](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Flutter Clean Architecture](https://resocoder.com/flutter-clean-architecture-tdd/)

### Firebase
- [Firebase Documentation](https://firebase.google.com/docs)
- [FlutterFire](https://firebase.flutter.dev/)

### Provider
- [Provider Package](https://pub.dev/packages/provider)
- [Flutter State Management](https://flutter.dev/docs/development/data-and-backend/state-mgmt)

---

## ✅ 18. PROJE DURUMU

### Tamamlananlar ✅
- ✅ Clean Architecture yapısı
- ✅ Authentication (SignIn, SignUp, SignOut)
- ✅ Profile management
- ✅ Event management
- ✅ Chat system
- ✅ Google Maps integration
- ✅ Push notifications
- ✅ Multi-language support

### Devam Edenler 🔄
- 🔄 Clean Architecture tam entegrasyonu
- 🔄 Firebase reCAPTCHA yapılandırması
- 🔄 Test coverage artırılması

### Planlananlar 📋
- 📋 Presentation layer refactoring
- 📋 Event ve Chat feature'ları için Clean Architecture
- 📋 Performance optimizasyonları
- 📋 UI/UX iyileştirmeleri

---

## 🎯 SONUÇ

Bu proje **Clean Architecture** prensiplerine göre yapılandırılmış, **Flutter** ve **Firebase** kullanan modern bir mobil uygulamadır. Kod yapısı modüler, test edilebilir ve maintainable'dır.

**Ana Özellikler:**
- ✅ Clean Architecture
- ✅ Provider State Management
- ✅ Firebase Backend
- ✅ Multi-platform (Android, iOS, Web)
- ✅ Multi-language (TR, EN)
- ✅ Modern UI/UX

**Teknoloji Stack:**
- Flutter + Dart
- Firebase (Auth, Firestore, Storage, Messaging)
- Provider (State Management)
- Google Maps
- Material Design 3

