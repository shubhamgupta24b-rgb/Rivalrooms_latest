# RivalRooms Latest

Independent multiplayer mini-game platform. This repository is the sole source of truth for the new RivalRooms app and services.

> Fresh implementation. `RivalRooms-Clay` is a read-only product reference; no Clay runtime, database, credentials, Render service, or deployment is reused.

## Current implementation

- Flutter Android app with a dark, amber-accented game hub.
- Local two-player Tic Tac Toe with win/draw detection and restart.
- Guest player sessions and authenticated REST room create/join APIs.
- Socket.IO room presence, ready/start actions, and authoritative Tic Tac Toe game events.
- Node.js backend with room lifecycle and versioned game state.
- PostgreSQL migrations and leaderboard persistence implementation.
- GitHub Actions backend tests, Flutter analysis/tests, and debug APK artifact pipeline.

## Known gaps (do not treat as production-ready)

- A separate Render PostgreSQL database has been provisioned in Singapore (free tier). The API service is not deployed or connected to it yet; session creation still returns service-unavailable until DATABASE_URL is configured and migrations are applied.
- Room/game state is currently in process memory; it is not durable across restarts and is not horizontally scalable. Redis or another shared authoritative state layer is required before multiple server instances.
- The online Tic Tac Toe flow is implemented in the client and server. Backend unit tests pass; a two-device integration test against a deployed backend/database is still required.
- Match result persistence requires a healthy PostgreSQL connection.
- The wider game catalogue, complete per-game mechanics/physics, AdMob consent and production IDs, privacy/store declarations, load tests, signed APK/AAB and Play Store release remain future work.
- Device-local guest IDs are not a secure account recovery mechanism and can be lost on uninstall.

## Repository layout

- `mobile/`: Flutter application.
- `server/`: independent Node.js + Socket.IO backend.
- `docs/`: product requirements, architecture and roadmap.
- `.github/workflows/`: independent CI and Android build pipeline.

## Local development

Prerequisites: Flutter stable (Dart 3.10+), Node.js 22+, npm and PostgreSQL.

Backend:
```sh
cd server
cp .env.example .env
# Configure DATABASE_URL and SESSION_SECRET (at least 32 random characters)
npm install
npm run db:migrate
npm test
npm run dev
```

Mobile:
```sh
cd mobile
flutter pub get
flutter analyze
flutter test
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
```

Never commit secrets. Production requires TLS, a managed database, a shared room-state strategy, platform identity/recovery, privacy/consent work and load testing.
