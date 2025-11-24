# 📚 Flutter ve Mobil Geliştirme - Ders Notları

> Bu dosya Flutter ve mobil geliştirme için temel kavramları içerir.  
> Thunder projesi üzerinden örneklerle açıklanmıştır.

---

## 📋 İçindekiler

1. [Temel Kavramlar](#1-temel-kavramlar)
2. [Veri Yapıları](#2-veri-yapıları)
3. [Clean Architecture Katmanları](#3-clean-architecture-katmanları)
4. [Veri Akışı](#4-veri-akışı-clean-architecture)
5. [Async İşlemler](#5-async-işlemler)
6. [State Management](#6-state-management)
7. [Dependency Injection](#7-dependency-injection-bağımlılık-yönetimi)
8. [Hata Yönetimi](#8-hata-yönetimi)
9. [Firebase Terimleri](#9-firebase-terimleri)
10. [Diğer Önemli Terimler](#10-diğer-önemli-terimler)
11. [Özet Tablo](#özet-tablo)
12. [Pratik Örnekler](#pratik-örnekler)

---

## 1. Temel Kavramlar

### Widget
**Ne?** Flutter'da ekrandaki her şey bir widget'tır.

**Örnek:**
```dart
Text('Merhaba')        // Widget
ElevatedButton(...)    // Widget
Scaffold(...)          // Widget
```

**Benzetme:** LEGO parçaları gibi, birleştirerek ekran oluştururuz.

---

### State (Durum)
**Ne?** Değişebilen veri.

**Örnek:**
```dart
bool isLoading = false;  // State: Yükleniyor mu?
String? userName;        // State: Kullanıcı adı
```

**Benzetme:** Lamba açık/kapalı durumu gibi.

---

### BuildContext
**Ne?** Widget'ın konumu ve çevresi (tema, dil, navigasyon).

**Örnek:**
```dart
Text(AppLocalizations.of(context)!.login)  // context ile dil al
Navigator.push(context, ...)               // context ile sayfa değiştir
```

**Benzetme:** Adres gibi, nerede olduğunu söyler.

---

## 2. Veri Yapıları

### Model
**Ne?** Veri yapısı (kullanıcı, etkinlik, mesaj).

**Örnek:**
```dart
class UserModel {
  final String uid;        // Kullanıcı ID
  final String email;      // E-posta
  final String? name;     // İsim (opsiyonel)
  
  // JSON'dan model oluştur
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'],
      email: map['email'],
      name: map['name'],
    );
  }
  
  // Model'den JSON'a çevir
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
    };
  }
}
```

**Benzetme:** Form şablonu gibi, veriyi yapılandırır.

**Nerede?** `lib/models/` klasöründe.

---

## 3. Clean Architecture Katmanları

### Data Source (Veri Kaynağı)
**Ne?** Firebase/API ile doğrudan konuşan katman.

**Örnek:**
```dart
class AuthRemoteDataSource {
  // Firebase'e direkt bağlan
  Future<UserModel> signIn(String email, String password) async {
    final userCredential = await FirebaseAuth.instance
        .signInWithEmailAndPassword(email: email, password: password);
    
    return UserModel.fromFirebaseUser(userCredential.user!);
  }
}
```

**Benzetme:** Kasiyer gibi, dışarıyla (Firebase) konuşur.

**Nerede?** `lib/features/[feature]/data/datasources/` klasöründe.

---

### Repository (Repo)
**Ne?** Veri kaynağını sarmalayan, iş mantığına veri sağlayan katman.

**İki Parça:**

#### 1. Interface (Soyut - Ne Yapılacağını Söyler)
```dart
// domain/repositories/auth_repository.dart
abstract class AuthRepository {
  Future<Either<Failure, UserModel>> signIn(String email, String password);
  // Sadece "ne yapılacağını" söyler, "nasıl yapılacağını" değil
}
```

#### 2. Implementation (Somut - Nasıl Yapılacağını Söyler)
```dart
// data/repositories/auth_repository_impl.dart
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  
  @override
  Future<Either<Failure, UserModel>> signIn(...) async {
    try {
      final user = await _remoteDataSource.signIn(...);  // Data Source'u çağır
      return Either.right(user);  // Başarılı
    } catch (e) {
      return Either.left(ServerFailure(...));  // Hata
    }
  }
}
```

**Benzetme:** Müdür gibi, kasiyerden (Data Source) alır, üst katmana (Use Case) sunar.

**Nerede?** 
- Interface: `lib/features/[feature]/domain/repositories/`
- Implementation: `lib/features/[feature]/data/repositories/`

---

### Use Case
**Ne?** Tek bir iş kuralını yapan, Repository kullanan katman.

**Örnek:**
```dart
class SignInUseCase {
  final AuthRepository _repository;
  
  SignInUseCase(this._repository);
  
  Future<Either<Failure, UserModel>> call(String email, String password) async {
    // Business logic: Email ve password boş olamaz
    if (email.isEmpty || password.isEmpty) {
      return Either.left(ValidationFailure('Boş olamaz'));
    }
    
    // Repository'yi kullan
    return await _repository.signIn(email, password);
  }
}
```

**Benzetme:** İş kuralı gibi, "şifre en az 6 karakter" gibi kuralları uygular.

**Nerede?** `lib/features/[feature]/domain/usecases/` klasöründe.

---

### ViewModel
**Ne?** UI state'ini yöneten, Use Case'leri çağıran katman.

**Örnek:**
```dart
class AuthViewModel extends ChangeNotifier {
  bool isLoading = false;  // State
  UserModel? user;         // State
  String? error;           // State
  
  final SignInUseCase _signInUseCase;
  
  Future<void> signIn(String email, String password) async {
    isLoading = true;      // State değişti
    notifyListeners();      // UI'a haber ver
    
    final result = await _signInUseCase(email, password);  // Use Case'i çağır
    
    if (result.isRight) {
      user = result.right;  // Başarılı
    } else {
      error = result.left.message;  // Hata
    }
    
    isLoading = false;
    notifyListeners();      // UI'a tekrar haber ver
  }
}
```

**Benzetme:** Sunucu gibi, mutfaktan (Use Case) alır, müşteriye (UI) sunar.

**Nerede?** `lib/features/[feature]/presentation/viewmodels/` klasöründe.

---

## 4. Veri Akışı (Clean Architecture)

### Akış Şeması
```
UI (View)
  ↓
ViewModel (State Management)
  ↓
Use Case (Business Logic)
  ↓
Repository (Data Management)
  ↓
Data Source (Firebase/API)
  ↓
Firebase/API
```

### Detaylı Örnek
```dart
// 1. UI: Kullanıcı "Giriş Yap" butonuna tıklar
ElevatedButton(
  onPressed: () => authViewModel.signIn(email, password),
  child: Text('Giriş Yap'),
)

// 2. ViewModel: State'i güncelle, Use Case'i çağır
class AuthViewModel {
  Future<void> signIn(...) async {
    isLoading = true;
    notifyListeners();  // UI'a "yükleniyor" göster
    
    final result = await _signInUseCase(...);  // Use Case'e git
    // ...
  }
}

// 3. Use Case: Business logic kontrol et, Repository'ye git
class SignInUseCase {
  Future<Either<Failure, UserModel>> call(...) async {
    if (email.isEmpty) {
      return Either.left(ValidationFailure('Boş olamaz'));
    }
    return await _repository.signIn(...);  // Repository'ye git
  }
}

// 4. Repository: Data Source'u çağır, hata yönetimi yap
class AuthRepositoryImpl {
  Future<Either<Failure, UserModel>> signIn(...) async {
    try {
      final user = await _remoteDataSource.signIn(...);  // Data Source'a git
      return Either.right(user);
    } catch (e) {
      return Either.left(ServerFailure(...));
    }
  }
}

// 5. Data Source: Firebase'e bağlan
class AuthRemoteDataSource {
  Future<UserModel> signIn(...) async {
    final userCredential = await FirebaseAuth.instance
        .signInWithEmailAndPassword(...);  // Firebase'e git
    return UserModel.fromFirebaseUser(userCredential.user!);
  }
}
```

---

## 5. Async İşlemler

### Future
**Ne?** Gelecekte tamamlanacak işlem (ağ çağrısı, dosya okuma).

**Örnek:**
```dart
Future<String> fetchData() async {
  await Future.delayed(Duration(seconds: 2));  // 2 saniye bekle
  return 'Veri geldi!';
}

// Kullanım
final data = await fetchData();  // Bekle, sonra devam et
print(data);  // "Veri geldi!"
```

**Benzetme:** Sipariş vermek gibi, yemek hazır olunca gelir.

---

### Async/Await
**Ne?** Asenkron işlemleri sıralı gibi yazmayı sağlar.

**Örnek:**
```dart
// ❌ KÖTÜ (callback hell)
fetchUser((user) {
  fetchEvents((events) {
    fetchMessages((messages) {
      // 3 katmanlı callback
    });
  });
});

// ✅ İYİ (async/await)
Future<void> loadData() async {
  final user = await fetchUser();      // Bekle
  final events = await fetchEvents();   // Bekle
  final messages = await fetchMessages(); // Bekle
  // Temiz ve okunabilir
}
```

---

### Stream
**Ne?** Sürekli gelen veri akışı (gerçek zamanlı mesajlar).

**Örnek:**
```dart
// Firestore'dan sürekli mesaj dinle
Stream<List<Message>> getMessages(String chatId) {
  return FirebaseFirestore.instance
      .collection('messages')
      .where('chatId', isEqualTo: chatId)
      .snapshots()  // Stream: Her değişiklikte yeni veri gelir
      .map((snapshot) => snapshot.docs.map((doc) => Message.fromMap(doc.data())).toList());
}

// Kullanım
getMessages('chat123').listen((messages) {
  // Her yeni mesaj geldiğinde bu çalışır
  print('Yeni mesaj: ${messages.length}');
});
```

**Benzetme:** Canlı yayın gibi, sürekli yeni veri gelir.

---

## 6. State Management

### Provider
**Ne?** State'i UI'a sağlayan ve değişiklikleri dinleyen sistem.

**Örnek:**
```dart
// 1. Provider'ı kaydet
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthViewModel()),
  ],
  child: MyApp(),
)

// 2. UI'da kullan
Consumer<AuthViewModel>(
  builder: (context, viewModel, child) {
    if (viewModel.isLoading) {
      return CircularProgressIndicator();
    }
    return Text('Hoş geldin ${viewModel.user?.name}');
  },
)
```

**Benzetme:** Garson gibi, mutfaktan (ViewModel) bilgi alıp müşteriye (UI) iletir.

**Nerede?** `lib/core/providers/app_providers.dart`

---

### ChangeNotifier
**Ne?** State değiştiğinde dinleyicilere haber veren sınıf.

**Örnek:**
```dart
class AuthViewModel extends ChangeNotifier {
  bool isLoading = false;
  
  void signIn() {
    isLoading = true;
    notifyListeners();  // "Değişti!" diye bağır
    // ...
    isLoading = false;
    notifyListeners();  // Tekrar "Değişti!" diye bağır
  }
}
```

---

## 7. Dependency Injection (Bağımlılık Yönetimi)

### Service Locator
**Ne?** Servisleri merkezi yöneten sistem.

**Örnek:**
```dart
// 1. Servis kaydet
ServiceLocator().registerSingleton<AuthRepository>(
  AuthRepositoryImpl(),
);

// 2. İhtiyaç duyulan yerde al
class AuthViewModel {
  final AuthRepository _repository = ServiceLocator().get<AuthRepository>();
  // Artık test edilebilir, mock eklenebilir
}
```

**Benzetme:** Kütüphane gibi, kitapları (servisleri) saklar ve verir.

**Nerede?** `lib/core/di/service_locator.dart`

---

### Dependency Injection (DI)
**Ne?** Bağımlılıkları dışarıdan verme.

**Örnek:**
```dart
// ❌ KÖTÜ (bağımlılık içeride)
class AuthViewModel {
  final AuthRepository _repository = AuthRepositoryImpl();  // Direkt oluştur
}

// ✅ İYİ (bağımlılık dışarıdan)
class AuthViewModel {
  final AuthRepository _repository;
  
  AuthViewModel({required AuthRepository repository}) 
      : _repository = repository;  // Dışarıdan ver
}
```

**Faydaları:**
- Test edilebilirlik artar (mock eklenebilir)
- Kod daha modüler olur
- Bağımlılıklar merkezi yönetilir

---

## 8. Hata Yönetimi

### Exception
**Ne?** Hata durumu (try-catch ile yakalanır).

**Örnek:**
```dart
try {
  final user = await signIn(email, password);
} catch (e) {
  print('Hata: $e');  // Exception yakalandı
}
```

---

### Failure
**Ne?** İş mantığı seviyesinde hata (Either ile döner).

**Örnek:**
```dart
// Either: Left = Hata, Right = Başarılı
Future<Either<Failure, UserModel>> signIn(...) async {
  try {
    final user = await _repository.signIn(...);
    return Either.right(user);  // Başarılı
  } catch (e) {
    return Either.left(ServerFailure('Sunucu hatası'));  // Hata
  }
}

// Kullanım
final result = await signIn(...);
if (result.isRight) {
  final user = result.right;  // Başarılı
} else {
  final error = result.left.message;  // Hata mesajı
}
```

**Failure Türleri:**
- `ServerFailure`: Sunucu hatası
- `NetworkFailure`: İnternet hatası
- `ValidationFailure`: Doğrulama hatası
- `CacheFailure`: Cache hatası
- `UnknownFailure`: Bilinmeyen hata

**Nerede?** `lib/core/errors/failures.dart`

---

## 9. Firebase Terimleri

### Firebase
**Ne?** Google'ın backend servisleri (Auth, Database, Storage).

**Benzetme:** Sunucu gibi, veri ve kimlik doğrulama sağlar.

**Servisler:**
- **Firebase Auth**: Kullanıcı girişi/kaydı
- **Cloud Firestore**: Veritabanı
- **Firebase Storage**: Dosya depolama
- **Firebase Messaging**: Push bildirimleri

---

### Firestore
**Ne?** NoSQL veritabanı (koleksiyonlar ve dokümanlar).

**Veri Yapısı:**
```
users/              // Collection (tablo)
  └── user123/      // Document (satır)
      ├── email: "test@test.com"
      ├── name: "Ahmet"
      └── age: 25
```

**Örnek:**
```dart
// Veri kaydet
await FirebaseFirestore.instance
    .collection('users')
    .doc('user123')
    .set({'email': 'test@test.com', 'name': 'Ahmet'});

// Veri oku
final doc = await FirebaseFirestore.instance
    .collection('users')
    .doc('user123')
    .get();

final data = doc.data();  // {'email': 'test@test.com', 'name': 'Ahmet'}
```

---

### Firebase Auth
**Ne?** Kimlik doğrulama servisi.

**Örnek:**
```dart
// Giriş yap
await FirebaseAuth.instance.signInWithEmailAndPassword(
  email: email,
  password: password,
);

// Kayıt ol
await FirebaseAuth.instance.createUserWithEmailAndPassword(
  email: email,
  password: password,
);

// Çıkış yap
await FirebaseAuth.instance.signOut();
```

---

## 10. Diğer Önemli Terimler

### Navigation
**Ne?** Sayfa geçişleri.

**Örnek:**
```dart
// Yeni sayfaya git
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => HomePage()),
);

// Geri dön
Navigator.pop(context);

// Sayfa değiştir (geri dönüş yok)
Navigator.pushReplacement(
  context,
  MaterialPageRoute(builder: (context) => HomePage()),
);
```

---

### StatefulWidget vs StatelessWidget

#### StatelessWidget
**Ne?** Değişmeyen widget.

**Örnek:**
```dart
class MyButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(...);  // Hep aynı
  }
}
```

#### StatefulWidget
**Ne?** Değişebilen widget.

**Örnek:**
```dart
class Counter extends StatefulWidget {
  @override
  State<Counter> createState() => _CounterState();
}

class _CounterState extends State<Counter> {
  int count = 0;  // State değişebilir
  
  void increment() {
    setState(() {
      count++;  // State değişti, UI güncellenir
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Text('Sayı: $count');
  }
}
```

---

### Features (Özellikler)
**Ne?** Uygulamanın bağımsız özellikleri.

**Projede:**
```
features/
├── auth/      # Giriş/Kayıt özelliği
├── event/     # Etkinlik özelliği
└── chat/      # Sohbet özelliği
```

**Her Feature'ın Yapısı:**
```
auth/
├── domain/                    # İş mantığı
│   ├── repositories/         # Interface'ler
│   └── usecases/            # Business logic
├── data/                     # Veri katmanı
│   ├── datasources/         # Firebase çağrıları
│   └── repositories/        # Repository implementasyonu
└── presentation/             # UI katmanı
    └── viewmodels/          # State management
```

**Benzetme:** Şirket departmanları gibi, her biri kendi işini yapar.

---

## Özet Tablo

| Terim | Ne? | Nerede? | Örnek |
|-------|-----|---------|-------|
| **Widget** | UI elemanı | Her yerde | `Text()`, `Button()` |
| **Model** | Veri yapısı | `models/` | `UserModel` |
| **Data Source** | Firebase bağlantısı | `data/datasources/` | `AuthRemoteDataSource` |
| **Repository** | Veri yönetimi | `data/repositories/` | `AuthRepositoryImpl` |
| **Use Case** | İş kuralı | `domain/usecases/` | `SignInUseCase` |
| **ViewModel** | State yönetimi | `presentation/viewmodels/` | `AuthViewModel` |
| **Provider** | State sağlayıcı | `core/providers/` | `ChangeNotifierProvider` |
| **Service Locator** | Bağımlılık yönetimi | `core/di/` | `ServiceLocator` |
| **Future** | Asenkron işlem | Her yerde | `Future<String>` |
| **Stream** | Sürekli veri | Her yerde | `Stream<List<Message>>` |

---

## Pratik Örnekler

### Tam Bir Akış Örneği: Kullanıcı Girişi

```dart
// 1. UI (lib/views/auth_page.dart)
class AuthPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading) {
          return CircularProgressIndicator();
        }
        
        return ElevatedButton(
          onPressed: () {
            viewModel.signIn('test@test.com', '123456');
          },
          child: Text('Giriş Yap'),
        );
      },
    );
  }
}

// 2. ViewModel (lib/features/auth/presentation/viewmodels/auth_viewmodel.dart)
class AuthViewModel extends ChangeNotifier {
  bool isLoading = false;
  UserModel? user;
  String? error;
  
  final SignInUseCase _signInUseCase;
  
  AuthViewModel({required SignInUseCase signInUseCase})
      : _signInUseCase = signInUseCase;
  
  Future<void> signIn(String email, String password) async {
    isLoading = true;
    error = null;
    notifyListeners();
    
    final result = await _signInUseCase(email, password);
    
    if (result.isRight) {
      user = result.right;
    } else {
      error = result.left.message;
    }
    
    isLoading = false;
    notifyListeners();
  }
}

// 3. Use Case (lib/features/auth/domain/usecases/sign_in_usecase.dart)
class SignInUseCase {
  final AuthRepository _repository;
  
  SignInUseCase(this._repository);
  
  Future<Either<Failure, UserModel>> call(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      return Either.left(ValidationFailure('Boş olamaz'));
    }
    
    return await _repository.signIn(email, password);
  }
}

// 4. Repository (lib/features/auth/data/repositories/auth_repository_impl.dart)
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  
  AuthRepositoryImpl({required AuthRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;
  
  @override
  Future<Either<Failure, UserModel>> signIn(String email, String password) async {
    try {
      final user = await _remoteDataSource.signIn(email, password);
      return Either.right(user);
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } catch (e) {
      return Either.left(UnknownFailure('Bilinmeyen hata: ${e.toString()}'));
    }
  }
}

// 5. Data Source (lib/features/auth/data/datasources/auth_remote_data_source.dart)
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  @override
  Future<UserModel> signIn(String email, String password) async {
    final userCredential = await FirebaseAuth.instance
        .signInWithEmailAndPassword(email: email, password: password);
    
    return UserModel.fromFirebaseUser(userCredential.user!);
  }
}
```

---

## Çalışma İpuçları

### 1. Adım Adım Öğrenme
1. Önce temel kavramları öğren (Widget, State, Model)
2. Sonra Clean Architecture katmanlarını öğren
3. Veri akışını takip et (UI → ViewModel → Use Case → Repository → Data Source)
4. Pratik yap, kod yaz

### 2. Kod Okuma
- Projede `lib/features/auth/` klasörünü incele
- Her dosyayı oku, ne yaptığını anla
- Veri akışını takip et

### 3. Pratik Yapma
- Basit bir özellik ekle (ör: profil fotoğrafı değiştirme)
- Clean Architecture'a uygun yaz
- Her katmanı doğru kullan

### 4. Test Yazma
- Her katman için test yaz
- Mock kullan
- Test coverage'ı artır

---

## Sık Sorulan Sorular

### Q: Repository ve Data Source arasındaki fark nedir?
**A:** 
- **Data Source**: Firebase'e direkt bağlanır, hata fırlatır (Exception)
- **Repository**: Data Source'u sarmalar, hataları Failure'a çevirir, cache yönetir

### Q: Use Case neden gerekli?
**A:** Business logic'i (iş kuralları) ayrı tutmak için. Örnek: "Şifre en az 6 karakter olmalı"

### Q: ViewModel ve Provider farkı nedir?
**A:**
- **ViewModel**: State tutar, Use Case'leri çağırır
- **Provider**: ViewModel'i UI'a bağlar, değişiklikleri dinler

### Q: Service Locator neden kullanılır?
**A:** Bağımlılıkları merkezi yönetmek için. Test edilebilirlik artar, mock eklemek kolaylaşır.

---

## Kaynaklar

- **Flutter Dokümantasyonu**: https://flutter.dev/docs
- **Clean Architecture**: https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html
- **Provider Paketi**: https://pub.dev/packages/provider
- **Firebase Dokümantasyonu**: https://firebase.google.com/docs

---

## Notlar

- Bu notlar Thunder projesi üzerinden hazırlanmıştır
- Tüm örnekler projeden alınmıştır
- Clean Architecture prensiplerine uygundur
- Düzenli olarak güncellenecektir

---

**Son Güncelleme:** 2024  
**Proje:** Thunder Flutter App  
**Versiyon:** 1.0.0

