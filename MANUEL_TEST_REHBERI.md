# Manuel Test Rehberi

## ✅ Tamamlanan Optimizasyonlar

1. **Görsel Sıkıştırma** - %70-80 storage maliyeti azalması
2. **Stream Limitleri** - %40-60 read maliyeti azalması
3. **Mesaj Arama Optimizasyonu** - Optimize edilmiş N-query metodu
4. **Map Load Cache** - %50-70 map load maliyeti azalması

---

## 🔥 Firebase Index Deploy

✅ **Tamamlandı**: `firebase deploy --only firestore:indexes`

**Deploy edilen index'ler:**
- `messages` collection: `chatId + timestamp` (ASC/DESC)
- `messages` collection: `chatId + text + timestamp` (DESC)
- `chats` collection: `participants + lastMessageAt` (DESC)
- `events` collection: `createdBy + datetime` (DESC)
- `notifications` collection: `userId + createdAt` (DESC)

---

## 📋 Manuel Test Adımları

### 1. Görsel Sıkıştırma Testi

#### 1.1 Profil Fotoğrafı Upload
- [ ] Profil sayfasına git
- [ ] Fotoğraf seç (büyük bir fotoğraf, örn: 5MB+)
- [ ] Upload yap
- [ ] Firebase Console → Storage → `profile_photos/{userId}/` kontrol et
- [ ] Dosya boyutunun orijinalinden %70-80 daha küçük olduğunu doğrula
- [ ] Fotoğraf kalitesinin kabul edilebilir olduğunu doğrula

#### 1.2 Event Cover Fotoğrafı Upload
- [ ] Event oluştur sayfasına git
- [ ] Cover fotoğrafı seç (büyük bir fotoğraf, örn: 8MB+)
- [ ] Event oluştur
- [ ] Firebase Console → Storage → `event_covers/{eventId}/` kontrol et
- [ ] Dosya boyutunun orijinalinden %70-80 daha küçük olduğunu doğrula
- [ ] Fotoğraf kalitesinin kabul edilebilir olduğunu doğrula

#### 1.3 Chat Medya (Image) Upload
- [ ] Chat'e git
- [ ] Büyük bir fotoğraf gönder (örn: 10MB+)
- [ ] Firebase Console → Storage → `chat_media/{eventId}/` kontrol et
- [ ] Dosya boyutunun orijinalinden %70-80 daha küçük olduğunu doğrula
- [ ] Fotoğraf kalitesinin kabul edilebilir olduğunu doğrula

**Beklenen Sonuç:**
- Profil fotoğrafları: Max 800x800px, %80 kalite
- Event cover: Max 1200x1200px, %85 kalite
- Chat medya: Max 1000x1000px, %85 kalite

---

### 2. Stream Limitleri Testi

#### 2.1 User Events Stream
- [ ] Profil sayfasına git (kendi profilin veya başka birinin)
- [ ] Firebase Console → Firestore → `events` collection aç
- [ ] Firestore Console'da "Network Requests" izle
- [ ] Profil sayfasındaki events listesini gözlemle
- [ ] **Beklenen**: Sadece en son 20 event'in yüklendiğini doğrula
- [ ] Firestore Console'da sadece 20 doküman okunduğunu doğrula

#### 2.2 Event Comments Stream
- [ ] Bir event detay sayfasına git
- [ ] Firebase Console → Firestore → `events/{eventId}/comments` subcollection aç
- [ ] Firestore Console'da "Network Requests" izle
- [ ] Comments listesini gözlemle
- [ ] **Beklenen**: Sadece en son 50 comment'in yüklendiğini doğrula
- [ ] Firestore Console'da sadece 50 doküman okunduğunu doğrula

#### 2.3 Chat Messages Stream
- [ ] Bir chat'e git
- [ ] Firebase Console → Firestore → `messages` collection aç
- [ ] Firestore Console'da "Network Requests" izle
- [ ] Chat mesajlarını gözlemle
- [ ] **Beklenen**: Sadece en son 50 mesajın yüklendiğini doğrula
- [ ] Firestore Console'da sadece 50 doküman okunduğunu doğrula

