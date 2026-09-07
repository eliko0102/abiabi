# Firebase'dən MongoDB-yə Keçiş Qalavuzu

## Xülasə

Bu layihə Firebase autentifikasiyasından **Node.js + MongoDB** əsaslı autentifikasiyaya keçirilmişdir.

## Dəyişikliklər

### Backend
- ❌ Python FastAPI → ✅ Node.js Express
- ❌ Firebase Auth → ✅ MongoDB + JWT
- ✅ Bcryptjs ilə şifrə hashing
- ✅ Bearer token ilə autentifikasiya

### Frontend (Flutter)
- ❌ `firebase_auth_service.dart` → ✅ `mongo_auth_service.dart`
- ✅ Yeni `MongoAuthService` istifadə
- ✅ Autentifikasiya tokenlər API çağırışlarına daxil olunacaq

## Qurulum Mərhələləri

### 1️⃣ Backend Qurulumu

#### 1.1 Dependencies Qurulumu
```bash
cd backend/
npm install
```

#### 1.2 MongoDB Qurulması

**Seçim A: Lokal MongoDB**
```bash
# Ubuntu/Debian
sudo apt-get install mongodb
sudo systemctl start mongod

# macOS
brew tap mongodb/brew
brew install mongodb-community
brew services start mongodb-community

# Docker
docker run -d -p 27017:27017 --name mongodb mongo:latest
```

**Seçim B: MongoDB Atlas (Cloud)**
1. https://www.mongodb.com/cloud/atlas adresində hesab açın
2. Cluster yaratın
3. Bağlantı sətirini (Connection String) kopyalayın
4. `.env` faylında əvəz edin:
```env
MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/ai-business-agent
```

#### 1.3 Environment Dəyişənləri
```bash
cp .env.example .env
```

`.env` faylı doldur:
```env
# MongoDB
MONGODB_URI=mongodb://localhost:27017/ai-business-agent

# Server
PORT=5000
NODE_ENV=development

# JWT
JWT_SECRET=your-super-secret-key-change-this-in-production

# AI Provider
AI_PROVIDER=gemini
GEMINI_API_KEY=your-key
```

#### 1.4 Backend Başlatma
```bash
# Development modu (hot reload ilə)
npm run dev

# Production modu
npm start
```

✅ Serverin 5000 portunda çalışdığını yoxla:
```bash
curl http://localhost:5000/health
```

### 2️⃣ Flutter Qurulumu

#### 2.1 Dependencies Yeniləmə
`pubspec.yaml` faylında `firebase_*` paketlərini sil (əgər lazım deyilsə):
```yaml
# Çıxart:
# firebase_core: ^latest
# firebase_auth: ^latest
```

Yeni Firebase-dən asılı olan dependensies çıxartsa da `http` paketi qal:
```bash
flutter pub get
```

#### 2.2 API Config Yeniləmə
`lib/config/api_config.dart` artıq yenilənmiş:
```dart
static const backendUrl = String.fromEnvironment(
  'BACKEND_URL',
  defaultValue: 'http://127.0.0.1:5000',
);
```

Android-də local API-yə qoşulmaq üçün:
- `http://10.0.2.2:5000` (emulator üçün)
- `http://192.168.x.x:5000` (real cihazda network IP-si)

#### 2.3 Firebase Sıfırlanması

Əgər Firebase hələ də istifadə olunursa (başqa funksiyalar üçün):
1. `android/app/google-services.json` sil
2. `ios/Podfile` Firebase entries sil
3. `lib/main.dart`-da Firebase initialization sil:
```dart
// Sil: Firebase.initializeApp()
```

#### 2.4 Flutter Uygulamasını Çalış
```bash
# Android
flutter run -d android

# iOS
flutter run -d ios

# Web
flutter run -d chrome
```

### 3️⃣ Test Əməliyyatları

#### 3.1 cURL ilə Test Edin

**Sign Up**
```bash
curl -X POST http://localhost:5000/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Əhməd Hüseynov",
    "email": "ahmed@example.com",
    "password": "password123",
    "businessType": "Restoran",
    "phone": "+994511234567"
  }'
```

**Login**
```bash
curl -X POST http://localhost:5000/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "ahmed@example.com",
    "password": "password123"
  }'
```

**Chat (Token ilə)**
```bash
curl -X POST http://localhost:5000/api/chat \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -d '{
    "prompt": "Bak şəhərində kafeteriya biznesi üçün yerdə analiz et"
  }'
```

#### 3.2 Flutter Uygulamasında Test

```dart
final authService = MongoAuthService();

// Qeydiyyat
try {
  final user = await authService.signUp(
    name: 'Əhməd',
    email: 'test@example.com',
    password: 'password123',
    businessType: 'Café',
  );
  print('✅ Qeydiyyat uğurlu: $user');
} catch (e) {
  print('❌ Xəta: $e');
}

// Giriş
try {
  final user = await authService.login(
    email: 'test@example.com',
    password: 'password123',
  );
  print('✅ Giriş uğurlu: $user');
} catch (e) {
  print('❌ Xəta: $e');
}
```

## Fayllar Strukturu

```
backend/
├── server.js                 # Ana Express server
├── package.json             # Node.js dependencies
├── .env.example            # Environment template
├── models/
│   └── User.js             # MongoDB user schema
├── routes/
│   ├── auth.js             # Signup/Login endpoints
│   └── api.js              # Protected API endpoints
├── middleware/
│   └── auth.js             # JWT verification
└── README.md               # Döküman

lib/
├── config/
│   └── api_config.dart     # API konfigurasyonu (yeniləndi)
├── services/
│   ├── mongo_auth_service.dart  # Yeni auth service (MongoDB)
│   ├── ai_service.dart          # Yeniləndi (auth token ilə)
│   └── firebase_auth_service.dart # Eski (siliş üçün)
└── ...
```

## Sorular & Cavablar

### S: Firebase hələ də lazımdırsa?
**C:** `firebase_auth_service.dart` orada qalacaq. Ancaq indi `mongo_auth_service.dart` istifadə edin.

### S: Tokenin müddəti bitərsə nə olacaq?
**C:** Login yenidən edin. JWT token 7 gün ərzində keçərlidir. Sonradan refresh token logic əlavə edilə bilər.

### S: Şifrəni unutdusam?
**C:** Indi password reset funksiyası yoxdur. Sonradan əlavə etmək olar.

### S: Android-də localhost qoşulmadı
**C:** `http://10.0.2.2:5000` istifadə edin emulator-da, real cihazda network IP-sinə bağlayın.

## Security

⚠️ **Üretim üçün:**
1. `.env` faylını **git-ə commit etməyin**
2. `JWT_SECRET` güclü random string istifadə edin
3. HTTPS aktivləşdirin
4. MongoDB parolasını qurğun
5. CORS origin-ini sadəcə domendən icazə verin

## Əlavə Resurslar

- [Express.js Docs](https://expressjs.com)
- [Mongoose Docs](https://mongoosejs.com)
- [JWT Auth](https://jwt.io)
- [Flutter HTTP](https://pub.dev/packages/http)

---

**Suallarınız olsa**: Demir push etmədən əvvəl test edin! 🚀
