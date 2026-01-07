# 📋 YAPILACAKLAR LİSTESİ - THUNDER PROJESİ

**Oluşturulma Tarihi:** 30 Aralık 2025  
**Kaynak:** FINAL_DURUM_RAPORU.md + ChatGPT Güvenlik/Performans Raporu  
**Durum:** Aktif

---

## 🎯 ÖNCELİK SIRASI

### 🔴 P0 - KRİTİK (Hemen Yapılmalı - Güvenlik)

#### 1. Storage Rules Güvenlik Açığı
**Sorun:** Her auth kullanıcı herkesin dosyasını overwrite edebilir  
**Dosya:** `storage.rules`

**Yapılacaklar:**
- [ ] `profile_photos/{uid}/{fileId}.jpg` formatına geç
- [ ] `event_covers/{eventId}/{fileId}.jpg` formatına geç (event owner check)
- [ ] `chat_files/{chatId}/{uid}/{fileId}` formatına geç
- [ ] Size limit ekle: `request.resource.size < 10 * 1024 * 1024`
- [ ] ContentType kontrolü ekle: `request.resource.contentType.matches('image/.*')`
- [ ] Genel `{allPaths=**}` write hakkını kapat

**Tahmini Süre:** 2-3 saat

---

#### 2. Firestore /messages Update Yetkisi
**Sorun:** Private chat'te her iki taraf da mesajları update edebilir  
**Dosya:** `firestore.rules` (satır 183-185)

**Yapılacaklar:**
- [ ] Update rule'unu sadece sender için geçerli yap
- [ ] Read/seen alanları için field-level validation ekle
- [ ] `chatIdContainsUser()` kontrolünü update'den kaldır

**Mevcut Kod:**
```javascript
allow update: if request.auth != null && 
  (request.auth.uid == resource.data.senderId ||
   chatIdContainsUser(resource.data.chatId)); // ❌ SORUN BURADA
```

**Hedef Kod:**
```javascript
allow update: if request.auth != null && 
  request.auth.uid == resource.data.senderId; // ✅ Sadece sender
```

**Tahmini Süre:** 30 dakika

---

#### 3. Event Subcollection Messages
**Sorun:** `write` create/update/delete hepsini kapsıyor, create'te `resource.data` yok  
**Dosya:** `firestore.rules` (satır 59-62)

**Yapılacaklar:**
- [ ] `allow create` ayrı: `request.resource.data.senderId == request.auth.uid` + participant check
- [ ] `allow update` ayrı: sender only (veya sadece read fields)
- [ ] `allow delete` ayrı: sender (veya event owner + sistem mesajı değilse)
- [ ] `resource.data.createdBy` yerine `request.resource.data.senderId` kullan (create için)

**Tahmini Süre:** 1 saat

---

### 🟡 P1 - YÜKSEK ÖNCELİK (Bu Hafta - Performans)

#### 4. Chat Mesaj Stream Performans Sorunu
**Sorun:** Server-side orderBy/limit yok, client-side sort yapılıyor  
**Dosya:** `lib/features/chat/data/datasources/chat_remote_data_source.dart` (satır 302-345)

**Yapılacaklar:**
- [ ] `getMessagesStream()` metoduna `.orderBy('timestamp', descending: true).limit(limit)` ekle
- [ ] UI'da mesajları ters çevir (en yeni altta)
- [ ] Firestore index oluştur: `messages(chatId, timestamp DESC)`
- [ ] Client-side sort'u kaldır

**Mevcut Kod:**
```dart
.where('chatId', isEqualTo: chatId)
.snapshots() // ❌ orderBy yok, limit yok
.map((snapshot) {
  // Client-side sort
  messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
  // Client-side limit
  final limitedMessages = messages.length > limit
      ? messages.sublist(messages.length - limit)
      : messages;
```

**Hedef Kod:**
```dart
.where('chatId', isEqualTo: chatId)
.orderBy('timestamp', descending: true) // ✅ Server-side
.limit(limit) // ✅ Server-side
.snapshots()
```

**Tahmini Süre:** 1-2 saat

---

#### 5. Pagination Yanlış Modeli
**Sorun:** `limit(limit*2)` çekip client-side filtreliyor  
**Dosya:** `lib/features/chat/data/datasources/chat_remote_data_source.dart` (satır 348-369)

**Yapılacaklar:**
- [ ] `loadOlderMessages()` metodunu `startAfter([lastTimestamp])` ile düzelt
- [ ] `.orderBy('timestamp', descending: true)` ekle
- [ ] `.limit(limit)` ekle
- [ ] Client-side `removeWhere` ve `sort` kaldır