**Beklenen Sonuç:**
- Her stream için belirtilen limit kadar doküman okunmalı
- Gereksiz okuma işlemi yapılmamalı

---

### 3. Mesaj Arama Optimizasyonu Testi

#### 3.1 Tek Chat'te Arama
- [ ] Bir chat'e git
- [ ] Mesaj arama özelliğini kullan (eğer varsa) veya `searchMessages` fonksiyonunu test et
- [ ] Firebase Console → Firestore → "Network Requests" izle
- [ ] Bir kelime ara (örn: "merhaba")
- [ ] **Beklenen**: 
  - `where('chatId', isEqualTo: chatId) + orderBy('timestamp', descending: true) + limit(50)` query'si çalışmalı
  - Sadece ilgili chat'teki mesajlar aranmalı
  - Server-side orderBy ve limit kullanılmalı

#### 3.2 Tüm Chat'lerde Arama
- [ ] Global mesaj arama özelliğini kullan (eğer varsa)
- [ ] Firebase Console → Firestore → "Network Requests" izle
- [ ] Bir kelime ara
- [ ] **Beklenen**:
  - Önce `chats` collection'da `where('participants', arrayContains: userId)` ile chat'ler alınmalı
  - Sonra her chat için `searchMessages` çağrılmalı (her biri server-side limit ile)
  - Sonuçlar client-side birleştirilip sıralanmalı
  - Her chat için maksimum 20 sonuç getirilmeli

**Beklenen Sonuç:**
- Arama hızlı olmalı
- Gereksiz okuma işlemi yapılmamalı
- Server-side orderBy ve limit kullanılmalı

---

### 4. Map Load Cache Testi

#### 4.1 İlk Map Açılışı
- [ ] Map sayfasına git
- [ ] Firebase Console → Google Maps API → "Usage" kontrol et
- [ ] **Beklenen**: 1 map load sayılmalı

#### 4.2 Cache ile Map Açılışı (Aynı Konum)
- [ ] Map sayfasından çık
- [ ] 2-3 saniye bekle (cache hala geçerli olmalı)
- [ ] Tekrar map sayfasına git (aynı konum)
- [ ] Firebase Console → Google Maps API → "Usage" kontrol et
- [ ] **Beklenen**: Map load sayısı artmamalı (cache kullanıldı)

#### 4.3 Cache ile Map Açılışı (Farklı Konum, Yakın)
- [ ] Map sayfasından çık
- [ ] Yakın bir konuma git (örn: 500m içinde)
- [ ] Tekrar map sayfasına git
- [ ] Firebase Console → Google Maps API → "Usage" kontrol et
- [ ] **Beklenen**: Map load sayısı artmamalı (cache kullanıldı, 1km içinde)

#### 4.4 Cache Sonrası Map Açılışı (Farklı Konum, Uzak)
- [ ] Map sayfasından çık
- [ ] Uzak bir konuma git (örn: 2km+)
- [ ] Tekrar map sayfasına git
- [ ] Firebase Console → Google Maps API → "Usage" kontrol et
- [ ] **Beklenen**: Map load sayısı artmalı (cache geçersiz, yeni map yüklendi)

#### 4.5 Cache Sonrası Map Açılışı (Zaman Aşımı)
- [ ] Map sayfasına git
- [ ] 6 dakika bekle (cache 5 dakika geçerli)
- [ ] Tekrar map sayfasına git (aynı konum)
- [ ] Firebase Console → Google Maps API → "Usage" kontrol et
- [ ] **Beklenen**: Map load sayısı artmalı (cache zaman aşımına uğradı)

**Beklenen Sonuç:**
- Aynı konumda veya yakın konumda (<1km) cache kullanılmalı
- Uzak konumda (>1km) veya zaman aşımından sonra (>5dk) yeni map yüklenmeli
- Map load sayısı azalmalı (%50-70 tasarruf)

---

### 5. Firebase Console Maliyet İzleme

#### 5.1 Firestore Usage
- [ ] Firebase Console → Firestore → Usage sekmesi
- [ ] **İzle:**
  - Document reads (stream limitleri nedeniyle azalmalı)
  - Document writes
  - Storage (görsel sıkıştırma nedeniyle azalmalı)

