# Product requirements

## Product boundary
RivalRooms Latest is an independent app and backend. Clay is reference material only. All code, deployments, data stores, secrets, app identifiers and release artifacts must belong to this project.

## Experience
- Fast entry into solo, same-device and online multiplayer games.
- Create/join rooms with short shareable codes; show player presence and ready state.
- Clear turn ownership, timers, scores, reconnecting and match-complete states.
- Mature, game-specific presentation; avoid generic template-like screens and unnecessary explanatory copy.
- Respect reduced motion, readable contrast, scalable layouts and accessible touch targets.

## Game catalogue
Use the full game list and prior chat requirements as the discovery backlog, not as a claim that every game is already implemented. Each game must have an explicit ruleset, player limits, state model, input model, win condition, offline support, online support and test plan. Include the previously requested games and variants, including Memory, Basketball Hoops, Fruit Cut, Math Duel, Guess the Person, Pool/Eight Ball, Raja Mantri Chor Sipahi, Ball Sort, Chicken Jump and Nitro Knockout. Remove superseded titles where the prior brief explicitly requested replacement (for example Smash Kart -> Nitro Knockout and Fruit Duel -> Fruit Cut).

## Multiplayer
- Server-authoritative validation for all competitive online moves.
- Room lifecycle, membership, reconnect grace, idempotent actions, rate limits and versioned state snapshots.
- Turn-based and real-time transports share room identity but use game-specific authoritative reducers.
- Never trust client-submitted scores, winners, physics outcomes or player identity claims.
- Real-time games must define tick rate, input sequencing, latency handling and snapshot reconciliation.

## Data minimisation
- Keep preferences and nonessential session state on-device.
- Store only the stable player key, display profile and leaderboard/match aggregates that are required.
- Do not store passwords. Use a secure identity strategy before enabling cross-device identity or public leaderboards.
- Define retention and deletion behavior before launch.

## Monetisation and privacy
- AdMob test inventory by default in development and CI.
- Production ad units only in signed/reviewed release builds.
- Consent gating, privacy options, privacy policy, Play Data Safety and ads declarations are release blockers.
- Ads must never interrupt an active match or reward an action without clear disclosure.

## Quality gates
- Unit tests for game rules and deterministic state reducers.
- Socket integration tests for room lifecycle and adversarial client input.
- Flutter widget tests for core flows and per-game UI.
- Device tests with at least two physical clients for each online game family.
- Release build, crash-free smoke test and rollback plan before production.
