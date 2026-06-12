# 📁 Thunder Projesi - Klasör Yapısı Dokümantasyonu

**Tarih:** 7 Ocak 2026  
**Proje:** Thunder - Flutter Social Event App

---

## 🏗️ GENEL MİMARİ YAPISI

```
Thunder/
├── lib/
│   ├── main.dart                    # 🚀 Uygulama giriş noktası
│   ├── firebase_options.dart        # 🔥 Firebase yapılandırması
│   │
│   ├── core/                        # 🎯 CORE - Uygulama geneli bileşenler
│   ├── features/                    # 📦 FEATURES - Feature-based modüller (Clean Architecture)
│   ├── services/                    # ⚙️ SERVICES - Cross-cutting servisler
│   ├── views/                       # 🖼️ VIEWS - Shell/Shared sayfalar ve widget'lar
│   └── l10n/                        # 🌍 L10N - Çoklu dil desteği
│
├── test/                            # 🧪 Test dosyaları
├── android/                         # 🤖 Android platform dosyaları
├── ios/                             # 🍎 iOS platform dosyaları
└── firebase/                        # 🔥 Firebase yapılandırmaları
```

---

## 📂 DETAYLI KLASÖR YAPISI

### 1️⃣ **`lib/core/`** - Core Bileşenler
**Amaç:** Uygulama genelinde kullanılan, feature-bağımsız temel bileşenler

```
core/
├── constants/                       # 📌 Sabitler
│   └── app_constants.dart          # Uygulama geneli sabit değerler
│
├── errors/                          # ❌ Hata yönetimi
│   ├── exceptions.dart             # Custom exception sınıfları
│   ├── failures.dart               # Failure nesneleri
│   └── error_mapper.dart           # Hata mapping mantığı
│
├── navigation/                      # 🧭 Navigasyon
│   ├── app_router.dart             # go_router yapılandırması
│   └── app_navigation.dart         # Navigation helper fonksiyonları
│
├── providers/                       # 🔌 Dependency Injection
│   └── app_providers.dart          # Provider setup (Auth, Event, Chat, vb.)
│
├── theme/                           # 🎨 Tema ve Renkler
│   ├── app_theme.dart              # Material Theme yapılandırması
│   ├── app_color_config.dart       # Renk paleti
│   └── README_RENK_DEGISTIRME.md   # Renk değiştirme rehberi
│
├── utils/                           # 🛠️ Yardımcı Fonksiyonlar
│   ├── category_utils.dart         # Kategori yardımcıları
│   ├── fab_position_helper.dart     # FAB pozisyon hesaplamaları
│   └── responsive_helper.dart      # Responsive tasarım yardımcıları
│
├── validators/                      # ✅ Form Validasyonları
│   ├── form_validators.dart        # Form validasyon fonksiyonları
│   └── validation_logic.dart       # Validasyon mantığı
│
└── widgets/                         # 🧩 Core/Reusable Widget'lar
    ├── glass_container.dart        # Glassmorphism container
    ├── modern_components.dart       # Modern UI bileşenleri
    ├── responsive_padding.dart      # Responsive padding widget
    ├── responsive_sized_box.dart    # Responsive sized box
    ├── responsive_widgets.dart     # Responsive widget'lar
    └── skeleton_widgets.dart       # Loading skeleton widget'ları
```

**Kullanım Senaryosu:**
- Tüm feature'lar bu core bileşenleri kullanabilir
- Feature-bağımsız, yeniden kullanılabilir kod
- Uygulama geneli standartlar ve yardımcılar

---

### 2️⃣ **`lib/features/`** - Feature Modülleri (Clean Architecture)
**Amaç:** Her feature kendi modülünde, Clean Architecture prensiplerine göre organize edilmiş

#### 📐 **Clean Architecture Katmanları:**

Her feature şu 3 katmandan oluşur:

