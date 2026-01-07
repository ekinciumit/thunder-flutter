# 📱 MANUEL TEST ADIMLARI - Adım Adım Rehber

**Tarih:** 30 Aralık 2025  
**Kapsam:** P0 & P1 Değişikliklerinin Test Edilmesi

---

## 🔒 ADIM 1: FİREBASE RULES TESTİ (Firebase Console)

### ⚠️ SEN YAPMALISIN: Firebase Console'da Rules Playground

**Süre:** ~10 dakika

### Storage Rules Testi

1. **Firebase Console'a Git:**
   - https://console.firebase.google.com
   - Proje: `thunder-52d2e`
   - **Storage** → **Rules** → **Rules Playground** (sağ üstte)

2. **Test Senaryoları:**

#### ✅ Test 1: Profile Photo - Kendi UID'sine Yazma
```
Path: profile_photos/user123/file.jpg
Auth: user123 (Authentication UID)
Operation: write
Expected: ✅ ALLOW
```
**Nasıl Test Et:**
- Path: `profile_photos/user123/file.jpg`
- Authentication: `user123` seç
- Operation: `write` seç
- **"Run"** butonuna tıkla
- Sonuç: ✅ **ALLOW** olmalı

#### ❌ Test 2: Profile Photo - Başkasının UID'sine Yazma
```
Path: profile_photos/user456/file.jpg
Auth: user123
Operation: write
Expected: ❌ DENY
```
**Nasıl Test Et:**
- Path: `profile_photos/user456/file.jpg`
- Authentication: `user123` seç
- Operation: `write` seç
- **"Run"** butonuna tıkla
- Sonuç: ❌ **DENY** olmalı

#### ✅ Test 3: Chat Files - Kendi Klasörüne Yazma
```
Path: chat_files/chat123/user123/file.pdf
Auth: user123
Operation: write
Expected: ✅ ALLOW
```

#### ❌ Test 4: Chat Files - Başkasının Klasörüne Yazma
```
Path: chat_files/chat123/user456/file.pdf
Auth: user123
Operation: write
Expected: ❌ DENY
```

#### ❌ Test 5: Size Limit (>10MB)
```
Path: profile_photos/user123/large.jpg
Auth: user123
Operation: write
Size: 15MB (15000000 bytes)
Expected: ❌ DENY
```
**Nasıl Test Et:**
- Path: `profile_photos/user123/large.jpg`
- Authentication: `user123` seç
- Operation: `write` seç
- **Request** sekmesinde:
  - `request.resource.size`: `15000000` (15MB)
- **"Run"** butonuna tıkla
- Sonuç: ❌ **DENY** olmalı

---

### Firestore Rules Testi

1. **Firebase Console:**
   - **Firestore Database** → **Rules** → **Rules Playground**

2. **Test Senaryoları:**

#### ✅ Test 6: Messages Update - Kendi Mesajını Update
```
Collection: messages
Document ID: msg123
Auth: user123
Operation: update
Document Data:
  - senderId: "user123"
  - chatId: "chat123"
Expected: ✅ ALLOW
```

#### ❌ Test 7: Messages Update - Başkasının Mesajını Update
```
Collection: messages
Document ID: msg456
Auth: user123
Operation: update
Document Data:
  - senderId: "user456" (başkası)
  - chatId: "chat123"
Expected: ❌ DENY
```

#### ✅ Test 8: Event Messages - Create
```
Collection: events/event123/messages
Document ID: msg789
Auth: user123
Operation: create
Document Data:
  - senderId: "user123"
  - userId: "user123"
Expected: ✅ ALLOW (event participant ise)
```

---

## 📱 ADIM 2: MANUEL TEST (Uygulama Çalıştırma)

### ⚠️ SEN YAPMALISIN: Uygulamayı Çalıştır ve Test Et

**Süre:** ~15 dakika

### Adım 2.1: Uygulamayı Çalıştır
```bash
flutter run
```

### Adım 2.2: Test Senaryoları

#### Senaryo 1: Profile Photo Upload ✅
1. Uygulamayı aç
2. Profil sayfasına git
3. Fotoğraf yükle butonuna tıkla
4. Bir fotoğraf seç ve yükle
5. **Kontrol:** Firebase Console → Storage → `profile_photos/` klasörüne bak
   - ✅ Path: `profile_photos/{kendiUID}/file.jpg` formatında mı?
   - ✅ Dosya yüklendi mi?

