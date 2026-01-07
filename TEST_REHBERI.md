# 🧪 TEST REHBERİ - Hızlı Test Senaryoları

**Tarih:** 30 Aralık 2025  
**Kapsam:** P0 & P1 Değişikliklerinin Test Edilmesi

---

## 🚀 HIZLI TEST (5 Dakika)

### 1. Kod Analizi ✅ (Tamamlandı)
```bash
flutter analyze lib
# Sonuç: 0 error, 6 info ✅
```

### 2. Firebase Rules - Firebase Console'da Test

**Adımlar:**
1. https://console.firebase.google.com → Proje: `thunder-52d2e`
2. **Storage** → **Rules** → **Rules Playground**
3. **Firestore** → **Rules** → **Rules Playground**

**Test Senaryoları:**

#### Storage Rules Test:
```
✅ Test 1: Profile Photo - Kendi UID'sine yazma
Path: profile_photos/user123/file.jpg
Auth: user123
Expected: ✅ ALLOW

❌ Test 2: Profile Photo - Başkasının UID'sine yazma
Path: profile_photos/user456/file.jpg
Auth: user123
Expected: ❌ DENY

✅ Test 3: Chat Files - Kendi klasörüne yazma
Path: chat_files/chat123/user123/file.pdf
Auth: user123
Expected: ✅ ALLOW

❌ Test 4: Chat Files - Başkasının klasörüne yazma
Path: chat_files/chat123/user456/file.pdf
Auth: user123
Expected: ❌ DENY

❌ Test 5: Büyük Dosya (>10MB)
Path: profile_photos/user123/large.jpg
Auth: user123
Size: 15MB
Expected: ❌ DENY
```

#### Firestore Rules Test:
```
✅ Test 6: Messages Update - Kendi mesajını update
Message senderId: user123
Auth: user123
Expected: ✅ ALLOW

❌ Test 7: Messages Update - Başkasının mesajını update
Message senderId: user456
Auth: user123
Expected: ❌ DENY
```

---

## 📱 MANUEL TEST (Uygulama Çalıştırma)

### Adım 1: Uygulamayı Çalıştır
```bash
flutter run
```

### Adım 2: Test Senaryoları

#### Senaryo 1: Profile Photo Upload
1. ✅ Profil sayfasına git
2. ✅ Fotoğraf yükle
3. ✅ Firebase Console → Storage → `profile_photos/{uid}/` kontrol et
4. ✅ Path doğru mu? `profile_photos/user123/file.jpg` formatında mı?

#### Senaryo 2: Chat Mesaj Gönderme
1. ✅ Bir chat'e gir
2. ✅ Sesli mesaj gönder
3. ✅ Dosya gönder
4. ✅ Firebase Console → Storage kontrol et:
   - `voice_messages/{chatId}/{senderId}/file.m4a` ✅
   - `chat_files/{chatId}/{senderId}/file.pdf` ✅

#### Senaryo 3: Chat Mesajları Görüntüleme
1. ✅ Chat'e gir
2. ✅ Firebase Console → Firestore → `messages` koleksiyonu
3. ✅ Query: `where chatId == 'xxx' orderBy timestamp desc limit 50`
4. ✅ Sadece 50 mesaj çekilmeli (önceden tüm mesajlar çekiliyordu)

#### Senaryo 4: Pagination (Eski Mesajlar)
1. ✅ Chat'te yukarı scroll yap (eski mesajları yükle)
2. ✅ Firebase Console → Firestore → `messages` koleksiyonu
3. ✅ Query: `where chatId == 'xxx' orderBy timestamp asc endBefore [timestamp] limit 20`
4. ✅ Sadece 20 mesaj çekilmeli (önceden 40 çekip filtreliyordu)

#### Senaryo 5: Mesaj Update (Güvenlik)
1. ✅ Kendi mesajını edit et → ✅ Başarılı olmalı
2. ✅ Başkasının mesajını edit etmeyi dene → ❌ Başarısız olmalı (Firestore rules)

---

## 🔍 PERFORMANS TESTİ

### Chat Stream Performans Ölçümü

**Önceki Durum:**
- 1000 mesajlı chat'te: 1000 read (tüm mesajlar)
- Client-side sort: ~100ms
- RAM: Tüm mesajlar yükleniyor

**Yeni Durum:**
- 1000 mesajlı chat'te: 50 read (sadece son 50 mesaj)
- Server-side sort: 0ms (client-side yok)
- RAM: Sadece 50 mesaj yükleniyor

**Test:**
```bash
# Firebase Console → Usage → Firestore Reads
# Chat açıldığında sadece 50 read olmalı (önceden 1000)
```

---

## ✅ TEST CHECKLIST

### Güvenlik (P0)
- [ ] Storage: Profile photo UID kontrolü
- [ ] Storage: Chat files chatId+senderId kontrolü
- [ ] Storage: Size limit (10MB)
- [ ] Storage: Genel path write kapalı
- [ ] Firestore: Messages update sadece sender
- [ ] Firestore: Event messages create/update/delete ayrımı

### Performans (P1)
- [ ] Chat stream: Server-side orderBy + limit
- [ ] Pagination: Server-side endBefore + limit
- [ ] Firestore read maliyeti düştü mü?

### DI Pattern (P1)
- [ ] Repository hazır olduğunda ViewModel güncelleniyor mu?

---

## 🐛 BİLİNEN SORUNLAR

### Test Mock'ları
- ✅ Mock dosyaları yeniden generate edildi
- ✅ Interface değişiklikleri mock'lara yansıdı

### Firebase Index
- ⚠️ `loadOlderMessages` için ascending index gerekli
- ✅ Index zaten mevcut: `chatId (ASC) + timestamp (ASC)`

---

## 📊 BEKLENEN SONUÇLAR

### Başarı Kriterleri:
1. ✅ Storage rules: Sadece kendi dosyasına yazabilir
2. ✅ Firestore rules: Sadece kendi mesajını update edebilir
3. ✅ Chat stream: Sadece 50 mesaj çekiliyor
4. ✅ Pagination: Sadece 20 mesaj çekiliyor
5. ✅ Firestore read maliyeti: ~%80 azaldı

---

**Son Güncelleme:** 30 Aralık 2025

