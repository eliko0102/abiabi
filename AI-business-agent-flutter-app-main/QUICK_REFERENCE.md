# 🎯 Quick Reference Card

## Backend Setup (60 seconds)

```bash
# 1. Install
cd backend/
npm install

# 2. Run
npm run dev

# ✅ Terminal output:
# ✅ MongoDB connected successfully
# 🚀 Server is running on port 5000
```

## Flutter Setup (30 seconds)

```bash
# 1. Install
flutter pub get

# 2. Run
flutter run

# ✅ Result:
# Login Screen appears
```

## API Quick Test

```bash
# Sign Up
curl -X POST http://localhost:5000/auth/signup \
  -H "Content-Type: application/json" \
  -d '{"name":"User","email":"user@ex.com","password":"pass123"}'

# Login
curl -X POST http://localhost:5000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@ex.com","password":"pass123"}'

# Use token from response for protected routes
```

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    FLUTTER APP (Client)                     │
│                                                              │
│  ┌──────────────┐         ┌──────────────┐                 │
│  │ LoginScreen  │         │ SignUpScreen │                 │
│  └──────────────┘         └──────────────┘                 │
│         │                        │                          │
│         └────────┬───────────────┘                          │
│                  ▼                                           │
│         ┌─────────────────┐                                 │
│         │ MongoAuthService│ (Email, Password → Token)       │
│         └────────┬────────┘                                 │
│                  │                                           │
│         ┌────────▼────────┐                                 │
│         │ AuthProvider    │ (State Management)              │
│         └────────┬────────┘                                 │
│                  │                                           │
│         ┌────────▼────────┐                                 │
│         │ API Services    │ (Token in header)               │
│         │  - AiService    │                                 │
│         │  - BusinessAPI  │                                 │
│         └────────┬────────┘                                 │
│                  │ HTTP                                     │
└─────────────────┼─────────────────────────────────────────┘
                  │
                  ▼ (Bearer Token)
┌──────────────────────────────────────────────────────────────┐
│            NODE.JS EXPRESS BACKEND                           │
│                                                              │
│  ┌─────────────────────────────────────┐                   │
│  │ Routes                              │                   │
│  │ ├── POST /auth/signup              │ (No Token)        │
│  │ ├── POST /auth/login               │ (No Token)        │
│  │ ├── POST /api/chat                 │ ⚠️ Token Required │
│  │ ├── POST /api/location-analysis    │ ⚠️ Token Required │
│  │ └── POST /api/roi                  │ ⚠️ Token Required │
│  └──────────────┬──────────────────────┘                   │
│                 │                                           │
│         ┌───────▼────────┐                                 │
│         │ Auth Middleware│ (JWT Verify)                    │
│         └───────┬────────┘                                 │
│                 │                                           │
│         ┌───────▼────────┐                                 │
│         │ Database Layer │                                 │
│         └───────┬────────┘                                 │
│                 │                                           │
└─────────────────┼──────────────────────────────────────────┘
                  │
                  ▼
        ┌─────────────────────┐
        │ MongoDB Atlas Cloud │
        │  (ai-business-agent │
        │   database)         │
        │  users collection   │
        └─────────────────────┘
```

---

## File Structure (What's New)

```
AI-Business-Agent/
│
├── backend/
│   ├── .env ⭐ UPDATED (MongoDB credentials)
│   ├── server.js ⭐ NEW
│   ├── package.json ⭐ NEW
│   ├── models/User.js ⭐ NEW
│   ├── routes/
│   │   ├── auth.js ⭐ NEW
│   │   └── api.js ⭐ NEW
│   ├── middleware/
│   │   └── auth.js ⭐ NEW
│   └── README.md ⭐ UPDATED
│
├── lib/
│   ├── screens/
│   │   ├── login_screen.dart ⭐ NEW
│   │   └── signup_screen.dart ⭐ NEW
│   ├── services/
│   │   ├── mongo_auth_service.dart (exists)
│   │   ├── ai_service.dart ⭐ UPDATED
│   │   ├── business_api_service_v2.dart ⭐ NEW
│   │   └── firebase_auth_service.dart (optional remove)
│   ├── providers/
│   │   └── auth_provider.dart ⭐ NEW
│   ├── utils/
│   │   └── error_handler.dart ⭐ NEW
│   ├── config/
│   │   ├── api_config.dart ⭐ UPDATED
│   │   └── routes.dart ⭐ NEW
│   └── main_with_auth.dart ⭐ NEW
│
└── Docs/
    ├── MONGO_AUTH_INTEGRATION.md ⭐ NEW (Integration guide)
    ├── TESTING_GUIDE.md ⭐ NEW (Testing guide)
    ├── IMPLEMENTATION_COMPLETE.md ⭐ NEW (Summary)
    ├── FIREBASE_TO_MONGODB_MIGRATION.md (exists)
    ├── QUICK_START.md (exists)
    └── backend/README.md (exists)