```
features/
└── {feature_name}/
    ├── data/                        # 📥 DATA LAYER - Veri kaynağı
    │   ├── datasources/            # Remote/Local veri kaynakları
    │   ├── models/                  # Data modelleri (Firestore formatı)
    │   ├── mappers/                 # Model ↔ Entity dönüşümleri
    │   └── repositories/            # Repository implementasyonları
    │
    ├── domain/                      # 🧠 DOMAIN LAYER - İş mantığı
    │   ├── entities/                # Domain entity'leri (pure Dart)
    │   ├── repositories/            # Repository interface'leri
    │   └── usecases/                # İş mantığı use case'leri
    │
    └── presentation/                # 🎨 PRESENTATION LAYER - UI
        ├── pages/                   # Ekranlar (Sayfalar)
        ├── viewmodels/              # State management (ChangeNotifier)
        └── widgets/                 # Feature-specific widget'lar
            └── helpers/             # Widget helper'ları (opsiyonel)
```

**Veri Akışı:**
```
UI (pages/widgets) 
  → ViewModel (presentation/viewmodels)
    → UseCase (domain/usecases)
      → Repository Interface (domain/repositories)
        → Repository Implementation (data/repositories)
          → DataSource (data/datasources)
            → Firebase/API
```

---

#### 🔐 **`features/auth/`** - Kimlik Doğrulama
**Amaç:** Kullanıcı girişi, kayıt, profil yönetimi

```
auth/
├── data/
│   ├── datasources/
│   │   ├── auth_remote_data_source.dart    # Firebase Auth işlemleri
│   │   └── auth_local_data_source.dart      # Local storage (SharedPreferences)
│   └── repositories/
│       └── auth_repository_impl.dart        # Repository implementasyonu
│
├── domain/
│   ├── repositories/
│   │   └── auth_repository.dart             # Repository interface
│   └── usecases/
│       ├── sign_in_usecase.dart             # Giriş yapma
│       ├── sign_up_usecase.dart             # Kayıt olma
│       ├── sign_out_usecase.dart         # Çıkış yapma
│       ├── fetch_user_profile_usecase.dart  # Profil getirme
│       └── save_user_profile_usecase.dart   # Profil kaydetme
│
└── presentation/
    ├── pages/
    │   ├── auth_page.dart                   # Giriş/Kayıt ekranı
    │   ├── complete_profile_page.dart       # Profil tamamlama
    │   └── edit_profile_page.dart           # Profil düzenleme
    └── viewmodels/
        └── auth_viewmodel.dart              # Auth state management
```

---

#### 💬 **`features/chat/`** - Mesajlaşma
**Amaç:** Özel ve grup sohbetleri, mesaj gönderme/alma

```
chat/
├── data/
│   ├── datasources/
│   │   └── chat_remote_data_source.dart     # Firestore chat işlemleri
│   ├── models/
│   │   ├── chat_model.dart                  # Chat data modeli
│   │   └── message_model.dart               # Message data modeli
│   ├── mappers/
│   │   ├── chat_mapper.dart                 # Chat Model ↔ Entity
│   │   └── message_mapper.dart              # Message Model ↔ Entity
│   └── repositories/
│       └── chat_repository_impl.dart         # Repository implementasyonu
│
├── domain/
│   ├── entities/
│   │   ├── chat_entity.dart                 # Chat domain entity
│   │   └── message_entity.dart              # Message domain entity
│   ├── repositories/
│   │   └── chat_repository.dart             # Repository interface
│   └── usecases/
│       ├── get_or_create_private_chat_usecase.dart
│       ├── create_group_chat_usecase.dart
│       ├── get_user_chats_usecase.dart
│       ├── get_messages_usecase.dart
│       ├── send_message_usecase.dart
│       ├── send_voice_message_usecase.dart
│       ├── send_file_message_usecase.dart
│       ├── edit_message_usecase.dart
│       ├── delete_message_usecase.dart
│       ├── forward_message_usecase.dart
│       ├── add_reaction_usecase.dart
│       ├── remove_reaction_usecase.dart
│       ├── mark_message_as_read_usecase.dart
│       ├── load_older_messages_usecase.dart
│       ├── search_messages_usecase.dart
│       ├── search_all_messages_usecase.dart
│       └── update_typing_status_usecase.dart
│
└── presentation/
    ├── pages/
    │   ├── chat_list_page.dart              # Sohbet listesi
    │   ├── private_chat_page.dart            # Özel sohbet ekranı
    │   ├── message_forward_page.dart         # Mesaj iletme
    │   └── message_search_page.dart          # Mesaj arama
    ├── viewmodels/
    │   └── chat_viewmodel.dart               # Chat state management
    └── widgets/
        ├── chat_app_bar.dart                 # Chat app bar
        ├── chat_input_bar.dart               # Mesaj giriş alanı
        ├── chat_message_list_builder.dart    # Mesaj listesi
        ├── message_bubble.dart                # Mesaj balonu
        ├── message_renderer.dart             # Mesaj renderer
        ├── voice_message_widget.dart         # Ses mesajı widget'ı
        ├── file_message_widget.dart          # Dosya mesajı widget'ı
        ├── media_message_bubble.dart         # Medya mesajı
        ├── message_reactions.dart           # Mesaj tepkileri
        ├── reaction_picker.dart              # Tepki seçici
        ├── full_screen_media_viewer.dart     # Tam ekran medya görüntüleyici
        └── helpers/
            ├── chat_initialization_helper.dart
            ├── chat_message_actions_helper.dart
            ├── chat_message_formatter_helper.dart
            ├── chat_pagination_helper.dart
            ├── message_sender_helper.dart
            └── voice_recording_helper.dart
```

