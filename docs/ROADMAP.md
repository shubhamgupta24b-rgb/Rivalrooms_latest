# Delivery roadmap

## Phase 0 — repository foundation (in progress)
- [x] Confirm independent repository and reference-only boundary.
- [x] Record product requirements and architecture.
- [ ] Establish runnable backend skeleton and tests.
- [ ] Establish Flutter app shell and analysis baseline.
- [ ] Add CI for backend and Android builds.

## Phase 1 — core platform
- [ ] Room create/join/leave/ready/start lifecycle.
- [ ] Secure anonymous identity and reconnect.
- [ ] Versioned event protocol and server-authoritative command pipeline.
- [ ] Local profile/preferences and leaderboard persistence adapter.
- [ ] Two-device smoke test and basic observability.

## Phase 2 — game framework
- [ ] Game registry and shared lifecycle.
- [ ] Rules/state reducers with deterministic unit tests.
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
