# AI Business Agent - Node.js Backend

Modern Node.js + Express + MongoDB backend for the AI Business Agent Flutter app.

## Features

- ✅ User Registration & Login with MongoDB
- ✅ JWT Token-based Authentication
- ✅ Password Hashing with bcryptjs
- ✅ Chat API with Auth Protection
- ✅ Location Analysis Endpoint
- ✅ ROI Calculation Endpoint
- ✅ CORS Enabled for Flutter

## Prerequisites

- Node.js 16+ (LTS recommended)
- MongoDB 4.4+
- npm or yarn

## Installation

1. **Install dependencies**
```bash
npm install
```

2. **Create `.env` file** (copy from `.env.example`)
```bash
cp .env.example .env
```

## Local auth server

MongoDB must be running before starting this server. Fill `MONGODB_URI` and
`JWT_SECRET` in `.env`, then run:

```bash
npm install
npm start
curl http://127.0.0.1:5000/health
```

The health response must contain `"status":"ok"` before login/register can
work. A `503` response means the Node server is running but MongoDB is not
connected yet.

Location analysis is a separate FastAPI service on port `8000` and requires
`TWOGIS_API_KEY`. Deploy both services from the root `render.yaml`, then pass
the analysis service URL to Flutter as `TOCHKA_API_BASE_URL`.

## Deploy the auth backend

The repository includes `backend/render.yaml` for Render. Create a MongoDB
Atlas database, create a Render Blueprint from this repository, and set the
secret `MONGODB_URI`, `GEMINI_API_KEY`, and `TWOGIS_API_KEY` values in Render.
After deployment, verify `https://YOUR-SERVICE.onrender.com/health`, then build
Flutter with the public Node URL:

```bash
flutter build apk --dart-define=BACKEND_URL=https://YOUR-SERVICE.onrender.com
```

Do not use `127.0.0.1` or `localhost` in a mobile production build.

3. **Configure environment variables**
```
MONGODB_URI=mongodb://localhost:27017/ai-business-agent
PORT=5000
JWT_SECRET=your-super-secret-key-change-this
AI_PROVIDER=gemini
```

## Running the Server

### Development Mode (with hot reload)
```bash
npm run dev
```

### Production Mode
```bash
npm start
```

Server will start on `http://localhost:5000`

## API Endpoints

### Authentication Routes

#### Sign Up
```
POST /auth/signup
Content-Type: application/json

{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "securePassword123",
  "businessType": "Restaurant",
  "phone": "+994511234567"
}

Response:
{
  "success": true,
  "message": "User registered successfully",
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "user": {
    "id": "64f7a3c8e4d5f2a1b9c0d1e2",
    "name": "John Doe",
    "email": "john@example.com",
    "businessType": "Restaurant",
    "phone": "+994511234567"
  }
}
```

#### Login
```
POST /auth/login
Content-Type: application/json

{
  "email": "john@example.com",
  "password": "securePassword123"
}

Response:
{
  "success": true,
  "message": "Login successful",
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "user": { ... }
}
```

### Protected Routes (Require Authorization Header)

#### Chat
```
POST /api/chat
Authorization: Bearer {token}
Content-Type: application/json

{
  "prompt": "Analyize my business"
}
```

#### Location Analysis
```
POST /api/location-analysis
Authorization: Bearer {token}
Content-Type: application/json

{
  "city": "Baku",
  "businessType": "Coffee Shop",
  "address": "Neftchi Ave 5"
}
```

#### ROI Calculation
```
POST /api/roi
Authorization: Bearer {token}
Content-Type: application/json

{
  "rent": 2000,
  "averageTicket": 50,
  "margin": 0.35
}
```

## Database Schema

### User Collection
```javascript
{
  _id: ObjectId,
  name: String (required),
  email: String (required, unique),
  password: String (required, hashed),
  businessType: String,
  phone: String,
  createdAt: Date,
  updatedAt: Date
}
```

## Flutter Integration

### 1. Update API Config
In `lib/config/api_config.dart`:
```dart
static const backendUrl = String.fromEnvironment(
  'BACKEND_URL',
  defaultValue: 'http://127.0.0.1:5000',
);
```

### 2. Use MongoDB Auth Service
```dart
import 'services/mongo_auth_service.dart';

final authService = MongoAuthService();

// Sign Up
try {
  final user = await authService.signUp(
    name: 'John Doe',
    email: 'john@example.com',
    password: 'securePassword',
    businessType: 'Restaurant',
  );
  print('User created: $user');
} catch (e) {
  print('Error: $e');
}

// Login
try {
  final user = await authService.login(
    email: 'john@example.com',
    password: 'securePassword',
  );
  print('Logged in: $user');
} catch (e) {
  print('Error: $e');
}

// Get Auth Headers for API Calls
final headers = authService.getAuthHeaders();
```

### 3. Use Updated AI Service
```dart
import 'services/ai_service.dart';

final aiService = AiService(authToken: authService.token);
final response = await aiService.generateResponse('My prompt');
```

## MongoDB Setup

### Local MongoDB
```bash
# On Ubuntu/Debian
sudo systemctl start mongod

# Or with Docker
docker run -d -p 27017:27017 --name mongodb mongo:latest
```

### MongoDB Atlas (Cloud)
1. Create account at https://www.mongodb.com/cloud/atlas
2. Create a cluster
3. Get connection string
4. Add to `.env`:
```
MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/ai-business-agent
```

## Security Best Practices

- ✅ Change `JWT_SECRET` to a random strong string
- ✅ Never commit `.env` file to git (use `.env.example`)
- ✅ Use HTTPS in production
- ✅ Implement rate limiting
- ✅ Add input validation on both client and server
- ✅ Use environment variables for sensitive data
- ✅ Enable MongoDB authentication

## Troubleshooting

### MongoDB Connection Error
```
❌ MongoDB connection error: connect ECONNREFUSED 127.0.0.1:27017
```
Solution: Make sure MongoDB is running or update `MONGODB_URI`

### Invalid Token Error
```
401 Unauthorized: Invalid token
```
Solution: Make sure token is passed in Authorization header correctly

### CORS Error
```
Access to XMLHttpRequest blocked by CORS policy
```
Solution: Backend already has CORS enabled, check browser console for details

## Testing

### Using cURL
```bash
# Test health endpoint
curl http://localhost:5000/health

# Sign up
curl -X POST http://localhost:5000/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "email": "test@example.com",
    "password": "password123"
  }'

# Login
curl -X POST http://localhost:5000/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'
```

## License

ISC