---

#### 🎉 **`features/event/`** - Etkinlik Yönetimi
**Amaç:** Etkinlik oluşturma, katılım, yönetim

```
event/
├── data/
│   ├── datasources/
│   │   └── event_remote_data_source.dart     # Firestore event işlemleri
│   ├── models/
│   │   └── event_model.dart                  # Event data modeli
│   ├── mappers/
│   │   └── event_mapper.dart                 # Event Model ↔ Entity
│   └── repositories/
│       └── event_repository_impl.dart        # Repository implementasyonu
│
├── domain/
│   ├── entities/
│   │   ├── event_entity.dart                # Event domain entity
│   │   └── location_entity.dart             # Lokasyon entity
│   ├── repositories/
│   │   └── event_repository.dart            # Repository interface
│   └── usecases/
│       ├── add_event_usecase.dart           # Etkinlik oluşturma
│       ├── update_event_usecase.dart        # Etkinlik güncelleme
│       ├── delete_event_usecase.dart        # Etkinlik silme
│       ├── cancel_event_usecase.dart        # Etkinlik iptal
│       ├── get_events_usecase.dart          # Etkinlikleri getirme
│       ├── fetch_next_events_usecase.dart   # Sonraki etkinlikler
│       ├── join_event_usecase.dart          # Etkinliğe katılma
│       ├── leave_event_usecase.dart         # Etkinlikten ayrılma
│       ├── send_join_request_usecase.dart   # Katılım isteği gönderme
│       ├── approve_join_request_usecase.dart
│       ├── reject_join_request_usecase.dart
│       ├── cancel_join_request_usecase.dart
│       └── remove_participant_usecase.dart
│
└── presentation/
    ├── pages/
    │   ├── event_list_view.dart             # Etkinlik listesi
    │   ├── event_detail_page.dart           # Etkinlik detayı
    │   ├── create_event_page.dart           # Etkinlik oluşturma
    │   └── my_events_page.dart              # Kullanıcının etkinlikleri
    ├── viewmodels/
    │   └── event_viewmodel.dart             # Event state management
    └── widgets/
        ├── event_card.dart                   # Etkinlik kartı
        ├── event_header.dart                 # Etkinlik başlığı
        ├── event_meta_card.dart              # Etkinlik meta bilgileri
        ├── event_participation_button.dart   # Katılım butonu
        ├── event_category_picker_section.dart
        ├── event_date_time_picker_section.dart
        ├── event_location_picker_section.dart
        ├── event_form_fields_section.dart
        ├── event_submit_button_section.dart
        ├── event_cover_photo_picker.dart
        ├── event_comments_section.dart
        ├── event_edit_dialog.dart
        ├── event_delete_dialog.dart
        ├── event_cancel_dialog.dart
        ├── location_picker_dialog.dart
        ├── participant_chips.dart
        ├── participant_management_panel.dart
        ├── participants_preview.dart
        └── distance_to_event_widget.dart
```

