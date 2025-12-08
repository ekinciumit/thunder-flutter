# ⚡ Thunder - Yapılacaklar Listesi

> **Oluşturulma Tarihi:** 8 Aralık 2024  
> **Son Güncelleme:** 8 Aralık 2024 - Event Filtreleme refactoring tamamlandı! 🚀

---

## 🔴 KRİTİK (Hemen Yapılmalı)

- [x] **1. HomePage Firestore Erişimi** ✅ (8 Aralık 2024)
  - **Dosya:** `lib/views/home_page.dart`
  - **Sorun:** `_navigateToChat` metodunda direkt `FirebaseFirestore.instance` çağrısı var
  - **Çözüm:** Bu logic'i `ChatViewModel`'e taşı, UI → ViewModel → UseCase → Repository zincirini koru
  - **Yapılanlar:**
    - `GetChatByIdUseCase` oluşturuldu
    - `ChatRepository` ve `ChatRepositoryImpl`'e `getChatById` eklendi
    - `ChatRemoteDataSource`'a `getChatById` eklendi
    - `ChatViewModel`'e `getChatById` metodu eklendi
    - `home_page.dart` güncellendi

- [x] **2. Null Safety İyileştirmesi** ✅ (8 Aralık 2024)
  - **Dosyalar:** `lib/views/create_event_page.dart`, `lib/views/event_detail_page.dart`
  - **Sorun:** `selectedDateTime!`, `selectedLatLng!`, `coverPhotoFile!` gibi `!` operatörü kullanımları
  - **Yapılanlar:**
    - `_uploadCoverPhoto()` metodunda yerel değişken pattern uygulandı
    - Form submit'te `dateTime` ve `latLng` yerel değişkenlere atandı
    - UI'daki ternary kullanımlar `Builder` widget ile güvenli hale getirildi
    - `event_detail_page.dart`'taki `newPhotoFile!` düzeltildi

---

## 🟡 ORTA ÖNCELİK (1-2 Hafta)

- [x] **3. ServiceLocator Kaldır** ✅ (8 Aralık 2024)
  - **Dosyalar:** 
    - `lib/core/di/service_locator.dart` (silindi)
    - `lib/main.dart` (`_setupServiceLocator()` kaldırıldı)
  - **Yapılanlar:**
    - Import kaldırıldı
    - `_setupServiceLocator()` fonksiyonu ve çağrısı kaldırıldı
    - `service_locator.dart` dosyası silindi (2.5 KB tasarruf)

- [x] **4. dartz Paketi Kaldır** ✅ (8 Aralık 2024)
  - **Dosya:** `pubspec.yaml`
  - **Yapılanlar:** `dartz: ^0.10.1` satırı kaldırıldı
  - **Not:** Proje kendi Either implementasyonunu kullanıyor (`core/errors/failures.dart`)

- [x] **5. web Paketi Kaldır** ✅ (8 Aralık 2024)
  - **Dosya:** `pubspec.yaml`
  - **Yapılanlar:** `web: ^1.1.1` kaldırıldı (hiçbir yerde kullanılmıyordu)

- [x] **6. library; Satırları Temizle** ✅ (8 Aralık 2024)
  - **Yapılanlar:** 6 dosyadan `library;` satırları kaldırıldı:
    - `lib/core/validators/form_validators.dart`
    - `lib/core/errors/exceptions.dart`
    - `lib/core/constants/app_constants.dart`
    - `lib/core/errors/failures.dart`
    - `lib/core/widgets/responsive_widgets.dart`
    - `lib/core/utils/validators.dart`

---

## 🟢 İYİLEŞTİRME (2-4 Hafta)

- [x] **7. Event Filtreleme Logic'ini Taşı** ✅ (8 Aralık 2024)
  - **Kaynak:** `lib/views/event_list_view.dart`
  - **Hedef:** `lib/features/event/presentation/viewmodels/event_viewmodel.dart`
  - **Yapılanlar:**
    - EventViewModel'e filtre state'leri eklendi (searchQuery, category, date, distance)
    - `getFilteredEvents()` metodu memoization ile eklendi
    - `setSearchQuery()`, `setCategory()`, `setDateRange()`, `setDistanceFilter()` metodları eklendi
    - `getDistanceForEvent()` metodu eklendi
    - `resetFilters()`, `resetLocationFilter()` metodları eklendi
    - `event_list_view.dart` temizlendi (~50 satır filtreleme kodu kaldırıldı)
  - **Fayda:** Performans artışı (memoization), Clean Architecture uyumu, test edilebilirlik

- [ ] **8. Büyük Widget Dosyalarını Parçala**
  - **Dosyalar:**
    - `lib/views/event_list_view.dart` (~967 satır)
    - `lib/views/create_event_page.dart`
    - `lib/views/home_page.dart` (~492 satır)
  - **Çözüm:** Alt widget'lara böl (EventCard, EventFilters, EventSearchBar vb.)

- [ ] **9. CardTheme Syntax Kontrol**
  - **Dosya:** `lib/core/theme/app_theme.dart`
  - **Kontrol:** `CardThemeData` → `CardTheme` olmalı mı?
  - **Not:** Proje derleniyorsa sorun yok

---

## 🔵 UZUN VADE (1-2 Ay - Opsiyonel)

- [ ] **10. Test Coverage Artır**
  - Auth, Event, Chat için unit testleri
  - Widget testleri
  - Integration testleri
  - **Hedef:** %70+ coverage

- [ ] **11. Sealed State Pattern**
  - ViewModel'lerde `isLoading`, `error` yerine sealed class kullan
  - Örnek: `EventLoading`, `EventLoaded`, `EventError`
  - **Fayda:** Daha güvenli state yönetimi

- [ ] **12. Dark Theme İyileştirmeleri**
  - Kontrast kontrolü (AA/AAA standartları)
  - Glassmorphism efektleri dark mode'da test
  - Font okunabilirliği

---

## 📊 İlerleme Özeti

| Kategori | Toplam | Tamamlanan |
|----------|--------|------------|
| 🔴 Kritik | 2 | 2 ✅ |
| 🟡 Orta | 4 | 4 ✅ |
| 🟢 İyileştirme | 3 | 1 |
| 🔵 Uzun Vade | 3 | 0 |
| **TOPLAM** | **12** | **7** |

---

## 📝 Notlar

- Bu liste ChatGPT ve Claude analizleri sonucunda oluşturulmuştur
- Öncelik sırasına göre ilerlemek önerilir
- Her madde tamamlandığında `[ ]` → `[x]` olarak işaretlenecek

---

## 🔗 İlgili Dosyalar

```
lib/
├── core/
│   ├── di/service_locator.dart      # ✅ Silindi
│   ├── errors/failures.dart         # ✅ library; temizlendi
│   ├── validators/form_validators.dart # ✅ library; temizlendi
│   └── theme/app_theme.dart         # CardTheme kontrol
├── features/
│   └── event/presentation/viewmodels/event_viewmodel.dart # ✅ Filtreleme eklendi
├── views/
│   ├── home_page.dart               # ✅ Firestore erişimi taşındı
│   ├── event_list_view.dart         # ✅ Filtreleme taşındı | Parçalama bekliyor
│   ├── create_event_page.dart       # ✅ Null safety | Parçalama bekliyor
│   └── event_detail_page.dart       # ✅ Null safety
└── main.dart                        # ✅ ServiceLocator kaldırıldı
```