**Mevcut Kod:**
```dart
.limit(limit * 2) // ❌ Fazla çekiyor
.get();
messages.removeWhere((msg) => msg.timestamp.isAfter(lastMessageTime)); // ❌ Client-side
messages.sort((a, b) => a.timestamp.compareTo(b.timestamp)); // ❌ Client-side
```

**Hedef Kod:**
```dart
.where('chatId', isEqualTo: chatId)
.orderBy('timestamp', descending: true) // ✅
.startAfter([lastTimestamp]) // ✅
.limit(limit) // ✅
.get();
```

**Tahmini Süre:** 1 saat

---

#### 6. DI/Provider Pattern Sorunu
**Sorun:** Repository güncellenmeyebilir (temporary repository pattern)  
**Dosya:** `lib/core/providers/app_providers.dart` (satır 106-156)

**Yapılacaklar:**
- [ ] ViewModel'lere repository setter ekle
- [ ] `update` metodunda `previous.repository = authRepository` gibi güncelle
- [ ] Veya VM'leri repository hazır olduktan sonra üret (null state ile UI beklet)

**Mevcut Kod:**
```dart
update: (_, authRepository, previous) {
  if (previous != null) {
    return previous; // ❌ Repository güncellenmiyor
  }
  return AuthViewModel(authRepository: authRepository);
}
```

**Tahmini Süre:** 2-3 saat

---

### 🟢 P2 - ORTA ÖNCELİK (Bu Ay - Mimari)

#### 7. Mimari Karışıklık
**Sorun:** `lib/views/` ve `lib/features/*/presentation/` paralel kullanılıyor  
**Dosyalar:** Tüm `lib/views/*` dosyaları

**Yapılacaklar:**
- [ ] Her feature'ın UI'ını `features/<feature>/presentation/pages/` altına taşı
- [ ] `views/` klasörünü sadece "shell/root" için kullan
- [ ] Veya tamamen `features/*/presentation/` yapısına geç

**Tahmini Süre:** 1-2 gün

---

#### 8. Lint & Context Güvenliği
**Sorun:** `use_build_context_synchronously: ignore` gerçek bug'ları gizleyebilir  
**Dosya:** `analysis_options.yaml` (satır 31)

**Yapılacaklar:**
- [ ] `ignore`'u kaldır
- [ ] Projede standart `mounted` kontrol pattern'i oluştur
- [ ] En bariz 5-10 warning'i düzelt
- [ ] Gerekli yerlerde `if (!context.mounted) return;` ekle

**Tahmini Süre:** 2-3 saat

---

## 📊 ÖNCELİK ÖZETİ

| Öncelik | Sorun | Süre | Etki |
|---------|-------|------|------|
| 🔴 P0 | Storage Rules | 2-3 saat | Güvenlik açığı kapatılır |
| 🔴 P0 | Firestore Messages Update | 30 dk | Mesaj manipülasyonu engellenir |
| 🔴 P0 | Event Messages Rules | 1 saat | Event chat güvenliği |
| 🟡 P1 | Chat Stream Performans | 1-2 saat | Firestore maliyeti düşer, UI jank azalır |
| 🟡 P1 | Pagination | 1 saat | Scale olur, performans artar |
| 🟡 P1 | DI Pattern | 2-3 saat | Repository güncelleme sorunu çözülür |
| 🟢 P2 | Mimari Temizlik | 1-2 gün | Bakım kolaylaşır |
| 🟢 P2 | Context Güvenliği | 2-3 saat | Potansiyel crash'ler önlenir |

**TOPLAM TAHMİNİ SÜRE:** ~2-3 gün (P0+P1), ~1 hafta (tümü)

---

## 🚀 HIZLI KAZANIMLAR (1 Günde Yapılacaklar)

1. ✅ Chat `getMessagesStream`'e `orderBy+limit` ekle (hemen performans ve maliyet düşer)
2. ✅ `/messages` update rule'unu "sender only" yap (en kritik güvenlik deliğini kapatır)
3. ✅ Storage'da `{allPaths=**}` write'ı kapat, en azından profile/event/chat için UID bazlı path'e geç
4. ✅ `use_build_context_synchronously` ignore'u kaldırıp en bariz 5-10 warning'i düzelt

---

## 📝 NOTLAR

1. **Güvenlik Öncelikli:** P0 sorunlar production'da ciddi risk oluşturuyor, önce bunlar yapılmalı
2. **Performans İkinci:** P1 sorunlar maliyet ve kullanıcı deneyimini etkiliyor
3. **Mimari Son:** P2 sorunlar bakımı zorlaştırıyor ama çalışan sistemi bozmuyor
4. **Test:** Her değişiklikten sonra test edilmeli, özellikle Firebase rules değişiklikleri

---

**Son Güncelleme:** 30 Aralık 2025