---

#### 👤 **`features/user/`** - Kullanıcı Yönetimi
**Amaç:** Kullanıcı profilleri, takip sistemi, arama

```
user/
├── data/
│   ├── models/
│   │   └── user_model.dart                  # User data modeli
│   └── mappers/
│       └── user_mapper.dart                  # User Model ↔ Entity
│
├── domain/
│   └── entities/
│       └── user_entity.dart                  # User domain entity
│
└── presentation/
    ├── pages/
    │   ├── user_profile_page.dart            # Kullanıcı profili
    │   ├── profile_view.dart                 # Profil görünümü
    │   ├── user_search_page.dart             # Kullanıcı arama
    │   ├── followers_following_page.dart    # Takipçi/Takip edilenler
    │   └── blocked_users_page.dart           # Engellenen kullanıcılar
    └── widgets/
        ├── user_suggestions_widget.dart      # Kullanıcı önerileri
        └── profile_events_section.dart       # Profil etkinlikleri
```

---

#### 🔔 **`features/notification/`** - Bildirimler
**Amaç:** Bildirim entity ve modelleri (UI `views/notifications_page.dart` içinde)

```
notification/
├── data/
│   ├── models/
│   │   └── notification_model.dart          # Notification data modeli
│   └── mappers/
│       └── notification_mapper.dart          # Notification Model ↔ Entity
│
└── domain/
    └── entities/
        └── notification_entity.dart          # Notification domain entity
```

---

### 3️⃣ **`lib/services/`** - Cross-Cutting Servisler
**Amaç:** Uygulama genelinde kullanılan, feature-bağımsız servisler

```
services/
├── audio_service.dart                # 🎵 Ses kayıt/çalma servisi
├── audio_state_notifier.dart         # Ses durumu yönetimi
├── cache_service.dart                # 💾 Cache yönetimi
├── feedback_service.dart             # 📝 Geri bildirim servisi
├── language_service.dart             # 🌍 Dil değiştirme servisi
├── notification_service.dart         # 🔔 Push notification servisi (FCM)
├── settings_service.dart             # ⚙️ Ayarlar servisi
├── theme_service.dart                # 🎨 Tema değiştirme servisi
└── user_service.dart                 # 👤 Kullanıcı servisi (bildirimler, vb.)
```

**Kullanım Senaryosu:**
- Tüm feature'lar bu servisleri kullanabilir
- Singleton pattern ile yönetilir
- Uygulama geneli işlevsellik sağlar

---

### 4️⃣ **`lib/views/`** - Shell/Shared Sayfalar ve Widget'lar
**Amaç:** Feature-bağımsız, uygulama geneli sayfalar ve shared widget'lar

```
views/
├── home_page.dart                    # 🏠 Ana sayfa
├── map_view.dart                     # 🗺️ Harita görünümü
├── notifications_page.dart            # 🔔 Bildirimler sayfası
├── settings_page.dart                 # ⚙️ Ayarlar sayfası
└── widgets/                           # 🧩 Shared Widget'lar
    ├── app_card.dart                  # Genel kart widget'ı
    ├── app_gradient_container.dart    # Gradient container
    ├── custom_bottom_navigation_bar.dart  # Alt navigasyon bar
    ├── modern_loading_widget.dart     # Loading widget'ı
    ├── nav_bar_icon.dart              # Navigasyon bar ikonu
    └── notification_item.dart         # Bildirim item widget'ı
```

**Not:** Feature-specific widget'lar artık `features/{feature}/presentation/widgets/` altında!

---

### 5️⃣ **`lib/l10n/`** - Çoklu Dil Desteği
**Amaç:** Uygulama çevirileri ve lokalizasyon

