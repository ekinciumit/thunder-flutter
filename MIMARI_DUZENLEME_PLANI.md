# Mimari Düzenleme Planı (P2)

## Mevcut Durum
- `lib/views/` altında tüm sayfalar var
- `lib/features/*/presentation/` altında sadece viewmodels var
- Router `lib/views/` import ediyor

## Hedef Yapı
Her feature'ın kendi `presentation/pages/` klasörü olacak.

## Taşınacak Dosyalar

### 1. Auth Feature
- `lib/views/auth_page.dart` → `lib/features/auth/presentation/pages/auth_page.dart`
- `lib/views/complete_profile_page.dart` → `lib/features/auth/presentation/pages/complete_profile_page.dart`
- `lib/views/edit_profile_page.dart` → `lib/features/auth/presentation/pages/edit_profile_page.dart`

### 2. Chat Feature
- `lib/views/private_chat_page.dart` → `lib/features/chat/presentation/pages/private_chat_page.dart`
- `lib/views/chat_list_page.dart` → `lib/features/chat/presentation/pages/chat_list_page.dart`
- `lib/views/message_forward_page.dart` → `lib/features/chat/presentation/pages/message_forward_page.dart`
- `lib/views/message_search_page.dart` → `lib/features/chat/presentation/pages/message_search_page.dart`

### 3. Event Feature
- `lib/views/event_detail_page.dart` → `lib/features/event/presentation/pages/event_detail_page.dart`
- `lib/views/create_event_page.dart` → `lib/features/event/presentation/pages/create_event_page.dart`
- `lib/views/event_list_view.dart` → `lib/features/event/presentation/pages/event_list_view.dart`
- `lib/views/my_events_page.dart` → `lib/features/event/presentation/pages/my_events_page.dart`

### 4. User Feature
- `lib/views/user_profile_page.dart` → `lib/features/user/presentation/pages/user_profile_page.dart`
- `lib/views/profile_view.dart` → `lib/features/user/presentation/pages/profile_view.dart`
- `lib/views/followers_following_page.dart` → `lib/features/user/presentation/pages/followers_following_page.dart`
- `lib/views/blocked_users_page.dart` → `lib/features/user/presentation/pages/blocked_users_page.dart`
- `lib/views/user_search_page.dart` → `lib/features/user/presentation/pages/user_search_page.dart`

### 5. Shared/Shell (views/ altında kalacak)
- `lib/views/home_page.dart` (shell - bottom navigation)
- `lib/views/map_view.dart` (shared)
- `lib/views/settings_page.dart` (shared)
- `lib/views/notifications_page.dart` (shared)

### 6. Widgets
- `lib/views/widgets/` → Feature'lara göre dağıtılacak veya `lib/core/widgets/` altına taşınacak
- Chat widget'ları → `lib/features/chat/presentation/widgets/`
- Event widget'ları → `lib/features/event/presentation/widgets/`
- User widget'ları → `lib/features/user/presentation/widgets/`
- Shared widget'lar → `lib/core/widgets/` veya `lib/views/widgets/` (shared)

## Yapılacaklar

1. ✅ Feature klasörlerinde `presentation/pages/` oluştur
2. ✅ Dosyaları taşı
3. ✅ Import path'lerini güncelle (tüm dosyalarda)
4. ✅ Router import'larını güncelle
5. ✅ Widget import'larını güncelle
6. ✅ Test et (flutter analyze, flutter run)

## Riskler
- Çok sayıda import path değişikliği
- Widget'ların dağıtımı karmaşık olabilir
- Test süresi: ~2-3 saat

## Alternatif (Daha Az Riskli)
Sadece import path'lerini düzenle, dosyaları taşıma. Ama bu Clean Architecture prensiplerine aykırı.

## Öneri
Adım adım yapalım:
1. Önce bir feature'ı taşı (ör: auth)
2. Test et
3. Diğerlerine geç

