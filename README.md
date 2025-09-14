# ⚡ Thunder - Modern Flutter Chat & Event App

<div align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart">
  <img src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" alt="Firebase">
  <img src="https://img.shields.io/badge/Riverpod-FF6B6B?style=for-the-badge&logo=flutter&logoColor=white" alt="Riverpod">
</div>

<br>

**Thunder**, modern tasarım prensipleri ile geliştirilmiş, kullanıcı dostu bir Flutter uygulamasıdır. Gerçek zamanlı sohbet, etkinlik yönetimi ve harita entegrasyonu ile kapsamlı bir sosyal deneyim sunar.

## 🌟 Özellikler

### 💬 **Gerçek Zamanlı Sohbet**
- ✅ Özel mesajlaşma
- ✅ Grup sohbetleri
- ✅ Ses mesajları
- ✅ Dosya paylaşımı
- ✅ Emoji desteği
- ✅ Mesaj arama

### 🎯 **Etkinlik Yönetimi**
- ✅ Etkinlik oluşturma
- ✅ Etkinlik katılımı
- ✅ Tarih ve saat planlaması
- ✅ Konum bazlı etkinlikler
- ✅ Harita entegrasyonu

### 🗺️ **Harita Özellikleri**
- ✅ Google Maps entegrasyonu
- ✅ Konum bazlı arama
- ✅ Etkinlik konumları
- ✅ Geocoding desteği

### 🔐 **Güvenlik & Kimlik Doğrulama**
- ✅ Firebase Authentication
- ✅ Email/Password girişi
- ✅ Profil yönetimi
- ✅ Güvenli veri saklama

### 🎨 **Modern UI/UX**
- ✅ Material Design 3
- ✅ Glassmorphism efektleri
- ✅ Animasyonlu geçişler
- ✅ Dark/Light tema desteği
- ✅ Responsive tasarım

## 🛠️ Teknoloji Stack

### **Frontend**
- **Flutter** - Cross-platform UI framework
- **Dart** - Programming language
- **Riverpod** - State management
- **Material Design 3** - UI components

### **Backend & Services**
- **Firebase Auth** - Authentication
- **Cloud Firestore** - NoSQL database
- **Firebase Storage** - File storage
- **Firebase Cloud Messaging** - Push notifications

### **Libraries & Packages**
```yaml
dependencies:
  flutter_riverpod: ^2.4.9
  firebase_auth: ^4.15.3
  cloud_firestore: ^4.13.6
  firebase_storage: ^11.5.6
  google_maps_flutter: ^2.5.3
  geolocator: ^13.0.1
  image_picker: ^1.0.4
  cached_network_image: ^3.4.1
  emoji_picker_flutter: ^2.1.0
  video_player: ^2.8.2
  audioplayers: ^5.2.1
  record: ^5.0.4
  url_launcher: ^6.2.2
  shared_preferences: ^2.2.2
  permission_handler: ^11.1.0
  file_picker: ^6.1.1
  path_provider: ^2.1.2
  flutter_localizations: ^3.24.3
```

## 📱 Ekran Görüntüleri

<div align="center">
  <img src="https://via.placeholder.com/300x600/02569B/FFFFFF?text=Login+Screen" alt="Login Screen" width="150">
  <img src="https://via.placeholder.com/300x600/FF6B6B/FFFFFF?text=Chat+Screen" alt="Chat Screen" width="150">
  <img src="https://via.placeholder.com/300x600/4ECDC4/FFFFFF?text=Events+Screen" alt="Events Screen" width="150">
  <img src="https://via.placeholder.com/300x600/FFE66D/000000?text=Map+Screen" alt="Map Screen" width="150">
</div>

## 🚀 Kurulum

### **Gereksinimler**
- Flutter SDK (3.24.0 veya üzeri)
- Dart SDK (3.5.0 veya üzeri)
- Android Studio / VS Code
- Firebase projesi
- Google Maps API anahtarı

### **Adım 1: Repository'yi Klonlayın**
```bash
git clone https://github.com/username/thunder.git
cd thunder
```

### **Adım 2: Dependencies'leri Yükleyin**
```bash
flutter pub get
```

