# 🧪 TEST PLANI - P0 & P1 Değişiklikleri

**Tarih:** 30 Aralık 2025  
**Kapsam:** Güvenlik (P0) ve Performans (P1) düzeltmeleri

---

## 📋 TEST STRATEJİSİ

### 1. ✅ Kod Analizi (Tamamlandı)
- **Flutter Analyze:** 0 error ✅
- **Linter:** 6 info (kritik değil) ✅
- **Mock Dosyaları:** Yeniden generate edildi ✅

---

### 2. 🔒 Firebase Rules Testleri

#### A. Storage Rules Test Senaryoları

**Test 1: Profile Photo Upload - UID Kontrolü**
```bash
# ✅ BAŞARILI: Kendi UID'sine yazma
Path: profile_photos/user123/file.jpg
Auth: user123
Expected: ✅ ALLOW

# ❌ BAŞARISIZ: Başkasının UID'sine yazma
Path: profile_photos/user456/file.jpg
Auth: user123
Expected: ❌ DENY
```

**Test 2: Event Cover Upload - Size Kontrolü**
```bash
# ✅ BAŞARILI: 5MB dosya
Size: 5MB
ContentType: image/jpeg
Expected: ✅ ALLOW

# ❌ BAŞARISIZ: 15MB dosya
Size: 15MB
ContentType: image/jpeg
Expected: ❌ DENY (10MB limit)
```

**Test 3: Chat Files - ChatId + SenderId Kontrolü**
```bash
# ✅ BAŞARILI: Kendi chat klasörüne yazma
Path: chat_files/chat123/user123/file.pdf
Auth: user123
Expected: ✅ ALLOW

# ❌ BAŞARISIZ: Başkasının klasörüne yazma
Path: chat_files/chat123/user456/file.pdf
Auth: user123
Expected: ❌ DENY
```

**Test 4: Genel Path Write - Kapalı Olmalı**
```bash
# ❌ BAŞARISIZ: Genel path'e yazma
Path: random_folder/file.txt
Auth: user123
Expected: ❌ DENY
```

#### B. Firestore Rules Test Senaryoları

**Test 5: Messages Update - Sadece Sender**
```bash
# ✅ BAŞARILI: Kendi mesajını update etme
Message senderId: user123
Auth: user123
Expected: ✅ ALLOW

# ❌ BAŞARISIZ: Başkasının mesajını update etme
Message senderId: user456
Auth: user123
Expected: ❌ DENY
```

**Test 6: Event Messages - Create/Update/Delete Ayrımı**
```bash
# ✅ BAŞARILI: Event participant mesaj oluşturma
Event participant: user123
Auth: user123
senderId: user123
Expected: ✅ ALLOW (create)

# ❌ BAŞARISIZ: Başkasının mesajını update etme
Message senderId: user456
Auth: user123
Expected: ❌ DENY (update)
```

---

### 3. ⚡ Performans Testleri

#### A. Chat Stream Performans

**Test 7: Server-side OrderBy + Limit**
```dart
// Beklenen: Sadece son 50 mesaj çekilmeli
// Önceki: Tüm mesajlar çekilip client-side sort
// Şimdi: Server-side orderBy + limit

// Test:
1. Chat'te 1000 mesaj olsun
2. getMessagesStream(chatId, limit: 50) çağır
3. Firestore'da sadece 50 read olmalı (önceden 1000)
```

**Test 8: Pagination - startAfter**
```dart
// Beklenen: Sadece 20 eski mesaj çekilmeli
// Önceki: limit(40) çekip client-side filtrele
// Şimdi: endBefore ile server-side pagination

// Test:
1. Chat'te 100 mesaj olsun
2. loadOlderMessages(chatId, lastMessageTime, limit: 20) çağır
3. Firestore'da sadece 20 read olmalı (önceden 40)
```

---

### 4. 🔧 DI/Provider Pattern Testi

