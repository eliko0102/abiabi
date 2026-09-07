# 📱 APK İnşa ve Telefonda Test Etme Rehberi

## 🎯 Amaç
AI Business Agent uygulamasını APK olarak inşa edip Android telefonunuza yükleyip test etmek.

---

## 📋 Ön Koşullar

### Yazılım Kurulumu
1. **Flutter SDK 3.12+**
   ```bash
   # İndir: https://flutter.dev/docs/get-started/install
   flutter --version
   ```

2. **Android Studio + SDK**
   ```bash
   # İndir: https://developer.android.com/studio
   flutter doctor -v
   ```

3. **Java Development Kit (JDK 11+)**
   ```bash
   java -version
   ```

### Telefon Ayarları (Android)

1. **Developer Mode Etkinleştir**
   - Settings → About phone
   - Build Number'a 7 kez tıkla
   - İleti: "You are now a developer!" ✅

2. **USB Debugging Aç**
   - Settings → Developer options
   - USB Debugging → ON

3. **Bilinmeyen Kaynaklar (Unknown Sources)**
   - Settings → Security (veya Privacy)
   - Unknown sources → Allow

---

## 🚀 Adım Adım İnşa Süreci

### 1️⃣ Proje Hazırlığı

```bash
cd AI-business-agent-flutter-app-main

# Flutter kontrol et
flutter doctor

# Bağımlılıkları yükle
flutter pub get
```

**Beklenen Sonuç:**
```
✓ Flutter (Channel stable, 3.47.0)
✓ Android SDK version 33 (or higher)
✓ Android Studio version 2023.1.1
✓ VS Code
```

### 2️⃣ APK İnşa Et

**Seçenek A: Hızlı Test İçin (Debug)**
```bash
flutter build apk --debug
```

**Seçenek B: Distribüsyon İçin (Release)**
```bash
flutter build apk --release
```

**Seçenek C: Optimizlenmiş (Split APKs)**
```bash
flutter build apk --split-per-abi --release
```

**İnşa Süresi:** 3-5 dakika (ilki daha uzun)

### 3️⃣ APK Konumu

```
✅ Debug APK:
   build/app/outputs/flutter-apk/app-debug.apk

✅ Release APK:
   build/app/outputs/flutter-apk/app-release.apk
```

---

## 📱 Telefona Yükleme

### Seçenek 1: Direkt USB ile (Önerilen)

```bash
# Telefonu USB ile bilgisayara bağla
# USB Debugging'in açık olduğundan emin ol

# Yükle
flutter install

# Ekranda izle
```

### Seçenek 2: APK Dosyasını Transfer Et

```bash
# USB ile transfer (Windows/Mac)
# build/app/outputs/flutter-apk/app-debug.apk
# → Telefona drag & drop
# → Telefonda: app-debug.apk'ye tıkla
# → "Install" seç

# veya ADB ile (Command Line)
adb install build/app/outputs/flutter-apk/app-debug.apk
```

### Seçenek 3: QR Kod ile

```bash
# Local IP'nizi bulun
ipconfig getifaddr en0  # macOS
hostname -I            # Linux
ipconfig               # Windows

# Basit HTTP server başlat
python3 -m http.server 8000

# Telefon browser'ında: http://YOUR_IP:8000
# → app-debug.apk'yi indir
# → Yükle
```

---

## ✅ Telefonda Test Etme

### 🎯 Test Senaryosu 1: Kayıt (Sign Up)

1. Uygulamayı aç
2. **"Kayıt Ol"** düğmesine tıkla
3. Bilgileri gir:
   - **Ad**: "Test Kullanıcı"
   - **Email**: "test@example.com"
   - **Şifre**: "password123"
   - **İşletme Tipi**: "Kafe" (opsiyonel)
   - **Telefon**: "+994511234567" (opsiyonel)
4. **"Kayıt Ol"** tıkla
5. ✅ Başarılı ise dashboard'a git

### 🎯 Test Senaryosu 2: Giriş (Login)

1. **"Giriş Yap"** sayfasında:
   - **Email**: "test@example.com"
   - **Şifre**: "password123"
2. **"Giriş Yap"** tıkla
3. ✅ Dashboard görülmeliydi

### 🎯 Test Senaryosu 3: AI Chat

