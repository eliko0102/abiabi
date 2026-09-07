# 🔐 MongoAuthService İntegrasiya Qalavuzu

## Yaradılan Fayllar

### Backend
✅ `.env` - MongoDB Atlas kredensialları əlavə edildi

### Frontend (Flutter)
```
lib/
├── screens/
│   ├── login_screen.dart ⭐ NEW - Giriş səhifəsi
│   └── signup_screen.dart ⭐ NEW - Qeydiyyat səhifəsi
├── providers/
│   └── auth_provider.dart ⭐ NEW - State management
├── utils/
│   └── error_handler.dart ⭐ NEW - Xəta göstərişi
├── services/
│   └── mongo_auth_service.dart (artıq var)
└── main_with_auth.dart ⭐ NEW - Yeni main.dart nümunəsi
```

## Sürətli İntegrasiya (3 Addım)

### 1️⃣ main.dart-ı Yenilə

Mövcud `lib/main.dart`-ı `lib/main_with_auth.dart`-dan kopyala:

```dart
// lib/main.dart - Yeni versiya
import 'main_with_auth.dart' as auth_main;

void main() => auth_main.main();
```

Yaxud tam əvəz et:

```bash
cp lib/main_with_auth.dart lib/main.dart
```

### 2️⃣ Authentication Axını

#### Sign Up Flow
```
Istifadəçi → SignUpScreen → MongoAuthService.signUp() 
→ Backend /auth/signup → Token + User → Dashboard
```

#### Login Flow
```
Istifadəçi → LoginScreen → MongoAuthService.login() 
→ Backend /auth/login → Token + User → Dashboard
```

### 3️⃣ Flutter Uygulamasını Çalış

```bash
flutter pub get
flutter run
```

## Detaylı İstifadə

### AuthProvider Istifadəsi

```dart
import 'providers/auth_provider.dart';

// Create provider
final authProvider = AuthProvider();

// Sign Up
bool success = await authProvider.signup(
  name: 'Əhməd Hüseynov',
  email: 'ahmad@example.com',
  password: 'password123',
  businessType: 'Restoran',
);

// Login
bool success = await authProvider.login(
  email: 'ahmad@example.com',
  password: 'password123',
);

// Check state
if (authProvider.isAuthenticated) {
  print('Daxil olmuş: ${authProvider.currentUser}');
}

// Get auth headers for API calls
final headers = authProvider.getAuthHeaders();
// Result: {'Authorization': 'Bearer <token>', 'Content-Type': 'application/json'}

// Logout
await authProvider.logout();
```

### Error Handling

```dart
import 'utils/error_handler.dart';

// Show error
ErrorHandler.showError(context, 'Email artıq istifadə olunur');

// Show success
ErrorHandler.showSuccess(context, 'Qeydiyyat uğurlu!');

// Show info
ErrorHandler.showInfo(context, 'Lütfən gözləyin...');

// Show confirm dialog
bool? confirmed = await ErrorHandler.showConfirmDialog(
  context,
  title: 'Çıxış',
  message: 'Tətbiqdən çıxmaq istəyirsinizmi?',
  confirmText: 'Çıx',
  cancelText: 'Ləğv Et',
);
```

### Login Screen

```dart
import 'screens/login_screen.dart';

// Push to login
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const LoginScreen()),
);

// Expected result: Successful login → Dashboard
```

### Sign Up Screen

```dart
import 'screens/signup_screen.dart';

// Push to signup
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const SignUpScreen()),
);

// Expected result: Successful signup → Dashboard
```

## API Integration

### Chat API ilə Token İstifadəsi

```dart
import 'services/ai_service.dart';

// Initialize with token
final aiService = AiService(authToken: authProvider.token);

// Use service
final response = await aiService.generateResponse(
  'Bak şəhərində kafe biznesi açmaq istəyirəm'
);
```

### Business API v2

```dart
import 'services/business_api_service_v2.dart';

final bizService = BusinessApiServiceV2(
  authToken: authProvider.token,
);

// Location analysis
final analysis = await bizService.analyzeLocation(
  city: 'Bakı',
  businessType: 'Restoran',
  address: 'Neftçi Ave 5',
);

// ROI calculation
final roi = await bizService.calculateRoi(
  rent: 2000,
  averageTicket: 50,
  margin: 0.35,
);
```

