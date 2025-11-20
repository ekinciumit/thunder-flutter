# 🧪 Thunder - Test Dokümantasyonu

## 📋 Test Stratejisi

### 1. **Unit Testler** (Clean Architecture)
- ✅ **Use Cases**: 163 test
  - Auth: 28 test
  - Event: 50 test
  - Chat: 85 test
- ✅ **Repositories**: 61 test
  - EventRepository: 25 test
  - ChatRepository: 36 test
- ✅ **ViewModels**: 47 test
  - EventViewModel: 22 test
  - ChatViewModel: 25 test
- ✅ **Data Sources**: 17 test
  - AuthRemoteDataSource: 9 test
  - AuthLocalDataSource: 8 test

### 2. **Widget Testler** (UI)
- ✅ `AuthPage` testleri (3 test)
- ✅ `ChatListPage` testleri (3 test)
- ✅ `EventListView` testleri (3 test)
- ✅ `CompleteProfilePage` testleri (6 test)
- ✅ `ProfileView` testleri (11 test)
- ✅ `ReactionPicker` testleri (6 test)
- ✅ `FilePickerWidget` testleri (6 test)
- ✅ `AppCard` testleri (4 test)
- ✅ `AppGradientContainer` testleri (4 test)
- ✅ `ModernButton` testleri (7 test)
- ✅ `CacheService` testleri (8 test)
- ✅ `ModernLoadingWidget` testleri (7 test)
- ✅ `MessageReactions` testleri (6 test)
- ✅ `FileMessageWidget` testleri (10 test)
- ✅ `LanguageSelector` testleri (6 test)
- ✅ `VoiceMessageWidget` testleri (5 test)
- ✅ `VoiceRecorderWidget` testleri (2 test)
- ⏳ `HomePage` testleri
- ⏳ `PrivateChatPage` testleri

### 3. **Integration Testler** (End-to-end)
- ⏳ Authentication flow testleri
- ⏳ Chat flow testleri
- ⏳ Event creation flow testleri

## 🚀 Test Çalıştırma

### Tüm testleri çalıştır:
```bash
flutter test
```

### Belirli bir test dosyasını çalıştır:
```bash
flutter test test/features/auth/domain/usecases/sign_in_usecase_test.dart
```

### Test coverage raporu:
```bash
flutter test --coverage
```
Coverage HTML raporunu görüntülemek için:
1. `coverage/coverage_viewer.html` dosyasını tarayıcıda açın
2. Dosya aynı klasördeki `lcov.info` dosyasını otomatik olarak yükler ve gösterir

### Integration testleri:
```bash
flutter drive --target=test_driver/app.dart
```

## 📦 Test Kütüphaneleri

- **mockito** - Mock objeler oluşturmak için
- **fake_cloud_firestore** - Firestore'u mock'lamak için
- **firebase_auth_mocks** - Firebase Auth'u mock'lamak için
- **integration_test** - Integration testler için

## 🔧 Mock Kullanımı

### Repository Mock:
```dart
@GenerateMocks([AuthRepository])
void main() {
  late MockAuthRepository mockRepository;
  
  setUp(() {
    mockRepository = MockAuthRepository();
  });
  
  test('should return Right when successful', () async {
    when(mockRepository.signIn(any, any))
        .thenAnswer((_) async => Either.right(testUser));
    
    final result = await useCase.call(email, password);
    expect(result.isRight, true);
  });
}
```

### Firestore Mock:
```dart
final fakeFirestore = FakeFirebaseFirestore();

// Veri ekleme
await fakeFirestore.collection('users').doc('user-1').set({
  'email': 'test@example.com',
  'name': 'Test User',
});

// Veri okuma
final doc = await fakeFirestore.collection('users').doc('user-1').get();
```

## 📊 Test Coverage Durumu

### Mevcut Durum (2024):
- **Unit Testler**: 313 test ✅
- **Widget Testler**: 3 test ⚠️
- **Integration Testler**: 0 test ❌
- **Toplam**: 316 test
- **Başarı Oranı**: %100 ✅