1. Dashboard'da **Chat** sekmesine git
2. Soruyu yaz: "Bakı şəhərində kafe biznesi açmaq üçün nədir lazım?"
3. **Gönder** tıkla
4. ⏳ Biraz bekle (Gemini API'ye çağrı yapılıyor)
5. ✅ AI yanıtı görülmeliydi

### 🎯 Test Senaryosu 4: İşletme Analizi

1. **"Analiz"** sekmesine git
2. Lokasyon bilgileri gir
3. ✅ Analiz sonuçlarını gör

---

## 🔧 Sorun Giderme

### ❌ "Flutter bulunamadı"
```bash
# Flutter PATH'e ekle
export PATH="$PATH:$HOME/flutter/bin"

# Kontrolü doğrula
flutter doctor
```

### ❌ "Android SDK bulunamadı"
```bash
# Android Studio'yu aç
# Tools → SDK Manager
# Android 30+ seç ve indir

# veya manual olarak
flutter config --android-sdk-path=/path/to/android/sdk
```

### ❌ "Telefon görülmüyor"
```bash
# Kontrol et
adb devices

# Eğer "unauthorized" ise:
# → Telefonda USB Debug izni seç
# → USB bağlantı modunu "File Transfer" yap
# → Tekrar dene
```

### ❌ "Bağlantı başarısız" (APK çalışıyor ama backend'e bağlanamıyor)

**Backend'i çalıştırmalısınız:**
```bash
cd backend/
npm install
npm run dev

# Beklenen çıkış:
# ✅ MongoDB connected
# 🚀 Server running on port 5000
```

**Telefon ayarları:**
- Telefon ile bilgisayar **aynı WiFi ağında** olmalı
- Bilgisayar IP'sini öğren: `ipconfig` (Windows) veya `ifconfig` (Linux/Mac)
- Uygulamada: Settings → Backend URL → `http://YOUR_IP:5000`

### ❌ "AI Yanıt Gelmiyor"
```bash
# Backend .env dosyasını kontrol et
# backend/.env dosyasında GEMINI_API_KEY olmalı
GEMINI_API_KEY=your_api_key_here

# Backend yeniden başlat
npm run dev
```

### ❌ "APK İnşası Başarısız"
```bash
# Clean build yap
flutter clean
flutter pub get
flutter build apk --debug

# Hala başarısız ise
flutter doctor -v
# Eksik olan şeyler kur
```

---

## 📊 Başarı Kontrol Listesi

```
Kurulum
□ Flutter yüklü (3.12+)
□ Android SDK yüklü
□ Java/JDK yüklü
□ flutter doctor yeşil ✓

APK İnşası
□ flutter pub get başarılı
□ flutter build apk tamamlandı
□ APK dosyası var (10-50 MB)

Telefon Hazırlığı
□ Developer mode açık
□ USB Debugging açık
□ Telefon tanındı (adb devices)

Yükleme
□ APK telefona yüklendi
□ Uygulama simgesi görülüyor
□ Uygulama açılabiliyor

Test
□ Kayıt yapılabiliyor
□ Giriş yapılabiliyor
□ Chat çalışıyor (AI yanıt geliyor)
□ Backend bağlantısı OK
```

---

## 🚀 Hızlı Başlangıç Komutları

```bash
# 1. Proje klasörüne git
cd AI-business-agent-flutter-app-main

# 2. Tüm kontroller (kırmızı olanları kur)
flutter doctor

# 3. Bağımlılıkları yükle
flutter pub get

# 4. APK inşa et
flutter build apk --debug

# 5. Telefona yükle
flutter install

# 6. Logları izle
flutter logs
```

---

## 📞 Canlı Loglar

Yüklemenin ardından logları canlı olarak görmek için:

```bash
flutter logs
```

Beklenen loglar:
```
I/FlutterActivity(12345): onCreate
I/FlutterActivity(12345): Binding native libs
I/flutter (12345): App started
I/flutter (12345): Attempting login...
I/flutter (12345): Login successful
I/flutter (12345): Chat initialized
```

---

## 🎬 Demo Videosu Oluşturma

Uygulamayı göstermek için:

```bash
# Ekran kaydı başlat
adb shell screenrecord /sdcard/demo.mp4

# Uygulamayı test et (1-2 dakika)
# Kayıt bitir: Ctrl+C

# Bilgisayara indir
adb pull /sdcard/demo.mp4 demo.mp4
```

---

## 📦 APK Özellikleri

| Özellik | Değer |
|---------|-------|
| **Package ID** | com.aiagent.com |
| **Versiyon** | 1.0.0 |
| **Build** | 1 |
| **Min SDK** | 21+ |
| **Target SDK** | 34+ |
| **Boyut** | ~20-30 MB |
| **Hedef** | Android 5.0+ |

---

## 🔒 Güvenlik Notları

1. **Debug APK**
   - Geliştirme için
   - Debugging aktif
   - Daha yavaş

2. **Release APK**
   - Distribüsyon için
   - Debugging kapalı
   - Daha hızlı
   - Daha küçük

Production'a gitmeden önce Release APK kullanın!

---

## 📚 Ek Kaynaklar

- Flutter Docs: https://flutter.dev/docs
- Android Docs: https://developer.android.com/docs
- APK Publishing: https://flutter.dev/docs/deployment/android

---

## 🎉 Başarılı!

APK hazırlandı ve telefonunuzda çalışıyor olmalı! 🚀

Sorular için backend loglarını kontrol etmeyi unutmayın:
```bash
cd backend
npm run dev
```

---

**Tarih**: 2026-08-18
**Versiyon**: 1.0.0
**Durum**: Ready for Testing ✅