## Navigation Setup

### Route Configuration

```dart
// lib/config/routes.dart
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';

Map<String, WidgetBuilder> getRoutes() {
  return {
    '/login': (_) => const LoginScreen(),
    '/signup': (_) => const SignUpScreen(),
    '/dashboard': (_) => const DashboardWrapper(),
  };
}
```

### Navigation Examples

```dart
// Go to signup from login
Navigator.pushNamed(context, '/signup');

// Replace with dashboard after login
Navigator.pushReplacementNamed(
  context,
  '/dashboard',
  arguments: {'user': user},
);

// Go back to login on logout
Navigator.pushNamedAndRemoveUntil(
  context,
  '/login',
  (route) => false,
);
```

## Security Best Practices

### 1. Token Storage
```dart
// ✅ RECOMMENDED: Use flutter_secure_storage
// ❌ AVOID: Storing token in plain text

// Current: Token in memory (lost on app restart)
// TODO: Implement persistent storage

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const storage = FlutterSecureStorage();
await storage.write(key: 'auth_token', value: token);
```

### 2. Token Refresh
```dart
// TODO: Implement refresh token logic
// Backend should return: {token, refreshToken, expiresIn}

// Add to .env:
// REFRESH_TOKEN_ENABLED=true
// TOKEN_EXPIRY_TIME=3600  // 1 hour
```

### 3. HTTPS Only
```dart
// Production-da HTTPS istifadə edin
// lib/config/api_config.dart

// Development:
static const backendUrl = 'http://localhost:5000';

// Production:
// static const backendUrl = 'https://api.yourdomain.com';
```

## Debugging

### Test Account
```
Email: test@example.com
Password: password123
```

### Logs
```dart
// Enable debug logging
import 'package:http/http.dart' as http;

// Wrap http client:
class LoggingHttpClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    print('→ ${request.method} ${request.url}');
    return super.send(request).then((response) {
      print('← ${response.statusCode}');
      return response;
    });
  }
}
```

### Common Issues

#### Problem: "Backend connection refused"
```
❌ curl: (7) Failed to connect to localhost port 5000
```
**Solution:**
1. Backend-in çalışdığını yoxla: `npm run dev`
2. MongoDB-in çalışdığını yoxla
3. `.env` MONGODB_URI doğru olduğunu yoxla

#### Problem: "Invalid token"
```
401 Unauthorized
```
**Solution:**
1. Giriş yap və yeni token al
2. Token header-də düzgün göndərilməsi yoxla:
   ```dart
   'Authorization': 'Bearer <token>'  // ✅ Doğru
   'Authorization': '<token>'          // ❌ Səhv
   ```

#### Problem: "Email already exists"
```
400 User already exists with this email
```
**Solution:**
1. Digər email istifadə et
2. Yaxud MongoDB-dən istifadəçini sil

## State Management (Optional)

### Without Provider Package
```dart
// Simple ChangeNotifier
import 'package:flutter/foundation.dart';

class AuthProvider extends ChangeNotifier {
  // Current: Used in main_with_auth.dart
  // No extra dependencies needed
}
```

### With Provider Package (Advanced)
```dart
// Add to pubspec.yaml:
dependencies:
  provider: ^6.0.0

// Usage:
final user = context.watch<AuthProvider>().currentUser;
```

## Sonrakı Addımlar

- [ ] Persistent token storage (flutter_secure_storage)
- [ ] Refresh token implementation
- [ ] Password reset endpoint
- [ ] Two-factor authentication
- [ ] Social login (Google, Apple)
- [ ] User profile update endpoint
- [ ] Device token for push notifications

## Faydalı Linkləri

- [HTTP Package](https://pub.dev/packages/http)
- [Flutter Forms](https://flutter.dev/docs/development/ui/widgets/input)
- [State Management](https://flutter.dev/docs/development/data-and-backend/state-mgmt/intro)
- [Navigation](https://flutter.dev/docs/development/ui/navigation)

---

**Suallarınız olsa**: Backend logs-a bax və Flutter console-a bax 🔍

Backend logs:
```bash
# Terminal-da backend çalışan yerdə:
❌ POST /auth/login 401 Unauthorized
```

Flutter logs:
```bash
flutter logs
# Yaxud VS Code Debug Console
```

Happy coding! 🚀
