# 🔄 Git - Geri Dönme Rehberi

## 📋 Mevcut Commit Geçmişi

```
* 2949b96 feat: Faz 4.1 - SignUp başarılı mesajı eklendi ve test edildi  ← EN SON (şu an buradayız)
* 6ad8528 fix: Faz 4 - Fallback mekanizması ile güvenli entegrasyon
* 94820d5 feat: Faz 4 - Clean Architecture tam entegrasyon
* 1998e0c feat: Integrate all remaining Use Cases into AuthViewModel
* 1809066 backup: Before integrating remaining Use Cases - safe point  ← DÜN (örnek)
```

---

## 🔙 Geri Dönme Yöntemleri

### 1. Son Commit'i Geri Al (Değişiklikleri Tut)

**Ne yapar:** Son commit'i geri alır ama değişiklikleri dosyalarda tutar (staged olarak)

```bash
git reset --soft HEAD~1
```

**Ne olur:**
- Son commit silinir
- Tüm değişiklikler staged (hazır) durumda kalır
- Dosyalar değişmeden kalır
- Tekrar commit edebilirsin

**Kullanım:** "Commit mesajını değiştirmek istiyorum" durumunda

---

### 2. Son Commit'i Geri Al (Değişiklikleri Unstage Et)

**Ne yapar:** Son commit'i geri alır, değişiklikleri unstaged yapar

```bash
git reset HEAD~1
# veya
git reset --mixed HEAD~1
```

**Ne olur:**
- Son commit silinir
- Değişiklikler unstaged (hazır değil) durumda kalır
- Dosyalar değişmeden kalır
- `git add` yapıp tekrar commit edebilirsin

**Kullanım:** "Commit'i geri almak ama değişiklikleri gözden geçirmek istiyorum" durumunda

---

### 3. Son Commit'i Geri Al (Değişiklikleri Sil) ⚠️ DİKKATLİ!

**Ne yapar:** Son commit'i geri alır ve değişiklikleri tamamen siler

```bash
git reset --hard HEAD~1
```

**Ne olur:**
- Son commit silinir
- Tüm değişiklikler silinir
- Dosyalar önceki commit'teki haline döner
- **GERİ ALINAMAZ!** (eğer push yapmadıysan)

**Kullanım:** "Son commit'i tamamen silmek istiyorum" durumunda

**⚠️ UYARI:** Bu komut değişiklikleri kalıcı olarak siler!

---

### 4. Belirli Bir Commit'e Dön (Geçici)

**Ne yapar:** Belirli bir commit'e geçici olarak döner (detached HEAD)

```bash
# Commit hash'ini kullan
git checkout 1809066

# veya commit mesajından
git checkout backup:Before
```

**Ne olur:**
- O commit'teki kod görünür
- Değişiklik yaparsan yeni branch oluşturman gerekir
- `git checkout refactor/clean-architecture` ile geri dönebilirsin

**Kullanım:** "Dünkü kodu görmek istiyorum" durumunda

---

### 5. Belirli Bir Commit'e Dön (Kalıcı) ⚠️ DİKKATLİ!

**Ne yapar:** Belirli bir commit'e kalıcı olarak döner

```bash
# Commit hash'ini kullan
git reset --hard 1809066
```

**Ne olur:**
- O commit'teki kod görünür
- O commit'ten sonraki tüm commit'ler silinir
- **GERİ ALINAMAZ!** (eğer push yapmadıysan)

**Kullanım:** "Dünkü koda kalıcı olarak dönmek istiyorum" durumunda

**⚠️ UYARI:** Bu komut sonraki commit'leri kalıcı olarak siler!

---

### 6. Yeni Commit ile Geri Al (En Güvenli) ✅ ÖNERİLEN

**Ne yapar:** Yeni bir commit oluşturarak son commit'i geri alır

```bash
git revert HEAD
```

**Ne olur:**
- Son commit'teki değişiklikleri geri alan yeni bir commit oluşturur
- Commit geçmişi korunur
- Güvenli ve geri alınabilir
- Push yaptıysan bile sorun yok

**Kullanım:** "Son commit'i geri almak ama geçmişi korumak istiyorum" durumunda

---

## 🎯 Senaryolar

### Senaryo 1: "Dünkü koda dönmek istiyorum"

**Güvenli yöntem:**
```bash
# 1. Önce commit hash'ini bul
git log --oneline

# 2. O commit'e geçici olarak dön
git checkout 1809066

# 3. Kodu kontrol et, test et

# 4. Geri dön
git checkout refactor/clean-architecture
```

**Kalıcı yöntem (DİKKATLİ!):**
```bash
# 1. Önce commit hash'ini bul
git log --oneline

# 2. O commit'e kalıcı olarak dön
git reset --hard 1809066

# ⚠️ Son commit'ler silinir!
```

---

### Senaryo 2: "Son commit'i geri almak istiyorum ama değişiklikleri tutmak istiyorum"

```bash
git reset --soft HEAD~1
# Değişiklikler staged olarak kalır
# Tekrar commit edebilirsin
```

---

### Senaryo 3: "Son commit'i tamamen silmek istiyorum"

```bash
git reset --hard HEAD~1
# ⚠️ Değişiklikler kalıcı olarak silinir!
```

---

## 🔍 Yardımcı Komutlar

### Commit geçmişini göster:
```bash
git log --oneline --graph -10
```

### Belirli bir commit'i göster:
```bash
git show 1809066
```

### Değişiklikleri göster:
```bash
git diff HEAD~1  # Son commit ile önceki commit arasındaki fark
```

### Kaybolan commit'leri bul:
```bash
git reflog  # Tüm commit geçmişini gösterir (silinenler dahil)
```

---

## 💡 Öneriler

1. **Geri dönmeden önce:** `git log` ile commit geçmişini kontrol et
2. **Güvenli yöntem:** `git revert` kullan (geçmişi korur)
3. **Test için:** `git checkout` kullan (geçici)
4. **Kalıcı silme:** `git reset --hard` kullan ama dikkatli!
5. **Kaybolan commit'ler:** `git reflog` ile bulabilirsin

---

## ⚠️ Önemli Notlar

- **Push yapmadıysan:** `git reset --hard` güvenli (local'de)
- **Push yaptıysan:** `git revert` kullan (remote'u bozmaz)
- **Kaybolan commit'ler:** `git reflog` ile bulabilirsin
- **Yedek:** Önemli değişikliklerden önce branch oluştur

---

## 🎯 Hızlı Referans

| İşlem | Komut | Güvenlik |
|-------|-------|----------|
| Son commit'i geri al (değişiklikleri tut) | `git reset --soft HEAD~1` | ✅ Güvenli |
| Son commit'i geri al (unstaged) | `git reset HEAD~1` | ✅ Güvenli |
| Son commit'i geri al (sil) | `git reset --hard HEAD~1` | ⚠️ Dikkatli |
| Belirli commit'e dön (geçici) | `git checkout <hash>` | ✅ Güvenli |
| Belirli commit'e dön (kalıcı) | `git reset --hard <hash>` | ⚠️ Dikkatli |
| Yeni commit ile geri al | `git revert HEAD` | ✅ En Güvenli |

