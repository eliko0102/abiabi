# 🚀 Sürətli Başlanğıc - Node.js + MongoDB Backend

## 5 Dəqiqədə Hazırlamaq

### Addım 1: Backend Qur (2 dəq)
```bash
cd backend/
npm install
cp .env.example .env
npm run dev
```
✅ Terminal-da `🚀 Server is running on port 5000` görəcəksiniz

### Addım 2: MongoDB (Təklif: Docker) 
```bash
docker run -d -p 27017:27017 --name mongodb mongo:latest
```

Yaxud [MongoDB Atlas](https://www.mongodb.com/cloud/atlas)-a qeydiyyat edin, Connection String `.env` əvəz edin.

### Addım 3: Test
```bash
# Terminal açın, test edin:
curl http://localhost:5000/health
# {"status":"ok","message":"Server is running"}
```

## Kod Nümunələri

### Flutter-də Qeydiyyat
```dart
import 'services/mongo_auth_service.dart';

final authService = MongoAuthService();

// Qeydiyyat
final user = await authService.signUp(
  name: 'Əhməd Hüseynov',
  email: 'ahmed@example.com',
  password: 'secure123',
  businessType: 'Café',
);
print('✅ Qeydiyyat ok: ${user['email']}');

// Token almaq
String token = authService.token; // Sonraki çağırışlar üçün
```

### Flutter-də Giriş
```dart
final user = await authService.login(
  email: 'ahmed@example.com',
  password: 'secure123',
);
print('✅ Daxil oldunuz: ${user['name']}');
```

### AI Söhbəti
```dart
import 'services/ai_service.dart';

final aiService = AiService(authToken: authService.token);
final response = await aiService.generateResponse(
  'Bak şəhərində Kafe biznesi açmaq istəyirəm',
);
print(response);
```

### Biznes Analizi
```dart
import 'services/business_api_service_v2.dart';

final bizService = BusinessApiServiceV2(authToken: authService.token);

// Konum analizi
final analysis = await bizService.analyzeLocation(
  city: 'Bakı',
  businessType: 'Restoran',
  address: 'Neftçi Prospekti 5',
);

// ROI hesablaması
final roi = await bizService.calculateRoi(
  rent: 2000, // AZN/ay
  averageTicket: 50, // AZN
  margin: 0.35, // 35% margin
);
print('📊 Aylıq Kar: ${roi['monthlyProfit']}');
```

## API Endpoints Xülasə

| Endpoint | Method | Auth | Məqsəd |
|----------|--------|------|--------|
| `/auth/signup` | POST | ❌ | Yeni istifadəçi qeydiyyat |
| `/auth/login` | POST | ❌ | Giriş, token al |
| `/api/chat` | POST | ✅ | AI söhbəti |
| `/api/location-analysis` | POST | ✅ | Məkan analizi |
| `/api/roi` | POST | ✅ | ROI hesablaması |

## Debugging Tipsləri

### "MongoDB connection error"
✅ **Həll**: MongoDB çalışmadığını yoxla
```bash
# Başla:
sudo systemctl start mongod
# və ya Docker:
docker start mongodb
```

### "Invalid token" (401 Xətası)
✅ **Həll**: Giriş yap, yeni token al
```dart
final user = await authService.login(
  email: 'yourEmail@example.com', 
  password: 'password'
);
// Token avtomatik saxlanacaq
```

### Android-də "Connection refused"
✅ **Həll**: API config dəyişdir
```dart
// lib/config/api_config.dart
// Emulator:
static const backendUrl = 'http://10.0.2.2:5000';
// Cihaz:
static const backendUrl = 'http://192.168.x.x:5000'; // Your machine IP
```

## Faylları Yoxla

Bunlar yeni yaradılıb:
- ✅ `backend/server.js` - Express server
- ✅ `backend/models/User.js` - User schema
- ✅ `backend/routes/auth.js` - Login/Signup
- ✅ `backend/routes/api.js` - Protected endpoints
- ✅ `lib/services/mongo_auth_service.dart` - Auth service
- ✅ `lib/services/business_api_service_v2.dart` - Business API
- ✅ `lib/services/ai_service.dart` - AI service (yeniləndi)

## Sonrakı Addımlar

- [ ] AI provider konfigurasyonu (Gemini/OpenAI)
- [ ] Refresh token logic
- [ ] Password reset endpoint
- [ ] User profil yenilənməsi
- [ ] Rate limiting
- [ ] Error logging

---

**Heç nə işləmirsə?** Backend logs-a bax:
```bash
# Terminal-da backend çalışan yerdə görsəniz:
❌ Error: MongoDB connection error
📝 POST /auth/login 400
```

Happy coding! 🎉