#### Senaryo 2: Chat Mesaj Gönderme ✅
1. Bir chat'e gir
2. Sesli mesaj gönder (mikrofon butonu)
3. Dosya gönder (dosya butonu)
4. **Kontrol:** Firebase Console → Storage kontrol et:
   - ✅ `voice_messages/{chatId}/{senderId}/file.m4a` var mı?
   - ✅ `chat_files/{chatId}/{senderId}/file.pdf` var mı?

#### Senaryo 3: Mesaj Update (Güvenlik) ✅
1. Bir chat'e gir
2. Kendi mesajını uzun bas (edit seçeneği)
3. Mesajı düzenle → ✅ Başarılı olmalı
4. Başkasının mesajını uzun bas → ❌ Edit seçeneği olmamalı veya hata vermeli

#### Senaryo 4: Chat Mesajları Görüntüleme (Performans) ✅
1. Bir chat'e gir (100+ mesajlı bir chat)
2. Firebase Console → Firestore → `messages` koleksiyonu
3. **Kontrol:** Query log'larına bak
   - ✅ Query: `where chatId == 'xxx' orderBy timestamp desc limit 50`
   - ✅ Sadece 50 mesaj çekilmeli (önceden tüm mesajlar çekiliyordu)

#### Senaryo 5: Pagination (Eski Mesajlar) ✅
1. Chat'te yukarı scroll yap (eski mesajları yükle)
2. Firebase Console → Firestore → `messages` koleksiyonu
3. **Kontrol:** Query log'larına bak
   - ✅ Query: `where chatId == 'xxx' orderBy timestamp asc endBefore [timestamp] limit 20`
   - ✅ Her pagination'da sadece 20 mesaj çekilmeli

---

## ⚡ ADIM 3: PERFORMANS ÖLÇÜMÜ

### ⚠️ SEN YAPMALISIN: Firebase Console'da Read Sayısını Kontrol Et

**Süre:** ~5 dakika

### Adım 3.1: Firestore Read Maliyeti

1. **Firebase Console:**
   - **Firestore Database** → **Usage** sekmesi

2. **Test:**
   - Chat açmadan önce read sayısını not et
   - Bir chat'e gir (1000+ mesajlı bir chat)
   - Read sayısını tekrar kontrol et
   - **Beklenen:** Sadece 50 read artmalı (önceden 1000 artıyordu)

3. **Pagination Test:**
   - Chat'te yukarı scroll yap (eski mesajları yükle)
   - Read sayısını kontrol et
   - **Beklenen:** Her pagination'da sadece 20 read artmalı

---

## ✅ TEST CHECKLIST

### Firebase Rules (Firebase Console)
- [ ] Storage: Profile Photo UID Kontrolü (Test 1-2)
- [ ] Storage: Chat Files Kontrolü (Test 3-4)
- [ ] Storage: Size Limit (Test 5)
- [ ] Firestore: Messages Update (Test 6-7)
- [ ] Firestore: Event Messages (Test 8)

### Manuel Test (Uygulama)
- [ ] Profile Photo Upload (Senaryo 1)
- [ ] Chat Mesaj Gönderme (Senaryo 2)
- [ ] Mesaj Update (Senaryo 3)
- [ ] Chat Stream Performans (Senaryo 4)
- [ ] Pagination Performans (Senaryo 5)

### Performans Ölçümü
- [ ] Firestore Read Maliyeti (Adım 3)

---

## 🐛 SORUN GÖRÜRSEN

### Sorun 1: Firebase Rules Syntax Hatası
**Belirti:** Rules Playground'da syntax error  
**Çözüm:** Bana söyle, düzeltirim

### Sorun 2: Storage Path Hatası
**Belirti:** Dosya yüklenemiyor  
**Çözüm:** Firebase Console → Storage → Rules → Rules Playground'da test et

### Sorun 3: Firestore Query Hatası
**Belirti:** "Index required" hatası  
**Çözüm:** `firebase deploy --only firestore:indexes` çalıştır

---

**Son Güncelleme:** 30 Aralık 2025

