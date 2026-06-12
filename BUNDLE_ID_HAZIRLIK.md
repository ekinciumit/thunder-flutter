# Bundle ID Hazırlık Rehberi (Adım 10)

Play Console / App Store Connect hesabı açıldığında `com.example.thunder` → gerçek paket adına geçiş için kontrol listesi.

## Mevcut durum

| Platform | Mevcut ID |
|----------|-----------|
| Android `applicationId` | `com.example.thunder` |
| iOS `PRODUCT_BUNDLE_IDENTIFIER` | `com.example.thunder` |
| macOS / Linux | `com.example.thunder` |
| Firebase (`firebase_options.dart`) | `com.example.thunder` (iOS) |

## Önerilen yeni ID formatı

```
com.<sirket>.thunder
```

Örnek: `com.thunderapp.social`

## Değiştirilecek dosyalar

### Android
- `android/app/build.gradle.kts` — `namespace`, `applicationId`
- `android/app/src/main/kotlin/com/example/thunder/MainActivity.kt` — paket yolu + klasör taşıma

### iOS
- `ios/Runner.xcodeproj/project.pbxproj` — `PRODUCT_BUNDLE_IDENTIFIER`
- Firebase Console → iOS uygulaması ekle/güncelle
- `GoogleService-Info.plist` yeniden indir

### macOS
- `macos/Runner/Configs/AppInfo.xcconfig`
- `macos/Runner.xcodeproj/project.pbxproj`

### Flutter / Firebase
- `lib/firebase_options.dart` — `flutterfire configure` ile yeniden üret
- `linux/CMakeLists.txt` — `APPLICATION_ID`

## Firebase & Google Sign-In

1. [Firebase Console](https://console.firebase.google.com) → Proje ayarları → Uygulama ekle (yeni bundle ID)
2. `google-services.json` (Android) ve `GoogleService-Info.plist` (iOS) güncelle
3. Google Cloud Console → OAuth istemci kimlikleri → Android/iOS SHA-1 / bundle ID güncelle
4. `flutterfire configure` çalıştır

## Release build doğrulama

```bash
flutter build appbundle --release
flutter build ipa --release   # macOS + Xcode gerekir
```

## Store listeleri

- Play Console: uygulama oluştur → paket adı **bir kez** seçilir (değiştirilemez)
- App Store Connect: Bundle ID önce Apple Developer portalda oluşturulmalı

## Not

Bundle ID değişikliği mevcut Firebase Auth / FCM token eşlemesini etkilemez; kullanıcılar yeniden giriş yapabilir. Test ortamında staging Firebase projesi kullanılması önerilir.
