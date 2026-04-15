# Chat App (Flutter + FastAPI)

A simple real-time chat application built with:

- Flutter (GetX) client in `lib/`
- FastAPI + WebSocket backend in `backend/`
- PostgreSQL database (via SQLAlchemy + asyncpg)

## Features

- Register + login (email or phone + password)
- Public rooms (create/list)
- Direct chats (1:1 room creation)
- Real-time messaging via WebSocket (with REST fallback)
- Message history + delete own messages
- Local session persistence (SharedPreferences)

## Repository Structure

- `lib/` Flutter app (UI, controllers, services)
- `backend/` FastAPI server + DB models
- `assets/` app assets (icons)

## Prerequisites

- Flutter SDK (Dart SDK >= 3.11)
- Python 3.10+ (recommended: 3.11)
- PostgreSQL database

## Run Backend (FastAPI)

1) Create and activate a virtual environment

```bash
cd backend
python -m venv .venv
source .venv/bin/activate
```

2) Install dependencies

```bash
pip install -r requirements.txt
```

3) Set environment variables

The backend requires `DATABASE_URL` (it will crash on startup if not set). You can export env vars in your shell, or create a `.env` file inside `backend/` (it is loaded automatically).

Example values:

```bash
export DATABASE_URL="postgresql://postgres:postgres@localhost:5432/chatapp"
export JWT_SECRET_KEY="change-me"
export JWT_ALGORITHM="HS256"
export CORS_ORIGINS="http://localhost:3000,http://localhost:5173"
```

Notes:

- `DATABASE_URL` supports `postgres://` and `postgresql://`; it is converted internally to `postgresql+asyncpg://...`.
- `CORS_ORIGINS` defaults to `*` if not provided.
- If `JWT_SECRET_KEY` is not set, the backend falls back to `supersecretkey` (not safe for production).

4) Start the server

```bash
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

Health check:

```bash
curl http://localhost:8000/health
```

## Run App (Flutter)

1) Install dependencies

```bash
flutter pub get
```

2) Point the app to your backend

The Flutter app reads the API base URL from a compile-time dart define:

- Key: `API_BASE_URL`
- Default: an ngrok URL (see [ApiService](lib/app/services/api_service.dart))

Run with a local backend:

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:8000
```

If you run on a physical device/emulator, use your machine’s LAN IP instead of `localhost`, for example:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000
```

## API Overview

REST endpoints (see [backend/main.py](backend/main.py)):

- `GET /health`
- `POST /register`
- `POST /login`
- `GET /users` (optional query: `exclude_id`)
- `POST /users/lookup`
- `POST /rooms`
- `GET /users/{user_id}/rooms`
- `GET /rooms/{room_id}/messages` (query: `limit`, `offset`)
- `POST /rooms/{room_id}/messages`
- `DELETE /messages/{message_id}` (query: `requester_id`)

WebSocket:

- `WS /ws/{room_id}/{user_id}`
- Client sends plain text messages (the message content)
- Server broadcasts JSON payloads that match the app’s `ChatMessage` model

## Database

The backend uses SQLAlchemy models defined in [backend/models.py](backend/models.py). Tables are created automatically on server startup (`Base.metadata.create_all`), so there are no migrations included in this repo.

## Common Issues

- Backend crashes with `DATABASE_URL is not set`: set `DATABASE_URL` (or create `backend/.env`).
- Flutter can’t reach backend from Android emulator: use `http://10.0.2.2:8000` instead of `localhost`.
- Flutter can’t reach backend from iOS simulator: `http://localhost:8000` usually works; for real devices use your LAN IP.
- WebSocket disconnects: confirm the app is using the same base URL and that the backend is reachable over `ws://` or `wss://`.

## Useful Commands

```bash
flutter analyze
flutter test
```