```
l10n/
├── app_localizations.dart            # Localization sınıfı
├── app_localizations_en.dart         # İngilizce çeviriler
├── app_localizations_tr.dart         # Türkçe çeviriler
├── app_en.arb                        # İngilizce kaynak dosyası
└── app_tr.arb                        # Türkçe kaynak dosyası
```

---

## 🔄 VERİ AKIŞI ÖRNEĞİ

### Senaryo: Kullanıcı bir mesaj gönderiyor

```
1. UI Layer (Presentation)
   └── private_chat_page.dart
       └── ChatInputBar widget'ı
           └── Kullanıcı mesaj yazar ve "Gönder" butonuna basar

2. ViewModel (Presentation)
   └── chat_viewmodel.dart
       └── sendMessage() metodu çağrılır

3. UseCase (Domain)
   └── send_message_usecase.dart
       └── İş mantığı kontrolü yapılır

4. Repository Interface (Domain)
   └── chat_repository.dart
       └── sendMessage() interface metodu

5. Repository Implementation (Data)
   └── chat_repository_impl.dart
       └── sendMessage() implementasyonu

6. DataSource (Data)
   └── chat_remote_data_source.dart
       └── Firestore'a mesaj kaydedilir

7. Firebase
   └── Firestore Database
       └── Mesaj veritabanına yazılır

8. Stream Update
   └── Firestore stream güncellenir
       └── UI otomatik olarak yeni mesajı gösterir
```

---

## 📊 İSTATİSTİKLER

### Dosya Dağılımı:
- **Core:** 20 dosya
- **Auth Feature:** 11 dosya
- **Chat Feature:** 50+ dosya (en büyük feature)
- **Event Feature:** 40+ dosya
- **User Feature:** 8 dosya
- **Notification Feature:** 3 dosya
- **Services:** 9 dosya
- **Views:** 10 dosya
- **L10n:** 5 dosya

### Toplam: ~150+ Dart dosyası

---

## ✅ MİMARİ PRENSİPLER

### 1. **Clean Architecture**
- ✅ Her feature 3 katmanlı (Data, Domain, Presentation)
- ✅ Dependency rule: Dış katmanlar iç katmanlara bağımlı
- ✅ Domain layer hiçbir şeye bağımlı değil (pure Dart)

### 2. **Feature-Based Organization**
- ✅ Her feature kendi modülünde
- ✅ Feature'lar birbirinden bağımsız
- ✅ Kolay bakım ve ölçeklenebilirlik

### 3. **Separation of Concerns**
- ✅ UI logic → ViewModel
- ✅ Business logic → UseCase
- ✅ Data logic → Repository/DataSource

### 4. **Dependency Injection**
- ✅ Provider pattern kullanılıyor
- ✅ `app_providers.dart` merkezi DI noktası

### 5. **State Management**
- ✅ Provider + ChangeNotifier
- ✅ Her feature kendi ViewModel'ine sahip

---

## 🎯 KLASÖR KULLANIM KURALLARI

### ✅ DOĞRU KULLANIM:

1. **Feature-specific kod** → `features/{feature}/`
2. **Uygulama geneli kod** → `core/` veya `services/`
3. **Shared UI** → `views/widgets/` (sadece gerçekten shared olanlar)
4. **Feature UI** → `features/{feature}/presentation/widgets/`

### ❌ YANLIŞ KULLANIM:

1. ❌ Feature-specific widget'ları `views/widgets/` altına koymak
2. ❌ Business logic'i ViewModel'e yazmak (UseCase kullanılmalı)
3. ❌ Domain entity'leri data layer'dan import etmek
4. ❌ Feature'lar arası direkt bağımlılık (core/services üzerinden olmalı)

---

## 📝 NOTLAR

- **Test dosyaları:** `test/` klasöründe, aynı yapıyı takip eder
- **Firebase config:** `firebase/` klasöründe (rules, indexes, vb.)
- **Platform files:** `android/` ve `ios/` klasörlerinde

---

**Son Güncelleme:** 7 Ocak 2026  
**Mimari:** Clean Architecture + Feature-Based  
**State Management:** Provider  
**Backend:** Firebase (Auth, Firestore, Storage, FCM)

