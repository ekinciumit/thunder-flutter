# Thunder — Production Yol Haritası

Her adım tamamlandıktan sonra emülatörde test edin. Sorun yoksa bir sonraki adıma geçin.

## Faz 1 — Uygulama stabilitesi (düşük risk)

| Adım | Konu | Test |
|------|------|------|
| **1** | MapView `setState after dispose` düzeltmesi | Harita ↔ diğer sekmeler arası geçiş |
| **2** | Ölü kod temizliği (`main.dart` duplicate RootPage) | Uygulama açılışı, auth, ana sekmeler |
| **3** | Event list hata gösterimi | İnternet kapat / hata simüle |
| **4** | Global error handler (`main.dart`) | Crash olmadan hata yakalama |

## Faz 2 — Backend güvenliği (orta risk, staging test şart)

| Adım | Konu | Test |
|------|------|------|
| **5** | Firestore rules düzeltmeleri | Sohbet, reaksiyon, profil, bildirim |
| **6** | Cloud Functions (join request, broadcast) | Etkinlik oluştur, katılım isteği |
| **7** | Storage rules ownership | Medya yükleme / okuma |

## Faz 3 — Production altyapısı

| Adım | Konu | Test |
|------|------|------|
| **8** | Crashlytics + Analytics | Test crash / event |
| **9** | Android/iOS izinler + manifest | Konum, mikrofon, bildirim |
| **10** | Bundle ID hazırlığı (com.example → gerçek ID) | Release build |

## Faz 4 — Kalite & cila

| Adım | Konu | Test |
|------|------|------|
| **11** | i18n sweep (hardcoded stringler) | TR/EN dil değiştir |
| **12** | 87 failing test düzeltme | `flutter test` |
| **13** | Grup chat eksikleri (üye ekle/çıkar) | Grup oluştur, yönet |
| **14** | Hesap silme akışı | Ayarlar → hesap sil |
| **15** | Ölü route/widget temizliği | MyEventsPage, EventParticipationButton |

---

## Tamamlanan adımlar

- **Adım 1** ✅ MapView `setState after dispose` düzeltmesi
- **Adım 2** ✅ `main.dart` ölü kod temizliği (duplicate RootPage kaldırıldı)
- **Adım 3** ✅ Event list hata gösterimi + `retryEvents()`
- **Adım 4** ✅ Global error handler (`main.dart`)
- **Adım 5** ✅ Firestore rules güvenlik düzeltmeleri (deploy edildi)
- **Adım 6** ✅ Cloud Functions düzeltmeleri (deploy edildi)
- **Adım 7** ✅ Storage rules ownership (deploy edildi)
- **Adım 8** ✅ Crashlytics + Analytics entegrasyonu
- **Adım 9** ✅ Android/iOS izinler + manifest
- **Adım 10** ⏸️ Bundle ID (Play/App Store hesabı açılınca)
- **Adım 12** ✅ Test düzeltmeleri (514/514 geçiyor)
- **Adım 11** ✅ i18n sweep (ana ekranlar, sohbet, etkinlik, ayarlar)
- **Adım 13** ✅ Grup chat üye ekle/çıkar + gruptan ayrıl
- **Adım 14** ✅ Hesap silme akışı (Ayarlar → Hesabı Sil)
- **Adım 15** ✅ Ölü route/widget temizliği (`MyEventsPage`, `EventParticipationButton` kaldırıldı)

## Ek cila (tamamlandı)

- i18n: eksik EN çevirileri, `create_group_chat_page`, ayarlar tema etiketleri, form validator mesajları
- MapView: kümeleme için `onCameraIdle` (setState-after-dispose riski azaltıldı)
- `CompleteProfilePage`: kullanılmayan `onComplete` parametresi kaldırıldı
- Paylaşılan widget'lar `lib/core/widgets/` altına taşındı
- `BUNDLE_ID_HAZIRLIK.md` — Adım 10 kontrol listesi

## Şu an

Yol haritası + cila tamamlandı. **Adım 10** için `BUNDLE_ID_HAZIRLIK.md` — Play/App Store hesabı açılınca uygulanacak.
