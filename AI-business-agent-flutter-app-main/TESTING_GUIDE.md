# 🧪 MongoDB Authentication Testing Guide

## Backend Test

### 1. Health Check

```bash
curl http://localhost:5000/health
```

Expected Response:
```json
{
  "status": "ok",
  "message": "Server is running"
}
```

---

### 2. User Sign Up

```bash
curl -X POST http://localhost:5000/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Əhməd Hüseynov",
    "email": "ahmad@example.com",
    "password": "password123",
    "businessType": "Restoran",
    "phone": "+994511234567"
  }'
```

Expected Response (201):
```json
{
  "success": true,
  "message": "User registered successfully",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "64f7a3c8e4d5f2a1b9c0d1e2",
    "name": "Əhməd Hüseynov",
    "email": "ahmad@example.com",
    "businessType": "Restoran",
    "phone": "+994511234567"
  }
}
```

**Save the token for next requests!** 🔑

---

### 3. User Login

```bash
curl -X POST http://localhost:5000/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "ahmad@example.com",
    "password": "password123"
  }'
```

Expected Response (200):
```json
{
  "success": true,
  "message": "Login successful",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "64f7a3c8e4d5f2a1b9c0d1e2",
    "name": "Əhməd Hüseynov",
    "email": "ahmad@example.com",
    "businessType": "Restoran",
    "phone": "+994511234567"
  }
}
```

---

### 4. Chat API (Protected)

**⚠️ Token Lazımdır!**

```bash
# Replace YOUR_TOKEN_HERE with actual token
curl -X POST http://localhost:5000/api/chat \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -d '{
    "prompt": "Bak şəhərində kafe biznesi üçün yerdə analiz et"
  }'
```

Expected Response (200):
```json
{
  "success": true,
  "message": "Chat endpoint is ready for AI integration",
  "prompt": "Bak şəhərində kafe biznesi üçün yerdə analiz et",
  "provider": "gemini",
  "userId": "64f7a3c8e4d5f2a1b9c0d1e2"
}
```

---

### 5. Location Analysis (Protected)

```bash
curl -X POST http://localhost:5000/api/location-analysis \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -d '{
    "city": "Bakı",
    "businessType": "Kafe",
    "address": "Neftçi Prospekti 5"
  }'
```

Expected Response (200):
```json
{
  "success": true,
  "message": "Location analysis endpoint ready",
  "city": "Bakı",
  "businessType": "Kafe",
  "address": "Neftçi Prospekti 5",
  "userId": "64f7a3c8e4d5f2a1b9c0d1e2"
}
```

---

### 6. ROI Calculation (Protected)

```bash
curl -X POST http://localhost:5000/api/roi \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -d '{
    "rent": 2000,
    "averageTicket": 50,
    "margin": 0.35
  }'
```

Expected Response (200):
```json
{
  "success": true,
  "message": "ROI calculated successfully",
  "monthlyRevenue": 45000,
  "monthlyProfit": 13750,
  "roi": "587.50",
  "userId": "64f7a3c8e4d5f2a1b9c0d1e2"
}
```

---

## Error Cases

### Invalid Email Format

```bash
curl -X POST http://localhost:5000/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "name": "User",
    "email": "invalid-email",
    "password": "password123"
  }'
```

Response (400):
```json
{
  "success": false,
  "error": "..."
}
```

---

### User Already Exists

```bash
curl -X POST http://localhost:5000/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Əhməd",
    "email": "ahmad@example.com",
    "password": "password123"
  }'
```

Response (400):
```json
{
  "success": false,
  "message": "User already exists with this email"
}
```

---

### Invalid Credentials

```bash
curl -X POST http://localhost:5000/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "ahmad@example.com",
    "password": "wrong-password"
  }'
```

Response (401):
```json
{
  "success": false,
  "message": "Invalid credentials"
}
```

---

### Missing Token

```bash
curl -X POST http://localhost:5000/api/chat \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "Test"
  }'
```

Response (401):
```json
{
  "success": false,
  "message": "No token provided"
}
```

---

### Invalid Token

```bash
curl -X POST http://localhost:5000/api/chat \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer invalid-token-123" \
  -d '{
    "prompt": "Test"
  }'
```

Response (401):
```json
{
  "success": false,
  "message": "Invalid token"
}
```

---

## Testing Script

Hamısını bir dəfəyə test et:

```bash
#!/bin/bash

echo "🧪 Testing MongoDB Authentication API"
echo "=================================="

# 1. Sign Up
echo -e "\n1️⃣ Testing Sign Up..."
SIGNUP_RESPONSE=$(curl -s -X POST http://localhost:5000/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "email": "test'$(date +%s)'@example.com",
    "password": "password123",
    "businessType": "Test",
    "phone": "+994511234567"
  }')

TOKEN=$(echo $SIGNUP_RESPONSE | grep -o '"token":"[^"]*' | cut -d'"' -f4)
echo "✅ Token received: ${TOKEN:0:20}..."

# 2. Login
echo -e "\n2️⃣ Testing Login..."
curl -s -X POST http://localhost:5000/auth/login \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"test@example.com\",
    \"password\": \"password123\"
  }" | jq '.'

# 3. Chat (Protected)
echo -e "\n3️⃣ Testing Chat API..."
curl -s -X POST http://localhost:5000/api/chat \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "prompt": "Test prompt"
  }' | jq '.'

# 4. Location Analysis
echo -e "\n4️⃣ Testing Location Analysis..."
curl -s -X POST http://localhost:5000/api/location-analysis \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "city": "Bakı",
    "businessType": "Kafe"
  }' | jq '.'

# 5. ROI Calculation
echo -e "\n5️⃣ Testing ROI Calculation..."
curl -s -X POST http://localhost:5000/api/roi \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "rent": 2000,
    "averageTicket": 50,
    "margin": 0.35
  }' | jq '.'

echo -e "\n✅ All tests completed!"
```

Save as `test_api.sh` və çalış:
```bash
chmod +x test_api.sh
./test_api.sh
```

---

## Postman Collection

### Import to Postman

1. Create new Collection: `AI Business Agent`
2. Add requests:

#### Signup
- **Method**: POST
- **URL**: `{{baseUrl}}/auth/signup`
- **Headers**:
  ```
  Content-Type: application/json
  ```
- **Body**:
  ```json
  {
    "name": "Əhməd",
    "email": "ahmad@example.com",
    "password": "password123",
    "businessType": "Restoran",
    "phone": "+994511234567"
  }
  ```

#### Login
- **Method**: POST
- **URL**: `{{baseUrl}}/auth/login`
- **Headers**:
  ```
  Content-Type: application/json
  ```
- **Body**:
  ```json
  {
    "email": "ahmad@example.com",
    "password": "password123"
  }
  ```

#### Chat
- **Method**: POST
- **URL**: `{{baseUrl}}/api/chat`
- **Headers**:
  ```
  Content-Type: application/json
  Authorization: Bearer {{token}}
  ```
- **Body**:
  ```json
  {
    "prompt": "Test message"
  }
  ```

### Postman Variables

Set in Postman Environment:
```
baseUrl: http://localhost:5000
token: (paste from signup/login response)
```

---

## Flutter Integration Test

### Unit Test Example

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_business_agent/services/mongo_auth_service.dart';

void main() {
  group('MongoAuthService Tests', () {
    final authService = MongoAuthService();

    test('Sign Up should return user with token', () async {
      final user = await authService.signUp(
        name: 'Test User',
        email: 'test@example.com',
        password: 'password123',
      );

      expect(user, isNotEmpty);
      expect(authService.token, isNotNull);
    });

    test('Login should return user', () async {
      final user = await authService.login(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(user['email'], equals('test@example.com'));
      expect(authService.isAuthenticated, isTrue);
    });

    test('Invalid credentials should throw error', () async {
      expect(
        () => authService.login(
          email: 'test@example.com',
          password: 'wrong-password',
        ),
        throwsException,
      );
    });
  });
}
```

Run:
```bash
flutter test
```

---

## Debugging Tips

### Check MongoDB Data

```bash
# Mongo shell-ə qoş
mongosh "mongodb+srv://user:pass@cluster.mongodb.net"

# Database-ə keç
use ai-business-agent

# Istifadəçiləri gör
db.users.find()

# Xüsusi istifadəçini gör
db.users.findOne({email: "ahmad@example.com"})

# Parolasız istifadəçi məlumatı
db.users.findOne({email: "ahmad@example.com"}, {password: 0})
```

### Backend Logs

```bash
# Backend terminalı açıq olanında
# Əsə hər request loqa çəkiləcək

POST /auth/signup 201 - 45ms
POST /auth/login 200 - 32ms
POST /api/chat 200 - 28ms
```

### Flutter Logs

```bash
# Terminal-da
flutter logs

# Xüsusi filtr
flutter logs | grep "MongoAuthService"
```

---

## Performance Tips

### 1. Token Caching
```dart
// Bir dəfə login, token memory-də saxla
final authService = MongoAuthService();
final token = authService.token;
// Sonraki çağırışlarda token istifadə et
```

### 2. Connection Pooling
```dart
// Express avtomatik pooling edir
// Həm paralel request-lər məqul
```

### 3. Database Indexing
```javascript
// MongoDB indexing (backend setup)
db.users.createIndex({email: 1}) // Email-ə görə sürətli axtarış
```

---

## Summary

| Endpoint | Method | Auth | Məqsəd |
|----------|--------|------|--------|
| `/health` | GET | ❌ | Server statusu |
| `/auth/signup` | POST | ❌ | Qeydiyyat |
| `/auth/login` | POST | ❌ | Giriş |
| `/api/chat` | POST | ✅ | Chat |
| `/api/location-analysis` | POST | ✅ | Məkan analizi |
| `/api/roi` | POST | ✅ | ROI hesablaması |

**✅ Hamısı hazır! Happy testing! 🚀**
