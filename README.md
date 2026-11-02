# RivalRooms Latest

Independent multiplayer mini-game platform. This repository is the sole source of truth for the new RivalRooms production app and services.

> This is a fresh implementation. `RivalRooms-Clay` is a read-only product/engineering reference; no Clay runtime, database, credentials, Render service, or deployment is reused.

## Product goals
- Flutter Android app with polished, accessible game UI.
- Local play plus online rooms for turn-based and real-time games.
- Authoritative server validation for multiplayer state and scoring.
- Anonymous/local-first player identity; persist only leaderboard/profile data that is explicitly needed.
- AdMob with test ads by default and consent/privacy safeguards.
- Release APK and Play Store AAB with reproducible CI builds.

## Repository layout
- `mobile/`: Flutter application.
- `server/`: independent Node.js + Socket.IO backend.
- `docs/`: product requirements, architecture, security, game specs and release checklists.
- `.github/workflows/`: independent CI and Android build pipelines.

## Current status
Phase 0 — repository foundation. App features, game implementations, database persistence, production deployment and release artifacts are not yet complete. See [the roadmap](docs/ROADMAP.md).

## Local development
Prerequisites: Flutter stable (Dart 3.10+), Node.js 22+, npm.

Backend:
```sh
cd server
cp .env.example .env
npm install
npm test
npm run dev
```

Mobile (after Flutter SDK is installed):
```sh
cd mobile
flutter pub get
flutter analyze
flutter test
```

The backend refuses insecure development authentication in production. Configure a real identity provider and a managed database before public launch. Never commit secrets.