**Test 9: Repository Güncelleme**
```dart
// Beklenen: Repository hazır olduğunda ViewModel güncellenmeli
// Önceki: previous != null ise repository güncellenmiyordu
// Şimdi: Repository hazır olduğunda yeni ViewModel oluşturuluyor

// Test:
1. Uygulama başlatıldığında temporary repository ile ViewModel oluşur
2. FutureProvider repository'yi hazırlar
3. ViewModel yeni repository ile yeniden oluşturulmalı
```

---

## 🚀 TEST ÇALIŞTIRMA ADIMLARI

### Adım 1: Firebase Rules Simulator (Firebase Console)

1. Firebase Console'a git: https://console.firebase.google.com
2. Proje seç: `thunder-52d2e`
3. Firestore Database → Rules → Rules Playground
4. Storage → Rules → Rules Playground

**Test Senaryoları:**
- Storage Rules: Yukarıdaki Test 1-4 senaryolarını test et
- Firestore Rules: Yukarıdaki Test 5-6 senaryolarını test et

---

### Adım 2: Flutter Unit Testleri

```bash
# Tüm testleri çalıştır
flutter test

# Sadece chat testleri
flutter test test/features/chat/

# Sadece event testleri
flutter test test/features/event/
```

**Not:** Bazı testler güncellenmeli (yeni parametreler için)

---

### Adım 3: Manuel Test (Uygulama Çalıştırma)

```bash
# Uygulamayı çalıştır
flutter run

# Test senaryoları:
1. Profile photo upload (kendi fotoğrafını yükle)
2. Event cover upload (etkinlik kapak fotoğrafı yükle)
3. Chat mesaj gönderme (sesli mesaj, dosya)
4. Chat mesajları görüntüleme (pagination test)
5. Mesaj update etme (sadece kendi mesajını)
```

---

### Adım 4: Firebase Rules Emulator (Opsiyonel)

```bash
# Firebase emulator'ı başlat
firebase emulators:start

# Rules'ı test et
firebase emulators:exec --only firestore,storage "flutter test"
```

---

## 📊 BEKLENEN SONUÇLAR

### ✅ Başarılı Test Kriterleri

1. **Storage Rules:**
   - ✅ Kendi dosyasına yazma: ALLOW
   - ✅ Başkasının dosyasına yazma: DENY
   - ✅ Büyük dosya (>10MB): DENY
   - ✅ Genel path'e yazma: DENY

2. **Firestore Rules:**
   - ✅ Kendi mesajını update: ALLOW
   - ✅ Başkasının mesajını update: DENY
   - ✅ Event participant mesaj oluşturma: ALLOW

3. **Performans:**
   - ✅ Chat stream: Sadece 50 mesaj çekilmeli
   - ✅ Pagination: Sadece 20 mesaj çekilmeli
   - ✅ Firestore read maliyeti düşmeli

4. **DI Pattern:**
   - ✅ Repository hazır olduğunda ViewModel güncellenmeli

---

## 🐛 POTANSİYEL SORUNLAR VE ÇÖZÜMLERİ

### Sorun 1: Firebase Index Eksik
**Belirti:** Firestore query hatası  
**Çözüm:** `firebase deploy --only firestore:indexes`

### Sorun 2: Storage Path Değişikliği
**Belirti:** Eski dosyalar bulunamıyor  
**Çözüm:** Migration script'i çalıştır (gelecekte)

### Sorun 3: Test Mock'ları Eski
**Belirti:** Test hataları  
**Çözüm:** `flutter pub run build_runner build --delete-conflicting-outputs` ✅ (Yapıldı)

---

## 📝 TEST RAPORU ŞABLONU

```markdown
## Test Sonuçları

### Storage Rules
- [ ] Test 1: Profile Photo UID Kontrolü
- [ ] Test 2: Size Kontrolü
- [ ] Test 3: Chat Files Kontrolü
- [ ] Test 4: Genel Path Kapalı

### Firestore Rules
- [ ] Test 5: Messages Update
- [ ] Test 6: Event Messages

### Performans
- [ ] Test 7: Chat Stream
- [ ] Test 8: Pagination

### DI Pattern
- [ ] Test 9: Repository Güncelleme
```

---

**Son Güncelleme:** 30 Aralık 2025

