# 🎨 Renk Değiştirme Kılavuzu

## 📍 Tek Yerden Renk Değiştirme

Uygulamanın tüm renklerini **tek bir dosyadan** kolayca değiştirebilirsiniz!

### 🎯 Dosya Konumu
```
lib/core/theme/app_color_config.dart
```

---

## 🚀 Hızlı Başlangıç

### 1. Ana Renkleri Değiştirme

`app_color_config.dart` dosyasını açın ve şu satırları bulun:

```dart
/// Primary Color (Ana Renk)
static const Color primaryColor = Color(0xFF6366F1); // Indigo

/// Secondary Color (İkincil Renk)
static const Color secondaryColor = Color(0xFF8B5CF6); // Purple

/// Tertiary Color (Üçüncül Renk)
static const Color tertiaryColor = Color(0xFF06B6D4); // Cyan
```

Sadece bu renkleri değiştirin! Örnek:

```dart
// Mavi tema için
static const Color primaryColor = Color(0xFF2196F3); // Blue
static const Color secondaryColor = Color(0xFF03A9F4); // Light Blue
static const Color tertiaryColor = Color(0xFF00BCD4); // Cyan

// Yeşil tema için
static const Color primaryColor = Color(0xFF4CAF50); // Green
static const Color secondaryColor = Color(0xFF8BC34A); // Light Green
static const Color tertiaryColor = Color(0xFFCDDC39); // Lime
```

### 2. Gradient Renkleri Değiştirme

Gradient renklerini değiştirmek için:

```dart
/// Primary Gradient (Ana Gradient)
static const List<Color> gradientPrimary = [
  Color(0xFF7F53AC), // Deep purple
  Color(0xFF647DEE), // Blue
  Color(0xFFFFD54F), // Amber
];
```

Örnek:

```dart
// Mavi-yeşil gradient
static const List<Color> gradientPrimary = [
  Color(0xFF2196F3), // Blue
  Color(0xFF00BCD4), // Cyan
  Color(0xFF4CAF50), // Green
];
```

---

## ✅ Değiştirilebilir Renkler

### 🎨 Ana Renkler
- ✅ `primaryColor` - Ana renk (butonlar, vurgular)
- ✅ `secondaryColor` - İkincil renk (aksanlar)
- ✅ `tertiaryColor` - Üçüncül renk (bilgi mesajları)

### 🌈 Gradient'ler
- ✅ `gradientPrimary` - Ana gradient (arka planlar)
- ✅ `gradientPrimaryLight` - Açık ana gradient
- ✅ `gradientSecondary` - İkincil gradient (butonlar)

---

## ❌ Değiştirmeyin (Semantik Renkler)

Bu renkler **sabit kalmalı** çünkü semantik anlamları var:

- ❌ `errorColor` - Hata mesajları (Kırmızı)
- ❌ `successColor` - Başarı mesajları (Yeşil)
- ❌ `warningColor` - Uyarı mesajları (Amber)
- ❌ `infoColor` - Bilgi mesajları (Tertiary ile aynı)

### 🔘 Gri Tonlar (Sabit)

Bu renkler de **sabit kalmalı** çünkü okunabilirlik için önemli:

- ❌ `surfaceColor` - Arka plan rengi
- ❌ `textPrimary` - Ana metin rengi
- ❌ `textSecondary` - İkincil metin rengi
- ❌ `borderColor` - Kenarlık renkleri

---

## 🔄 Otomatik Türetilen Renkler

Ana renkleri değiştirdiğinizde, şu renkler **otomatik** olarak hesaplanır:

- `primaryContainer` - Primary'in açık versiyonu
- `primaryContainerText` - Primary container üzerindeki metin
- `secondaryContainer` - Secondary'nin açık versiyonu
- `secondaryContainerText` - Secondary container üzerindeki metin
- `tertiaryContainer` - Tertiary'nin açık versiyonu
- `tertiaryContainerText` - Tertiary container üzerindeki metin

**Not:** Bu renkler otomatik hesaplandığı için değiştirmenize gerek yok!

---

## 📝 Örnek: Tema Değiştirme

### Mavi Tema

```dart
// app_color_config.dart içinde
static const Color primaryColor = Color(0xFF2196F3); // Blue
static const Color secondaryColor = Color(0xFF03A9F4); // Light Blue
static const Color tertiaryColor = Color(0xFF00BCD4); // Cyan

static const List<Color> gradientPrimary = [
  Color(0xFF2196F3), // Blue
  Color(0xFF00BCD4), // Cyan
  Color(0xFF4CAF50), // Green
];

static const List<Color> gradientSecondary = [
  Color(0xFF2196F3), // Blue
  Color(0xFF03A9F4), // Light Blue
];
```

### Yeşil Tema

```dart
// app_color_config.dart içinde
static const Color primaryColor = Color(0xFF4CAF50); // Green
static const Color secondaryColor = Color(0xFF8BC34A); // Light Green
static const Color tertiaryColor = Color(0xFFCDDC39); // Lime

static const List<Color> gradientPrimary = [
  Color(0xFF4CAF50), // Green
  Color(0xFF8BC34A), // Light Green
  Color(0xFFCDDC39), // Lime
];

static const List<Color> gradientSecondary = [
  Color(0xFF4CAF50), // Green
  Color(0xFF8BC34A), // Light Green
];
```

### Turuncu Tema

```dart
// app_color_config.dart içinde
static const Color primaryColor = Color(0xFFFF9800); // Orange
static const Color secondaryColor = Color(0xFFFF5722); // Deep Orange
static const Color tertiaryColor = Color(0xFFFFC107); // Amber

static const List<Color> gradientPrimary = [
  Color(0xFFFF9800), // Orange
  Color(0xFFFF5722), // Deep Orange
  Color(0xFFFFC107), // Amber
];

static const List<Color> gradientSecondary = [
  Color(0xFFFF9800), // Orange
  Color(0xFFFF5722), // Deep Orange
];
```

---

## 🎨 Renk Seçimi İpuçları

1. **Kontrast:** Primary ve Secondary renkler arasında yeterli kontrast olmalı
2. **Okunabilirlik:** Renkler üzerindeki beyaz metin okunabilir olmalı
3. **Uyum:** Gradient renkleri birbiriyle uyumlu olmalı
4. **Erişilebilirlik:** WCAG standartlarına uygun kontrast oranları kullanın

---

## 🔍 Değişiklikleri Test Etme

1. `app_color_config.dart` dosyasını düzenleyin
2. Hot reload yapın (veya uygulamayı yeniden başlatın)
3. Tüm sayfalarda renklerin güncellendiğini kontrol edin

---

## 📚 Daha Fazla Bilgi

- Detaylı renk paleti için: `RENK_PALETI.md`
- Tema yapılandırması için: `app_theme.dart`

---

**Not:** Renkleri değiştirdikten sonra uygulamayı yeniden başlatmanız gerekebilir (hot reload yeterli olmayabilir).