### **Adım 3: Firebase Yapılandırması**
1. [Firebase Console](https://console.firebase.google.com/)'da yeni proje oluşturun
2. Android uygulaması ekleyin
3. `google-services.json` dosyasını `android/app/` klasörüne yerleştirin
4. Firestore Database'i etkinleştirin
5. Authentication'ı yapılandırın

### **Adım 4: Google Maps API**
1. [Google Cloud Console](https://console.cloud.google.com/)'da Maps API'yi etkinleştirin
2. API anahtarını alın
3. `android/app/src/main/AndroidManifest.xml` dosyasına ekleyin:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_API_KEY"/>
```

### **Adım 5: Uygulamayı Çalıştırın**
```bash
flutter run
```

## 📁 Proje Yapısı

```
lib/
├── main.dart                    # Uygulama giriş noktası
├── models/                      # Veri modelleri
│   ├── user.dart
│   ├── event.dart
│   └── message.dart
├── services/                    # İş mantığı servisleri
│   ├── auth_service.dart
│   ├── chat_service.dart
│   ├── event_service.dart
│   └── audio_service.dart
├── providers/                   # Riverpod state providers
│   ├── auth_provider.dart
│   └── counter_provider.dart
├── views/                       # UI ekranları
│   ├── auth/
│   ├── chat/
│   ├── events/
│   ├── profile/
│   └── widgets/                 # Yeniden kullanılabilir widget'lar
└── utils/                       # Yardımcı fonksiyonlar
    ├── constants.dart
    └── helpers.dart
```

## 🎯 Özellik Detayları

### **Authentication Flow**
- Email/Password ile kayıt olma
- Güvenli giriş yapma
- Profil bilgilerini güncelleme
- Şifre sıfırlama

### **Chat System**
- Gerçek zamanlı mesajlaşma
- Ses kayıt ve oynatma
- Dosya yükleme ve indirme
- Mesaj geçmişi
- Emoji picker

### **Event Management**
- Etkinlik oluşturma formu
- Tarih ve saat seçimi
- Konum belirleme
- Katılımcı yönetimi
- Etkinlik arama ve filtreleme

### **Map Integration**
- Google Maps entegrasyonu
- Konum bazlı arama
- Etkinlik konumlarını gösterme
- Geocoding ile adres dönüşümü

## 🔧 Geliştirme

### **Kod Stili**
- Dart/Flutter best practices
- Clean architecture principles
- MVVM pattern
- Repository pattern

### **Testing**
```bash
# Unit testleri çalıştır
flutter test

# Integration testleri çalıştır
flutter drive --target=test_driver/app.dart
```

### **Build**
```bash
# Debug build
flutter build apk --debug

# Release build
flutter build apk --release
```

## 📊 Performans

- **Build Time**: ~30-45 saniye
- **App Size**: ~25-30 MB
- **Startup Time**: <3 saniye
- **Memory Usage**: ~50-80 MB

## 🌍 Çoklu Dil Desteği

- ✅ Türkçe (Varsayılan)
- ✅ İngilizce
- 🔄 Daha fazla dil eklenecek

## 🤝 Katkıda Bulunma

1. Fork edin
2. Feature branch oluşturun (`git checkout -b feature/AmazingFeature`)
3. Commit edin (`git commit -m 'Add some AmazingFeature'`)
4. Push edin (`git push origin feature/AmazingFeature`)
5. Pull Request oluşturun

## 📝 Lisans

Bu proje MIT lisansı altında lisanslanmıştır. Detaylar için [LICENSE](LICENSE) dosyasına bakın.

## 👥 Ekip

- **Geliştirici**: [Your Name](https://github.com/username)
- **Tasarım**: Material Design 3
- **Backend**: Firebase

## 📞 İletişim

- **Email**: your.email@example.com
- **GitHub**: [@username](https://github.com/username)
- **LinkedIn**: [Your LinkedIn](https://linkedin.com/in/username)

## 🎉 Teşekkürler

- Flutter ekibine harika framework için
- Firebase ekibine backend servisleri için
- Google Maps ekibine harita entegrasyonu için
- Tüm açık kaynak katkıda bulunanlara

---

<div align="center">
  <p>⭐ Bu projeyi beğendiyseniz yıldız vermeyi unutmayın!</p>
  <p>Made with ❤️ using Flutter</p>
</div>