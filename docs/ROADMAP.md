# Delivery roadmap

## Phase 0 — repository foundation (complete)
- [x] Confirm independent repository and reference-only boundary.
- [x] Record product requirements and architecture.
- [x] Establish runnable backend skeleton and automated tests.
- [x] Establish Flutter app shell and analysis baseline.
- [x] Add CI for backend and Android builds.

## Phase 1 — core platform (in progress)
- [x] Room create/join/leave/ready/start lifecycle in the backend.
- [x] Signed anonymous player sessions and reconnect grace handling.
- [x] Versioned Tic Tac Toe commands and server-authoritative validation.
- [x] PostgreSQL profile and leaderboard schema plus migration runner.
- [ ] Connect the independent Render API to its PostgreSQL instance.
- [ ] Complete two-device online smoke test against the deployed service.
- [ ] Add automated Socket.IO integration tests and protocol failure coverage.

## Phase 2 — game framework
- [ ] Game registry and shared lifecycle.
- [ ] Rules/state reducers with deterministic unit tests for each game.
- [ ] Offline/online parity contract.
- [ ] Implement games in testable batches; do not mark shell screens as complete games.

## Phase 3 — gameplay and polish
- [ ] Implement the agreed catalogue and variants.
- [ ] Game-specific physics, input, scoring and UI.
- [ ] Accessibility, performance and device-size review.
- [ ] AdMob consent, privacy and placement review.

## Phase 4 — release readiness
- [ ] Security review and production authentication.
- [ ] Managed database, backups and retention policy.
- [ ] Load tests at the agreed concurrency target and budget.
- [ ] Independent Render staging and production services.
- [ ] Android APK/AAB builds, signing, Play compliance and physical-device QA.

## Completion rule
A game is complete only when its rules, UI, offline behavior (if promised), online behavior (if promised), server validation, tests and two-device verification pass. A successful server boot or a passing unit suite alone is not production readiness.
