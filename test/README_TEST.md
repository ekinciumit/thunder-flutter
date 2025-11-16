# 🧪 Thunder - Test Dokümantasyonu

## 📋 Test Stratejisi

### 1. **Unit Testler** (Service'ler için)
- ✅ `AuthService` testleri
- ✅ `ChatService` testleri
- ✅ `EventService` testleri
- ⏳ `UserService` testleri
- ⏳ `NotificationService` testleri

### 2. **Widget Testler** (UI için)
- ✅ `AuthPage` testleri
- ⏳ `HomePage` testleri
- ⏳ `ChatListPage` testleri
- ⏳ `EventListView` testleri

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
flutter test test/services/auth_service_test.dart
```

### Test coverage raporu:
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

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

### Firebase Auth Mock:
```dart
final mockAuth = MockFirebaseAuth(
  mockUser: MockUser(
    uid: 'test-uid',
    email: 'test@example.com',
  ),
  signedIn: true,
);
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

## 📱 Android-Specific Testler

### 1. **Manual Test (Emülatörde)**
```bash
# Emülatörü başlat
flutter emulators --launch <emulator_id>

# Uygulamayı çalıştır
flutter run -d <device_id>

# Hot reload
# Terminal'de 'r' tuşuna bas
```

### 2. **Android Instrumentation Testleri**
Android Studio'da `android/app/src/test/` klasöründe JUnit testleri yazılabilir.

### 3. **Firebase Emulator Testleri**
```bash
# Firebase Emulator'ü başlat
firebase emulators:start

# Test'lerde emulator kullan
export FIRESTORE_EMULATOR_HOST=localhost:8080
export FIREBASE_AUTH_EMULATOR_HOST=localhost:9099
flutter test
```

## 🎯 Endpoint Testleri

### Firebase Services Testleri:

#### 1. **Authentication Endpoints**
- ✅ Sign In
- ✅ Sign Up
- ✅ Sign Out
- ✅ Password Reset

#### 2. **Firestore Endpoints**
- ✅ Users Collection
- ✅ Chats Collection
- ✅ Messages Collection
- ✅ Events Collection

#### 3. **Storage Endpoints**
- ⏳ Image Upload
- ⏳ File Upload
- ⏳ Audio Upload

## 📊 Test Coverage Hedefi

- **Unit Testler**: %80+
- **Widget Testler**: %60+
- **Integration Testler**: %40+

## 🔍 Test Senaryoları

### Authentication Flow:
1. ✅ Başarılı giriş
2. ✅ Başarılı kayıt
3. ✅ Hatalı şifre
4. ✅ E-posta formatı hatası
5. ✅ Çıkış yapma

### Chat Flow:
1. ✅ Özel sohbet oluşturma
2. ✅ Mesaj gönderme
3. ✅ Mesajları getirme
4. ✅ Grup sohbeti oluşturma

### Event Flow:
1. ✅ Etkinlik oluşturma
2. ✅ Etkinliğe katılma
3. ✅ Etkinlikten ayrılma
4. ✅ Etkinlik silme

## 🛠️ Test Geliştirme İpuçları

1. **Mock Kullan**: Gerçek Firebase servislerini kullanmak yerine mock'ları kullan
2. **Isolated Test**: Her test bağımsız çalışmalı
3. **Clear Setup/Teardown**: Test öncesi ve sonrası temizlik yap
4. **Meaningful Assertions**: Anlamlı assertion'lar yaz
5. **Test Coverage**: Kritik fonksiyonları test et

## 📝 Test Yazma Örnekleri

### Service Test Örneği:
```dart
test('signIn - Başarılı giriş', () async {
  // Arrange
  final email = 'test@example.com';
  final password = 'password123';
  
  // Act
  final result = await authService.signIn(email, password);
  
  // Assert
  expect(result, isNotNull);
  expect(result?.email, equals(email));
});
```

### Widget Test Örneği:
```dart
testWidgets('AuthPage - Email field görünür', (WidgetTester tester) async {
  // Arrange & Act
  await tester.pumpWidget(const MaterialApp(home: AuthPage()));
  
  // Assert
  expect(find.byType(TextFormField), findsWidgets);
});
```

## 🚨 Bilinen Sorunlar

1. **AuthService Singleton**: AuthService singleton olduğu için direkt test etmek zor. Dependency injection kullanılmalı.
2. **ChatService Firebase Instance**: ChatService FirebaseFirestore.instance kullandığı için mock'lamak zor.
3. **Integration Test Setup**: Integration testler için Firebase emulator kurulumu gerekli.

## 🔄 Sonraki Adımlar

1. ✅ Test kütüphanelerini ekle
2. ✅ Service testlerini oluştur
3. ✅ Widget testlerini oluştur
4. ⏳ Integration testlerini oluştur
5. ⏳ Firebase Emulator entegrasyonu
6. ⏳ Test coverage raporu
7. ⏳ CI/CD pipeline'a test ekleme

