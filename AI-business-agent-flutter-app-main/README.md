# AI Business Agent

This repository contains a Flutter mobile app and a FastAPI backend for an AI-powered business agent platform.

## Stack
- Frontend: Flutter
- Backend: FastAPI (Python)
- AI: GPT-5.5 + Claude 4 Sonnet (ready for integration)
- Agent: LangGraph + OpenAI Agents SDK (ready for integration)
- Database: PostgreSQL + pgvector + Redis (ready for integration)
- Maps: 2GIS tiles and Catalog API (configured via environment variables)
- Authentication: Firebase Authentication + WhatsApp Business API (ready for integration)

## Run backend
```bash
cd backend
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

## Auth server paylaşımı

Login və qeydiyyat Node.js + MongoDB backend-dən istifadə edir; FastAPI serveri
(`:8000`) bunları təmin etmir. Production üçün MongoDB Atlas və Node backend-i
deploy edin, sonra Flutter build zamanı public URL verin:

```bash
flutter build apk --dart-define=BACKEND_URL=https://YOUR-SERVICE.onrender.com
```

Mobil tətbiqdə `127.0.0.1:5000` istifadə etməyin. Ətraflı Render addımları
`backend/README.md` faylındadır.

## Run frontend
```bash
cd ..
export PATH="/tmp/flutter/bin:$PATH"
flutter pub get
flutter test
flutter run
```
