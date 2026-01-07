# ⚠️ SEN YAPMALISIN - Manuel Test Adımları

**Tarih:** 30 Aralık 2025  
**Süre:** ~30 dakika

---

## 🔒 ADIM 1: FİREBASE RULES TESTİ (10 Dakika)

### Firebase Console'da Rules Playground

**URL:** https://console.firebase.google.com/project/thunder-52d2e

### Storage Rules Testi

1. **Storage Rules:**
   - Sol menü: **Storage** → **Rules** → **Rules Playground** (sağ üstte)

2. **Test Senaryoları:**

#### ✅ Test 1: Profile Photo - Kendi UID'sine Yazma
```
Path: profile_photos/user123/file.jpg
Authentication UID: user123
Operation: write
Expected: ✅ ALLOW
```
**Adımlar:**
- Path: `profile_photos/user123/file.jpg` yaz
- Authentication: `user123` seç (veya manuel UID gir)
- Operation: `write` seç
- **"Run"** butonuna tıkla
- Sonuç: ✅ **ALLOW** olmalı

#### ❌ Test 2: Profile Photo - Başkasının UID'sine Yazma
```
Path: profile_photos/user456/file.jpg
Authentication UID: user123
Operation: write
Expected: ❌ DENY
```
**Adımlar:**
- Path: `profile_photos/user456/file.jpg` yaz
- Authentication: `user123` seç
- Operation: `write` seç
- **"Run"** butonuna tıkla
- Sonuç: ❌ **DENY** olmalı

#### ✅ Test 3: Chat Files - Kendi Klasörüne Yazma
```
Path: chat_files/chat123/user123/file.pdf
Authentication UID: user123
Operation: write
Expected: ✅ ALLOW
```

#### ❌ Test 4: Chat Files - Başkasının Klasörüne Yazma
```
Path: chat_files/chat123/user456/file.pdf
Authentication UID: user123
Operation: write
Expected: ❌ DENY
```

---

### Firestore Rules Testi

1. **Firestore Rules:**
   - Sol menü: **Firestore Database** → **Rules** → **Rules Playground** (sağ üstte)

2. **Test Senaryoları:**

#### ✅ Test 5: Messages Update - Kendi Mesajını Update
```
Collection: messages
Document ID: msg123
Authentication UID: user123
Operation: update
Document Data (Resource):
  senderId: "user123"
  chatId: "chat123"
Expected: ✅ ALLOW
```

#### ❌ Test 6: Messages Update - Başkasının Mesajını Update
```
Collection: messages
Document ID: msg456
Authentication UID: user123
Operation: update
Document Data (Resource):
  senderId: "user456" (başkası)
  chatId: "chat123"
Expected: ❌ DENY
```

---

## 📱 ADIM 2: UYGULAMA TESTİ (15 Dakika)

### Uygulamayı Çalıştır
```bash
flutter run
```

### Test Senaryoları

#### Senaryo 1: Profile Photo Upload ✅
1. Uygulamayı aç
2. Profil sayfasına git
3. Fotoğraf yükle
4. **Kontrol:** Firebase Console → Storage → `profile_photos/` klasörü
   - ✅ Path: `profile_photos/{kendiUID}/file.jpg` formatında mı?

#### Senaryo 2: Chat Mesaj Gönderme ✅
1. Bir chat'e gir
2. Sesli mesaj gönder
3. Dosya gönder
4. **Kontrol:** Firebase Console → Storage
   - ✅ `voice_messages/{chatId}/{senderId}/file.m4a` var mı?
   - ✅ `chat_files/{chatId}/{senderId}/file.pdf` var mı?

#### Senaryo 3: Mesaj Update (Güvenlik) ✅
1. Bir chat'e gir
2. Kendi mesajını uzun bas → Edit → ✅ Başarılı olmalı
3. Başkasının mesajını uzun bas → ❌ Edit seçeneği olmamalı

---

## ⚡ ADIM 3: PERFORMANS ÖLÇÜMÜ (5 Dakika)

### Firestore Read Maliyeti

1. **Firebase Console:**
   - **Firestore Database** → **Usage** sekmesi

2. **Test:**
   - Chat açmadan önce read sayısını not et
   - Bir chat'e gir (1000+ mesajlı bir chat)
   - Read sayısını kontrol et
   - **Beklenen:** Sadece 50 read artmalı (önceden 1000)

---

## ✅ TEST SONUÇLARINI BANA SÖYLE

Testleri yaptıktan sonra şunları söyle:
- ✅ Hangi testler başarılı oldu?
- ❌ Hangi testler başarısız oldu?
- 🐛 Herhangi bir sorun gördün mü?

---

**Son Güncelleme:** 30 Aralık 2025