### Hedefler:
- **Unit Testler**: %80+ ✅ (Mevcut: ~%85)
- **Widget Testler**: %60+ ⏳ (Mevcut: ~%10)
- **Integration Testler**: %40+ ⏳ (Mevcut: %0)

## 🔍 Test Senaryoları

### Authentication Flow:
1. ✅ Başarılı giriş (Use Case testi)
2. ✅ Başarılı kayıt (Use Case testi)
3. ✅ Hatalı şifre (Use Case testi)
4. ✅ E-posta formatı hatası (Use Case testi)
5. ✅ Çıkış yapma (Use Case testi)
6. ⏳ End-to-end giriş akışı (Integration testi)

### Chat Flow:
1. ✅ Özel sohbet oluşturma (Use Case testi)
2. ✅ Mesaj gönderme (Use Case testi)
3. ✅ Mesajları getirme (Use Case testi)
4. ✅ Grup sohbeti oluşturma (Use Case testi)
5. ✅ Reaction ekleme/çıkarma (Use Case testi)
6. ✅ Mesaj arama (Use Case testi)
7. ⏳ End-to-end mesaj gönderme akışı (Integration testi)

### Event Flow:
1. ✅ Etkinlik oluşturma (Use Case testi)
2. ✅ Etkinliğe katılma (Use Case testi)
3. ✅ Etkinlikten ayrılma (Use Case testi)
4. ✅ Etkinlik silme (Use Case testi)
5. ✅ Join request gönderme/onaylama (Use Case testi)
6. ⏳ End-to-end etkinlik oluşturma akışı (Integration testi)

## 🛠️ Test Geliştirme İpuçları

1. **Mock Kullan**: Gerçek Firebase servislerini kullanmak yerine mock'ları kullan
2. **Isolated Test**: Her test bağımsız çalışmalı
3. **Clear Setup/Teardown**: Test öncesi ve sonrası temizlik yap
4. **Meaningful Assertions**: Anlamlı assertion'lar yaz
5. **Test Coverage**: Kritik fonksiyonları test et
6. **AAA Pattern**: Arrange → Act → Assert

## 📝 Test Yazma Örnekleri

### Use Case Test Örneği:
```dart
@GenerateMocks([AuthRepository])
void main() {
  late SignInUseCase useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = SignInUseCase(mockRepository);
  });

  test('should return Right(UserModel) when sign in is successful', () async {
    // Arrange
    when(mockRepository.signIn(email, password))
        .thenAnswer((_) async => Either.right(testUser));

    // Act
    final result = await useCase.call(email, password);

    // Assert
    expect(result.isRight, true);
    expect(result.right, testUser);
    verify(mockRepository.signIn(email, password)).called(1);
  });
}
```

### Widget Test Örneği:
```dart
testWidgets('AuthPage - Email ve password field\'ları görünür', (tester) async {
  // Arrange
  final mockRepository = MockAuthRepository();
  when(mockRepository.getCurrentUser()).thenReturn(null);
  final authViewModel = AuthViewModel(authRepository: mockRepository);
  
  // Act
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('tr'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: ChangeNotifierProvider<AuthViewModel>.value(
        value: authViewModel,
        child: const AuthPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  
  // Assert
  expect(find.byType(TextField), findsNWidgets(2));
});
```

## 🏗️ Clean Architecture Test Yapısı

```
test/
├── features/
│   ├── auth/
│   │   ├── domain/usecases/     # Use Case testleri
│   │   ├── data/repositories/   # Repository testleri
│   │   └── data/datasources/    # Data Source testleri
│   ├── event/
│   │   ├── domain/usecases/     # Use Case testleri
│   │   ├── data/repositories/   # Repository testleri
│   │   └── presentation/viewmodels/ # ViewModel testleri
│   └── chat/
│       ├── domain/usecases/     # Use Case testleri
│       ├── data/repositories/   # Repository testleri
│       └── presentation/viewmodels/ # ViewModel testleri
└── widgets/
    └── auth_page_test.dart       # Widget testleri
```

## ✅ Bugün Yapılanlar (Güncel Durum)

### Data Source Testleri
- ✅ **ChatRemoteDataSource**: 36 test eklendi
  - Tüm metodlar test edildi (17 metod)
  - `FakeFirebaseFirestore` ile mock testler
  - Production bug düzeltildi: `Timestamp` kullanımı
  
