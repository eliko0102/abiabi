# 🚀 GitHub Actions Workflows

Layihəniz üçün avtomatik qurma (CI/CD) pipeline-ləri hazırlanıbdır.

---

## 📋 Workflows

### 1️⃣ **build-apk.yml** - Flutter APK Qurma
- **Nə zaman çalışır**: Push və Pull Request
- **Nə edir**:
  - ✅ Flutter yükləyir
  - ✅ Bağımlılıkları yükləyir
  - ✅ Debug APK qurur
  - ✅ Release APK qurur
  - 📥 APK dosyaları yükləyir (30 gün saxlanılır)

**APK'yı Düşür:**
1. GitHub → Actions
2. Build APK workflow'u tıkla
3. Artifactslara get
4. APK'yı download et

---

### 2️⃣ **build-backend.yml** - Node.js Backend Qurma
- **Nə zaman çalışır**: Backend dosyaları dəyişdirildikdə
- **Nə edir**:
  - ✅ Node.js 18 və 20 üzrə test edir
  - ✅ Bağımlılıkları yükləyir
  - ✅ Linter çalışdırır
  - ✅ Testləri çalışdırır
  - ✅ Syntax kontrol edir
  - 📦 Backend packagesi yükləyir

---

### 3️⃣ **ci-cd.yml** - Tam CI/CD Pipeline
- **Nə zaman çalışır**: Hər push
- **Nə edir**:
  - 🧪 **Test**: Backend + Flutter test edir
  - 📱 **Build APK**: İnşa edir
  - 🖥️ **Build Backend**: Node.js qurur
  - 🔍 **Security**: Təhlükəsizlik skanı edir
  - 📊 **Report**: Nəticə bildiriş göstərir

---

## 🎯 Necə İstifadə Etməli?

### Senariy 1: Kod Push Et

```bash
git add .
git commit -m "Yeni xüsusiyyət"
git push origin main
```

**Avtomatik olaraq:**
1. ✅ Testlər çalışır
2. ✅ APK qurulur
3. ✅ Backend paketi hazırlanır
4. 📥 Artifactslara yüklənir

### Senariy 2: APK Download Et

```
GitHub → Actions Tab
  ↓
CI/CD Pipeline tıkla
  ↓
Artifacts
  ↓
"apk-builds" download et
```

### Senariy 3: Release APK Yay

**Versiyon tag-ı yarat:**
```bash
git tag v1.0.0
git push origin v1.0.0
```

**Avtomatik olaraq:**
- Release APK GitHub Release-ə yüklənir
- Bütün istifadəçilər download edə bilər

---

## 📊 Workflow Statusu

GitHub açsanız, hər commit-in yanında status görsəniz:

```
✅ All checks passed      → Hər şey OK
⚠️  Some checks pending   → Hələ çalışıyor
❌ Some checks failed      → Xəta var
```

---

## 🔧 Workflow Dosyaları

| Dosya | Məqsəd |
|-------|--------|
| `.github/workflows/build-apk.yml` | APK qurma |
| `.github/workflows/build-backend.yml` | Backend qurma |
| `.github/workflows/ci-cd.yml` | Tam pipeline |

---

## 📝 Nəticəni Yoxla

### 1. GitHub Actions Tab-ı Aç

```
Layihə → Actions
```

### 2. Workflow Tıkla

```
CI/CD Pipeline
  ↓
Latest Run
```

### 3. Nəticə Gör

```
✅ test                 → Passed
✅ build-apk           → Passed
✅ build-backend       → Passed
✅ security-scan       → Passed
✅ notify              → Passed
```

---

## 💾 Artifacts (Qurulmuş Dosyalar)

Hər workflow sonrasında yüklənir:

### APK Builds
- `app-debug.apk` - Test üçün
- `app-release.apk` - Distribüsyon üçün

### Backend Build
- `server.js`
- `package.json`
- `routes/`
- `models/`
- `middleware/`

---

## 🚨 Workflow Başarısız olarsa?

1. **Actions Tab-ında tıkla**
2. **Xəta olan workflow'u aç**
3. **Red rəngdə olan adımı gör**
4. **Log mesajını oxu**
5. **Xətanı düzəlt**
6. **Push et - tekrar çalışacaq**

---

## 🔑 Environment Variables

Workflow-lara sırlar (API keys, tokens) əlavə etmək:

```
GitHub → Settings → Secrets → Actions
  ↓
New repository secret
  ↓
Adı: GEMINI_API_KEY
Dəyəri: AQ.Ab8RN6JpoOLvPa...
  ↓
Workflow-da istifadə et:
${{ secrets.GEMINI_API_KEY }}
```

---

## 📱 APK Release Staging

**Staging Release Yaratmaq:**

```bash
# Version tag yarat
git tag v1.0.0-beta.1
git push origin v1.0.0-beta.1
```

**Avtomatik olaraq:**
- GitHub Release səhifəsi yaranır
- APK avtomatik yüklənir
- İstifadəçilər download edə bilərlər

---

## 🔐 CI/CD Best Practices

✅ **Edən şeylər:**
- Hər dəyişikliyə test çalışdırır
- Otomatik qurma
- Security scan
- Nəticə bildirişi

❌ **Etməyən şeylər:**
- Sırları log-a yazmır
- Prod-a avtomatik deploy etmir
- İzinsiz release vermən

---

## 📚 Workflow Dil

### Trigger Events
```yaml
on:
  push:        # Hər push-da
  pull_request: # PR-da
  schedule:    # Saat-da
  workflow_dispatch: # Manual
```

### Jobs
```yaml
jobs:
  test:     # Test işi
  build:    # Qurma işi
  deploy:   # Deploy işi
```

### Steps
```yaml
steps:
  - uses: actions/checkout@v3  # Code-u çəkir
  - run: npm install           # Əmr çalışdırır
  - uses: actions/upload-artifact # Dosya yükləyir
```

---

## 🎬 Workflow Diaqram

```
Code Push
  ↓
CI/CD Trigger
  ↓
┌─────────────┬──────────────┬───────────────┐
│             │              │               │
v             v              v               v
Test      Build APK     Build Backend   Security Scan
✅          ✅            ✅              ✅
  ↓          ↓             ↓              ↓
  └──────────┴─────────────┴──────────────┘
              ↓
         Notify
         Report ✅
         ↓
    Download APK
    from Artifacts
```

---

## 🚀 Status Badge (Optional)

README-nə əlavə edəcəksən:

```markdown
![Build APK](https://github.com/camaloveliko-oss/myapp/workflows/Build%20APK/badge.svg)
![CI/CD Pipeline](https://github.com/camaloveliko-oss/myapp/workflows/CI%2FCD%20Pipeline/badge.svg)
```

---

## ✨ Özü

**Artıq:**
- ✅ Her push otomatik test
- ✅ APK avtomatik qurulur
- ✅ Download etmə hazır
- ✅ GitHub Release-ə yay
- ✅ Production-a hazır

**Lazım deyil:**
- ❌ Manual `flutter build`
- ❌ Manual `npm test`
- ❌ Manual `adb install`

---

## 🎉 Bitdi!

İndi:
1. Push et
2. Workflows otomatik çalışacaq
3. APK download et
4. Telefonunuza yüklə

**Hər şey avtomatik!** 🚀

---

**Setup Date**: 2026-08-18
**Status**: ✅ Ready
**Workflows**: 3 active