```

---

## Function Reference

### MongoAuthService

```dart
// Create
final auth = MongoAuthService();

// Sign Up
Map<String, dynamic> user = await auth.signUp(
  name: 'Name',
  email: 'email@ex.com',
  password: 'pass123',
  businessType: 'Type',
  phone: 'Number',
);

// Login
Map<String, dynamic> user = await auth.login(
  email: 'email@ex.com',
  password: 'pass123',
);

// Check token
String? token = auth.token;
bool isAuth = auth.isAuthenticated;

// Get headers
Map<String, String> headers = auth.getAuthHeaders();
// Returns: {'Authorization': 'Bearer <token>', 'Content-Type': 'application/json'}

// Logout
await auth.logout();
```

### AuthProvider

```dart
// Create
final provider = AuthProvider();

// Sign Up
bool success = await provider.signup(
  name: 'Name',
  email: 'email@ex.com',
  password: 'pass123',
);

// Login
bool success = await provider.login(
  email: 'email@ex.com',
  password: 'pass123',
);

// Check state
if (provider.isAuthenticated) {
  var user = provider.currentUser;
  var token = provider.token;
}

// Error handling
if (!success) {
  String error = provider.error ?? 'Unknown error';
}

// Logout
await provider.logout();
```

### ErrorHandler

```dart
import 'utils/error_handler.dart';

// Show error
ErrorHandler.showError(context, 'Error message');

// Show success
ErrorHandler.showSuccess(context, 'Success message');

// Show info
ErrorHandler.showInfo(context, 'Info message');

// Show dialog
bool? result = await ErrorHandler.showConfirmDialog(
  context,
  title: 'Title',
  message: 'Confirm?',
  confirmText: 'Yes',
  cancelText: 'No',
);
```

---

## Environment Variables

### Backend (.env)

| Variable | Value |
|----------|-------|
| `MONGODB_URI` | `mongodb+srv://elsencamalov9605_db_user:...` |
| `PORT` | `5000` |
| `NODE_ENV` | `development` |
| `JWT_SECRET` | Secret string (change in production) |
| `AI_PROVIDER` | `gemini` or `openai` |

### Frontend (lib/config/api_config.dart)

```dart
static const backendUrl = 'http://localhost:5000';
// Android Emulator: 'http://10.0.2.2:5000'
// Real Device: 'http://192.168.x.x:5000'
```

---

## Common Commands

```bash
# Backend
cd backend/
npm install              # Install dependencies
npm run dev             # Start development server
npm start               # Start production server

# Frontend
flutter pub get         # Get dependencies
flutter run             # Run app
flutter run -v          # Run with verbose logs
flutter logs            # Show app logs
flutter clean           # Clean build

# Testing
curl http://localhost:5000/health  # Test backend
mongosh "mongodb+srv://..."        # MongoDB shell
```

---

## Troubleshooting Quick Fixes

| Problem | Fix |
|---------|-----|
| Backend won't start | Check `.env` MONGODB_URI, restart `npm run dev` |
| MongoDB connection error | Check internet, verify credentials in `.env` |
| 401 Unauthorized | Login again, copy token from response |
| Invalid token | Make sure token is in header: `Authorization: Bearer <token>` |
| Flutter screens not showing | Copy `main_with_auth.dart` to `main.dart` |
| Android connection refused | Use `10.0.2.2:5000` instead of `localhost` |

---

## Before Going Live

- [ ] Change `JWT_SECRET` to a strong random string
- [ ] Change `NODE_ENV` to `production`
- [ ] Set `backendUrl` to HTTPS production domain
- [ ] Enable HTTPS for backend
- [ ] Add password reset endpoint
- [ ] Add token refresh logic
- [ ] Add rate limiting
- [ ] Set up error logging
- [ ] Test on real device
- [ ] Set up CI/CD pipeline

---

## Key Learnings

1. **JWT Tokens**: Stateless authentication, includes user info
2. **bcryptjs**: One-way password hashing (can't be reversed)
3. **MongoDB**: Document-based NoSQL database
4. **CORS**: Cross-origin resource sharing (Flutter ↔ Backend)
5. **Bearer Token**: `Authorization: Bearer <token>` format

---

## Resources

| Topic | Link |
|-------|------|
| Node.js Guide | backend/README.md |
| Integration | MONGO_AUTH_INTEGRATION.md |
| Testing | TESTING_GUIDE.md |
| API Docs | backend/README.md#api-endpoints |

---

## Status: ✅ READY TO USE

All components are implemented and documented. Start with:

```bash
# Terminal 1: Backend
cd backend && npm run dev

# Terminal 2: Flutter
flutter run
```

**Expected**: Login/Signup screens appear! 🎉

---

**Last Updated**: 2026-08-18
**Status**: Complete Implementation
**Next Step**: Integration & Testing
