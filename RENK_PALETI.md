# 🎨 Thunder Uygulaması - Renk Paleti

**Oluşturulma:** 2025-01-21  
**Son Güncelleme:** 2025-01-21

---

## 📋 İçindekiler

1. [Ana Renkler (ColorScheme)](#ana-renkler-colorscheme)
2. [Gradient Renkler](#gradient-renkler)
3. [Alpha Değerleri](#alpha-değerleri)
4. [Component Renkleri](#component-renkleri)
5. [Semantik Renkler](#semantik-renkler)

---

## 🎯 Ana Renkler (ColorScheme)

### Primary (Ana Renk)
- **Primary:** `#6366F1` (Indigo) - Ana butonlar, vurgular
- **On Primary:** `#FFFFFF` (Beyaz) - Primary üzerindeki metin
- **Primary Container:** `#E0E7FF` (Açık Indigo) - Primary arka plan
- **On Primary Container:** `#1E1B93` (Koyu Indigo) - Primary container üzerindeki metin

### Secondary (İkincil Renk)
- **Secondary:** `#8B5CF6` (Mor) - İkincil butonlar, aksanlar
- **On Secondary:** `#FFFFFF` (Beyaz) - Secondary üzerindeki metin
- **Secondary Container:** `#F3E8FF` (Açık Mor) - Secondary arka plan
- **On Secondary Container:** `#4C1D95` (Koyu Mor) - Secondary container üzerindeki metin

### Tertiary (Üçüncül Renk)
- **Tertiary:** `#06B6D4` (Cyan) - Üçüncül vurgular
- **On Tertiary:** `#FFFFFF` (Beyaz) - Tertiary üzerindeki metin
- **Tertiary Container:** `#CCFBF1` (Açık Cyan) - Tertiary arka plan
- **On Tertiary Container:** `#0F766E` (Koyu Cyan) - Tertiary container üzerindeki metin

### Error (Hata Renkleri)
- **Error:** `#DC2626` (Kırmızı) - Hata mesajları, validasyon
- **On Error:** `#FFFFFF` (Beyaz) - Error üzerindeki metin
- **Error Container:** `#FEE2E2` (Açık Kırmızı) - Error arka plan
- **On Error Container:** `#991B1B` (Koyu Kırmızı) - Error container üzerindeki metin

### Surface (Yüzey Renkleri)
- **Surface:** `#FFFBFE` (Neredeyse Beyaz) - Ana arka plan
- **On Surface:** `#1C1B1F` (Koyu Gri) - Ana metin rengi
- **Surface Container Highest:** `#F3F4F6` (Açık Gri) - Yüksek yüzeyler
- **On Surface Variant:** `#49454F` (Orta Gri) - İkincil metin

### Outline (Kenarlık Renkleri)
- **Outline:** `#79747E` (Orta Gri) - Normal kenarlıklar
- **Outline Variant:** `#CAC4D0` (Açık Gri) - Hafif kenarlıklar

### Diğer
- **Shadow:** `#000000` (Siyah) - Gölgeler
- **Scrim:** `#000000` (Siyah) - Overlay arka planları
- **Inverse Surface:** `#313033` (Koyu Gri) - Ters yüzey
- **On Inverse Surface:** `#F4EFF4` (Açık Gri) - Ters yüzey üzerindeki metin
- **Inverse Primary:** `#C5C0FF` (Açık Indigo) - Ters primary
- **Surface Tint:** `#6366F1` (Indigo) - Yüzey tonu

---

## 🌈 Gradient Renkler

### Primary Gradient
```dart
AppTheme.gradientPrimary
```
- `#7F53AC` (Deep Purple) → `#647DEE` (Blue) → `#FFD54F` (Amber)
- **Kullanım:** Ana sayfa arka planları, büyük card'lar

### Primary Light Gradient
```dart
AppTheme.gradientPrimaryLight
```
- `#E0E7FF` (Light Indigo) → `#F3E8FF` (Light Purple)
- **Kullanım:** Hafif arka planlar, input alanları

### Secondary Gradient
```dart
AppTheme.gradientSecondary
```
- `#6366F1` (Indigo) → `#8B5CF6` (Purple)
- **Kullanım:** Butonlar, vurgular, navigation

### Success Gradient
```dart
AppTheme.gradientSuccess
```
- `#10B981` (Green) → `#34D399` (Light Green)
- **Kullanım:** Başarı mesajları, onay durumları

### Error Gradient
```dart
AppTheme.gradientError
```
- `#DC2626` (Red) → `#EF4444` (Light Red)
- **Kullanım:** Hata mesajları, uyarılar

---

## 🔍 Alpha Değerleri

Alpha değerleri şeffaflık için kullanılır (0-255 arası):

| Sabit | Değer | Kullanım |
|-------|-------|----------|
| `alphaVeryLight` | 10 | Çok açık arka planlar |
| `alphaLight` | 15 | Açık arka planlar |
| `alphaMediumLight` | 20 | Orta-açık arka planlar |
| `alphaMedium` | 25 | Orta şeffaflık |
| `alphaMediumDark` | 30 | Orta-koyu şeffaflık |
| `alphaDark` | 40 | Koyu şeffaflık |
| `alphaDarker` | 60 | Daha koyu şeffaflık |
| `alphaVeryDark` | 100 | Çok koyu şeffaflık |
| `alphaAlmostOpaque` | 120 | Neredeyse opak |

**Kullanım Örneği:**
```dart
Colors.white.withAlpha(AppTheme.alphaMedium)
// veya
AppTheme.gradientWithAlpha(AppTheme.gradientPrimary, AppTheme.alphaLight)
```

---

## 🧩 Component Renkleri

### Scaffold (Ana Yapı)
- **Background:** `#FFFBFE` (Surface rengi)

### AppBar
- **Background:** `Colors.transparent` (Şeffaf)
- **Foreground:** `#1C1B1F` (On Surface)

### Card
- **Background:** `Colors.white` (Beyaz)
- **Border Radius:** 16px

### Input Fields (TextFormField)
- **Fill Color:** `#F3F4F6` (Surface Container Highest)
- **Border (Normal):** `#E5E7EB` (Açık Gri)
- **Border (Focused):** `#6366F1` (Primary) - 2px kalınlık
- **Border (Error):** `#DC2626` (Error)
- **Border Radius:** 12px

### Buttons
- **Elevated Button:** Primary rengi kullanır
- **Outlined Button:** Primary rengi kullanır
- **Border Radius:** 12px
- **Padding:** 24px horizontal, 12px vertical

---

## 🎨 Semantik Renkler

### Başarı (Success)
- **Ana Renk:** `#10B981` (Green)
- **Açık Renk:** `#34D399` (Light Green)
- **Kullanım:** Başarı mesajları, onay durumları

### Uyarı (Warning)
- **Renk:** `Colors.amber` (Amber)
- **Kullanım:** Uyarı mesajları, dikkat gerektiren durumlar

### Hata (Error)
- **Ana Renk:** `#DC2626` (Red)
- **Açık Renk:** `#EF4444` (Light Red)
- **Kullanım:** Hata mesajları, validasyon hataları

### Bilgi (Info)
- **Renk:** `#06B6D4` (Cyan - Tertiary)
- **Kullanım:** Bilgilendirme mesajları

---

## 📐 Shadow (Gölge) Renkleri

### Soft Shadow
```dart
AppTheme.shadowSoft()
```
- **Color:** `Colors.black.withAlpha(100)` (alphaVeryDark)
- **Blur:** 4.0
- **Offset:** (0, 2)
- **Kullanım:** Küçük card'lar, hafif yükseltmeler

### Medium Shadow
```dart
AppTheme.shadowMedium()
```
- **Color:** `Colors.black.withAlpha(60)` (alphaDarker)
- **Blur:** 12.0
- **Offset:** (0, 4)
- **Kullanım:** Orta boy card'lar, butonlar

### Large Shadow
```dart
AppTheme.shadowLarge()
```
- **Color:** `Colors.black.withAlpha(40)` (alphaDark)
- **Blur:** 24.0
- **Offset:** (0, 8)
- **Kullanım:** Büyük card'lar, modal'lar

---

## 🎯 Kullanım Örnekleri

### Gradient Kullanımı
```dart
// Gradient container
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: AppTheme.gradientPrimary,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
)

// Alpha ile gradient
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: AppTheme.gradientWithAlpha(
        AppTheme.gradientSecondary,
        AppTheme.alphaMedium,
      ),
    ),
  ),
)
```

### Renk Kullanımı
```dart
// Theme'den renk alma
Theme.of(context).colorScheme.primary
Theme.of(context).colorScheme.secondary
Theme.of(context).colorScheme.error

// Alpha ile renk
Colors.white.withAlpha(AppTheme.alphaMedium)
theme.colorScheme.primary.withAlpha(AppTheme.alphaLight)
```

### Shadow Kullanımı
```dart
Container(
  decoration: BoxDecoration(
    boxShadow: [
      AppTheme.shadowMedium(),
      AppTheme.shadowSoft(color: Colors.purple.withAlpha(20)),
    ],
  ),
)
```

---

## 📝 Notlar

1. **Tutarlılık:** Tüm renkler `AppTheme` sınıfından alınmalı
2. **Hard-coded Renkler:** Mümkün olduğunca `Color(0xFF...)` yerine `AppTheme` constants kullanılmalı
3. **Semantik Renkler:** Başarı, hata, uyarı için semantik renkler kullanılmalı
4. **Alpha Değerleri:** Şeffaflık için `AppTheme.alpha*` constants kullanılmalı
5. **Gradient'ler:** Arka planlar için gradient'ler kullanılabilir, ancak tutarlı olmalı

---

## 🔄 Gelecek Güncellemeler

- [ ] Dark mode renk paleti eklenecek
- [ ] Daha fazla gradient kombinasyonu
- [ ] Animasyon renkleri
- [ ] Kategori bazlı renkler (Müzik, Spor, vb.)

---

**Dosya Konumu:** `lib/core/theme/app_theme.dart`

