# 🧪 Manual Test Guide - Android Endpoint Testleri

## 📱 Android Emülatörde Test Etme

### 1. **Emülatörü Başlat**
```bash
# Emülatörleri listele
flutter emulators

# Emülatörü başlat
flutter emulators --launch <emulator_id>

# Veya Android Studio'dan başlat
```

### 2. **Uygulamayı Çalıştır**
```bash
# Cihazları listele
flutter devices

# Uygulamayı çalıştır
flutter run -d <device_id>

# Hot reload için terminal'de 'r' tuşuna bas
# Hot restart için terminal'de 'R' tuşuna bas
```

### 3. **Logcat ile Debug**
```bash
# Android logcat'i görüntüle
adb logcat

# Sadece Flutter loglarını görüntüle
adb logcat | grep flutter

# Belirli tag'i filtrele
adb logcat -s flutter
```

## 🔍 Endpoint Test Senaryoları

### Authentication Endpoints:

#### 1. **Sign In (Giriş Yap)**
- ✅ Geçerli email/password ile giriş
- ✅ Geçersiz email ile giriş
- ✅ Yanlış password ile giriş
- ✅ Kullanıcı bulunamadı hatası
- ✅ Network hatası

#### 2. **Sign Up (Kayıt Ol)**
- ✅ Yeni kullanıcı kaydı
- ✅ Zaten kayıtlı email ile kayıt
- ✅ Zayıf şifre hatası
- ✅ Geçersiz email formatı
- ✅ Network hatası

#### 3. **Sign Out (Çıkış Yap)**
- ✅ Başarılı çıkış
- ✅ Çıkış sonrası login sayfasına yönlendirme

### Firestore Endpoints:

#### 1. **Users Collection**
- ✅ Kullanıcı profili kaydetme
- ✅ Kullanıcı profili getirme
- ✅ Kullanıcı profili güncelleme
- ✅ Kullanıcı profili silme

#### 2. **Chats Collection**
- ✅ Özel sohbet oluşturma
- ✅ Grup sohbeti oluşturma
- ✅ Sohbet listesi getirme
- ✅ Sohbet detayı getirme
- ✅ Sohbet silme

#### 3. **Messages Collection**
- ✅ Mesaj gönderme
- ✅ Mesajları getirme
- ✅ Mesaj silme
- ✅ Mesaj güncelleme
- ✅ Real-time mesaj dinleme

#### 4. **Events Collection**
- ✅ Etkinlik oluşturma
- ✅ Etkinlik listesi getirme
- ✅ Etkinlik detayı getirme
- ✅ Etkinliğe katılma
- ✅ Etkinlikten ayrılma
- ✅ Etkinlik silme

### Storage Endpoints:

#### 1. **Image Upload**
- ✅ Profil fotoğrafı yükleme
- ✅ Etkinlik fotoğrafı yükleme
- ✅ Chat fotoğrafı yükleme
- ✅ Büyük dosya yükleme hatası
- ✅ Geçersiz format hatası

#### 2. **File Upload**
- ✅ Dosya seçme
- ✅ Dosya yükleme
- ✅ Dosya indirme
- ✅ Dosya silme

#### 3. **Audio Upload**
- ✅ Ses kaydı yapma
- ✅ Ses dosyası yükleme
- ✅ Ses dosyası oynatma
- ✅ Ses dosyası silme

## 🛠️ Test Araçları

### 1. **Flutter DevTools**
```bash
# DevTools'u başlat
flutter pub global activate devtools
flutter pub global run devtools

# Uygulamayı çalıştırırken DevTools'u aç
flutter run --devtools
```

### 2. **Android Studio Profiler**
- CPU Usage
- Memory Usage
- Network Usage
- Battery Usage

### 3. **Firebase Console**
- Authentication Users
- Firestore Database
- Storage Files
- Functions Logs

### 4. **Postman (API Test)**
- Firebase REST API testleri
- Custom endpoint testleri
- Authentication token testleri

## 📊 Test Checklist

### Authentication:
- [ ] Sign in başarılı
- [ ] Sign in hatalı
- [ ] Sign up başarılı
- [ ] Sign up hatalı
- [ ] Sign out başarılı
- [ ] Password reset
- [ ] Email verification

### Chat:
- [ ] Özel sohbet oluştur
- [ ] Mesaj gönder
- [ ] Mesaj al
- [ ] Real-time mesaj
- [ ] Dosya gönder
- [ ] Ses mesajı gönder
- [ ] Emoji gönder

### Events:
- [ ] Etkinlik oluştur
- [ ] Etkinlik listele
- [ ] Etkinliğe katıl
- [ ] Etkinlikten ayrıl
- [ ] Etkinlik sil
- [ ] Etkinlik güncelle

### Profile:
- [ ] Profil görüntüle
- [ ] Profil güncelle
- [ ] Profil fotoğrafı yükle
- [ ] Profil sil

## 🐛 Debug İpuçları

### 1. **Log Ekleme**
```dart
// Debug log
print('Debug: User signed in: ${user.email}');

// Error log
print('Error: ${e.toString()}');

// Firebase log
FirebaseFirestore.instance.enablePersistence();
```

### 2. **Breakpoint Kullanma**
- Android Studio'da breakpoint ekle
- Debug mode'da çalıştır
- Step by step debug yap

### 3. **Network Inspector**
```bash
# Network trafiğini izle
adb logcat | grep -i "network"

# Firebase request'lerini izle
adb logcat | grep -i "firebase"
```

## 🚀 Hızlı Test Komutları

```bash
# Tüm testleri çalıştır
flutter test

# Belirli test dosyasını çalıştır
flutter test test/services/auth_service_test.dart

# Coverage raporu
flutter test --coverage

# Integration test
flutter drive --target=test_driver/app.dart

# Emülatörde çalıştır
flutter run -d emulator-5554

# Hot reload
# Terminal'de 'r' tuşuna bas

# Hot restart
# Terminal'de 'R' tuşuna bas

# Quit
# Terminal'de 'q' tuşuna bas
```

## 📝 Test Raporu

Test sonuçlarını dokümante et:
- ✅ Başarılı testler
- ❌ Başarısız testler
- ⚠️  Uyarılar
- 📊 Performance metrikleri
- 🐛 Bulunan bug'lar