#### 5.2 Storage Usage
- [ ] Firebase Console → Storage → Usage sekmesi
- [ ] **İzle:**
  - Storage kullanımı (GB) - görsel sıkıştırma nedeniyle azalmalı
  - Bandwidth (GB) - görsel sıkıştırma nedeniyle azalmalı

#### 5.3 Google Maps API Usage
- [ ] Google Cloud Console → APIs & Services → Google Maps JavaScript API
- [ ] **İzle:**
  - Map loads (cache nedeniyle azalmalı)
  - Static map requests
  - Geocoding requests

**Beklenen Sonuç:**
- Firestore reads: %40-60 azalma (stream limitleri nedeniyle)
- Storage: %70-80 azalma (görsel sıkıştırma nedeniyle)
- Map loads: %50-70 azalma (cache nedeniyle)

---

## 🐛 Olası Hatalar ve Çözümleri

### 1. Image Compression Hatası
**Problem**: Fotoğraf upload edilirken hata alıyorum.

**Çözüm:**
- Console'da `image` paketinin yüklü olduğunu kontrol et
- `flutter pub get` çalıştır
- Dosya formatını kontrol et (JPG/PNG olmalı)

### 2. Stream Limit Çalışmıyor
**Problem**: Stream'de hala tüm dokümanlar geliyor.

**Çözüm:**
- Firebase Console'da query'nin `limit()` kullandığını kontrol et
- Kodda `orderBy()` ve `limit()` doğru kullanılmış mı kontrol et
- Hot reload yerine uygulamayı yeniden başlat

### 3. Map Cache Çalışmıyor
**Problem**: Her map açılışında yeni map yükleniyor.

**Çözüm:**
- `MapCacheService`'in import edildiğini kontrol et
- `onMapCreated` callback'inde `cacheController` çağrıldığını kontrol et
- Cache'in zaman aşımı ve mesafe kontrollerini kontrol et

### 4. Mesaj Arama Yavaş
**Problem**: Mesaj arama çok yavaş.

**Çözüm:**
- Firestore Console'da query'nin index kullandığını kontrol et
- `searchMessages` fonksiyonunda server-side `orderBy()` ve `limit()` kullanıldığını kontrol et
- Her chat için maksimum 20 sonuç getirildiğini kontrol et

---

## ✅ Test Sonuçları

### Test Tarihi: _______________

#### Görsel Sıkıştırma
- [ ] Profil fotoğrafı: ✅ / ❌ (Boyut: _____ KB → _____ KB, Tasarruf: _____%)
- [ ] Event cover: ✅ / ❌ (Boyut: _____ KB → _____ KB, Tasarruf: _____%)
- [ ] Chat medya: ✅ / ❌ (Boyut: _____ KB → _____ KB, Tasarruf: _____%)

#### Stream Limitleri
- [ ] User events: ✅ / ❌ (Okunan doküman: _____ / 20)
- [ ] Event comments: ✅ / ❌ (Okunan doküman: _____ / 50)
- [ ] Chat messages: ✅ / ❌ (Okunan doküman: _____ / 50)

#### Mesaj Arama
- [ ] Tek chat arama: ✅ / ❌ (Süre: _____ ms)
- [ ] Tüm chat arama: ✅ / ❌ (Süre: _____ ms)

#### Map Cache
- [ ] İlk açılış: ✅ / ❌ (Map load: _____)
- [ ] Cache kullanımı (aynı konum): ✅ / ❌ (Map load: _____)
- [ ] Cache kullanımı (yakın konum): ✅ / ❌ (Map load: _____)
- [ ] Cache sonrası (uzak konum): ✅ / ❌ (Map load: _____)

#### Firebase Maliyet
- [ ] Firestore reads: ✅ / ❌ (Azalma: _____%)
- [ ] Storage: ✅ / ❌ (Azalma: _____%)
- [ ] Map loads: ✅ / ❌ (Azalma: _____%)

---

## 📝 Notlar

- Test sonuçlarını buraya yazın
- Hataları ve çözümlerini buraya ekleyin
- Ek öneriler varsa buraya yazın

