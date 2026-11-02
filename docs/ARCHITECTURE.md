# Architecture

## High-level
```
Flutter Android client
  | HTTPS (REST: health, profile/leaderboard)
  | WSS (Socket.IO: room lifecycle + game actions)
Independent RivalRooms API / realtime server
  | validated commands -> deterministic game reducers
  | room state (ephemeral) + persistence adapter (durable aggregates)
Managed database (only required profile/leaderboard data)
```

## Client
Flutter owns presentation, local/offline game execution, input capture, interpolation and cached preferences. Online game outcomes are always confirmed by the server. The client must gracefully handle disconnects, stale snapshots, duplicate acknowledgements and app background/resume.

## Server
Node.js 22, Express and Socket.IO. Keep transport handlers thin: authenticate, validate envelope, enforce room membership/rate limits, invoke a game reducer, persist required aggregates, broadcast versioned events. No client may choose its own player ID, score, winner or authoritative physics result.

## State model
Each room has a random opaque ID and short join code, owner, game ID, rules/config version, members, status, created/updated timestamps and monotonically increasing state version. Commands include commandId, roomId, expectedVersion, gameId and typed payload. Reject invalid membership, stale versions, illegal moves and duplicate command IDs. Reconnect uses a server-issued resume credential stored securely on device.

## Persistence
Room runtime state is ephemeral initially and must be explicitly documented as such. Durable storage is limited to stable player profile, leaderboard aggregates and abuse-prevention records. Database adapter must be replaceable and migrations versioned. Do not persist full gameplay telemetry by default.

## Security
- Production startup fails closed without production authentication and required secrets.
- HTTPS/WSS only in production.
- Schema validation and payload size limits on every socket event.
- Per-IP and per-player rate limits; room-code entropy and join throttling.
- CORS allowlist, security headers, structured redacted logs.
- Secrets only in Render environment settings / CI secrets, never source.
- Separate production and staging projects/resources.

## Scaling
Start with a single server process for correctness and early device testing. Before horizontal scaling, move room coordination to a shared adapter (for example Redis) and define sticky-session/Socket.IO adapter requirements. Durable leaderboard writes use a managed database. Do not claim a concurrent-user capacity until load tests measure room mix, messages per second, CPU, memory and p95 latency.

## Deployment isolation
Render service names, environment groups, database, domains and secrets must be new and prefixed `rivalrooms-latest`. Existing Clay and older RivalRooms services are out of scope and must not be modified.