- ✅ **EventRemoteDataSource**: 22 test eklendi
  - Tüm metodlar test edildi (12 metod)
  - `FakeFirebaseFirestore` ile mock testler

### Model Testleri
- ✅ **UserModel**: 13 test eklendi
  - `fromMap`, `toMap`, `copyWith` testleri
  - Round-trip testleri
  
- ✅ **EventModel**: 13 test eklendi
  - `fromMap`, `toMap`, `copyWith` testleri
  - GeoPoint ve Timestamp testleri
  
- ✅ **MessageModel**: 16 test eklendi
  - `fromMap`, `toMap`, `copyWith` testleri
  - Reactions parsing testleri
  - Equality testleri
  
- ✅ **ChatModel + ChatParticipant**: 17 test eklendi
  - `fromMap`, `toMap`, `copyWith` testleri
  - Participant details testleri

### ViewModel Testleri
- ✅ **AuthViewModel**: 19 test eklendi
  - Tüm metodlar test edildi
  - Use case injection ile test edilebilirlik artırıldı

### Özet
- **Yeni eklenen test sayısı**: 117 test
- **Coverage artışı**: %32.8 → %35.7 (+2.9 puan)
- **Toplam test sayısı**: 449 test (önceki: 332)
- **Tüm testler geçiyor**: %100 başarı oranı

## 🎯 Yarın Yapılacaklar

### Widget Testleri (Öncelik: Yüksek)
1. ⏳ **CompleteProfilePage** widget testi
   - Form alanları render testi
   - Image picker testi (mock)
   - Validation testleri
   
2. ⏳ **ProfileView** widget testi
   - Widget render testi
   - Image picker testi (mock)
   - Animation testleri
   - Edit mode testleri

3. ⏳ **Basit widget testleri**
   - Diğer basit widget'ları test et

### Coverage Analizi
4. ⏳ **Coverage HTML raporu oluştur**
   - `genhtml coverage/lcov.info -o coverage/html`
   - Eksik testleri belirle
   - Coverage %40+ hedefine ulaş

### Integration Testleri (Sonraki Aşama)
5. ⏳ **Authentication flow** testi
   - End-to-end giriş → profil tamamlama
   
6. ⏳ **Event creation flow** testi
   - Etkinlik oluşturma akışı
   
7. ⏳ **Chat flow** testi
   - Mesaj gönderme akışı

## 📈 Test Metrikleri (Güncel)

- **Toplam Test**: 537
- **Geçen Test**: 537
- **Başarısız Test**: 0
- **Test Süresi**: ~35 saniye
- **Başarı Oranı**: %100 ✅
- **Coverage**: ~%38.5+ (hedef: %40+)

### Test Dağılımı
- **Unit Tests**: 440 test ✅
  - Use Cases: 163 test
  - Repositories: 61 test
  - ViewModels: 66 test
  - Data Sources: 94 test
  - Models: 59 test
  
- **Widget Tests**: 99 test ⏳
  - AuthPage: 3 test
  - EventListView: 3 test
  - ChatListPage: 3 test
  - CompleteProfilePage: 6 test
  - ProfileView: 11 test
  - ReactionPicker: 6 test
  - FilePickerWidget: 6 test
  - AppCard: 4 test
  - AppGradientContainer: 4 test
  - ModernButton: 7 test
  - ModernLoadingWidget: 7 test
  - MessageReactions: 6 test
  - FileMessageWidget: 10 test
  - LanguageSelector: 6 test
  - VoiceMessageWidget: 5 test
  - VoiceRecorderWidget: 2 test
  
- **Integration Tests**: 0 test ❌

## 🎯 Test Türleri

### Unit Tests
- **Use Cases**: Business logic testleri
- **Repositories**: Data mapping testleri
- **ViewModels**: State management testleri
- **Data Sources**: API/Firebase mock testleri

### Widget Tests
- UI render testleri
- User interaction testleri
- Localization testleri

### Integration Tests
- End-to-end flow testleri
- Feature interaction testleri
- Real Firebase testleri (emulator ile)
