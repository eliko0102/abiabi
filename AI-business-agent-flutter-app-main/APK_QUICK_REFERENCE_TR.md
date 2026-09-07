# 🚀 APK HAZIRLANMASI - SÜRƏTLİ BƏLƏDÇI

## ⚡ 5 ADIM

### 1️⃣ FLUTTERİ YÜKLƏ
```bash
# İndir: https://flutter.dev/docs/get-started/install
flutter --version
```

### 2️⃣ LAYIHƏYƏ GİT
```bash
cd AI-business-agent-flutter-app-main
flutter pub get
```

### 3️⃣ APK İNŞA ET
```bash
flutter build apk --debug
```

**Bitdi mi?** ✅ build/app/outputs/flutter-apk/app-debug.apk

### 4️⃣ TELEFONA YÜKLƏ
```bash
flutter install
```

### 5️⃣ TEST ET
- Açıl: Email + Şifre
- Yazı: Sualını sor
- Alıçıq: Cavab gəlib mi?

---

## 🎯 YOXLAMALAR

```
✅ Flutter yüklü mü?
   flutter --version

✅ Android SDK yüklü mü?
   flutter doctor

✅ Telefon görülüyor mu?
   adb devices

✅ Backend çalışıyor mu?
   cd backend && npm run dev
```

---

## 📊 APK INFO

| Parametr | Dəyər |
|----------|-------|
| Package | com.aiagent.com |
| Versiyon | 1.0.0 (+1) |
| Ölçü | ~20-30 MB |

---

## 🔧 BACKEND BAĞLANTISI

**Telefonda Backend IP'sini Dəyişdir:**

1. Bilgisayar IP'sini bulun:
   ```bash
   ipconfig          # Windows
   hostname -I       # Linux
   ifconfig en0      # Mac
   ```

2. Uygulamada: Settings → Backend URL
   ```
   http://YOUR_IP:5000
   ```

3. Backend'i çalıştırın:
   ```bash
   cd backend
   npm run dev
   ```

---

## ❌ SORULAR

| Sorun | Çözüm |
|-------|-------|
| Flutter yok | https://flutter.dev kuru indir |
| Telefon yok | adb devices - USB Debug aç |
| Backend yok | npm run dev - backend klasöründe |
| AI yanıt yok | .env içinde GEMINI_API_KEY kontrol et |

---

## 📱 TEST

### Kayıt
- Email: test@example.com
- Şifre: password123
- Ad: Test User

### Chat
- "Kafe biznesi nədir?"
- AI: Cəvab vərəcəq ✅

---

## 📚 DETAY

Tam rehbər: **APK_BUILD_GUIDE_TR.md**

---

**Hazır mısınız? Başlayın!** 🚀
