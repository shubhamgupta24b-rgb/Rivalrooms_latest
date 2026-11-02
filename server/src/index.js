'use strict';
const express = require('express');
const http = require('node:http');
const { Server } = require('socket.io');
const { RoomManager, RoomError } = require('./rooms/room_manager');
const { createSessionService } = require('./auth/session');
const { createStorage } = require('./storage/postgres');
const app = express();
app.disable('x-powered-by');
app.use(express.json({ limit: '16kb' }));
const secret = process.env.SESSION_SECRET || (process.env.NODE_ENV === 'production' ? null : 'local-development-session-secret-change-before-deploy');
const sessions = createSessionService({ secret });
const storage = createStorage();
const rooms = new RoomManager({ maxMembers: Number(process.env.MAX_ROOM_MEMBERS || 10),
  codeLength: Number(process.env.ROOM_CODE_LENGTH || 6), reconnectGraceMs: Number(process.env.RECONNECT_GRACE_MS || 60000) });
function requirePlayer(req, res, next) {
  const token = (req.headers.authorization || '').replace(/^Bearer /, '');
  const player = sessions.verify(token);
  if (!player) return res.status(401).json({ error: { code: 'UNAUTHORIZED', message: 'Create or renew your player session.' } });
  req.player = player; next();
}
function handleError(res, error) {
  const known = error instanceof RoomError;
  res.status(known ? 400 : 500).json({ error: { code: known ? error.code : 'INTERNAL_ERROR',
    message: known ? error.message : 'Something went wrong.' } });
}
app.get('/health', (_req, res) => res.json({ ok: true, service: 'rivalrooms-latest-api', version: '0.3.0' }));
app.get('/ready', async (_req, res) => {
  if (!storage.enabled) return res.status(503).json({ ok: false, database: 'not_configured' });
  try { await storage.ping(); res.json({ ok: true, database: 'connected' }); }
  catch { res.status(503).json({ ok: false, database: 'unavailable' }); }
});
app.post('/v1/sessions', (req, res) => {
  const { deviceId, displayName } = req.body || {};
  if (typeof deviceId !== 'string' || !/^[a-zA-Z0-9_-]{8,80}$/.test(deviceId))
    return res.status(400).json({ error: { code: 'INVALID_DEVICE_ID', message: 'A valid locally generated device ID is required.' } });
  if (typeof displayName !== 'string' || displayName.trim().length < 1 || displayName.trim().length > 24)
    return res.status(400).json({ error: { code: 'INVALID_NAME', message: 'Display name must be 1–24 characters.' } });
  const player = { playerId: deviceId, displayName: displayName.trim() };
  if (!storage.enabled) return res.status(503).json({ error: { code: 'STORAGE_NOT_CONFIGURED', message: 'Player profiles are temporarily unavailable.' } });
  storage.upsertProfile(player).then(() => {
    res.status(201).json({ token: sessions.issue(player), player, expiresInSeconds: 2592000 });
  }).catch(() => res.status(503).json({ error: { code: 'STORAGE_UNAVAILABLE', message: 'Player profile could not be saved.' } }));
});
app.post('/v1/rooms', requirePlayer, (req, res) => {
  try { res.status(201).json({ room: rooms.create({ ...req.player, gameId: req.body?.gameId, maxMembers: req.body?.maxMembers }) }); }
  catch (error) { handleError(res, error); }
});
app.post('/v1/rooms/join', requirePlayer, (req, res) => {
  try { res.json({ room: rooms.join({ ...req.player, code: req.body?.code }) }); }
  catch (error) { handleError(res, error); }
});
app.get('/v1/leaderboards/:gameId', requirePlayer, async (req, res) => {
  if (!storage.enabled) return res.status(503).json({ error: { code: 'STORAGE_NOT_CONFIGURED', message: 'Leaderboards are unavailable.' } });
  if (!/^[a-z0-9_]{2,48}$/.test(req.params.gameId)) return res.status(400).json({ error: { code: 'INVALID_GAME', message: 'Invalid game identifier.' } });
  try { res.json({ gameId: req.params.gameId, entries: await storage.getLeaderboard(req.params.gameId, req.query.limit) }); }
  catch { res.status(503).json({ error: { code: 'STORAGE_UNAVAILABLE', message: 'Leaderboard could not be loaded.' } }); }
});
app.get('/v1/rooms/:code', requirePlayer, (req, res) => {
  const room = rooms.getByCode(req.params.code);
  if (!room || !room.members.some((m) => m.playerId === req.player.playerId))
    return res.status(404).json({ error: { code: 'ROOM_NOT_FOUND', message: 'Room not found.' } });
  res.json({ room });
});
const server = http.createServer(app);
const origins = (process.env.CLIENT_ORIGINS || 'http://localhost:3000').split(',').map((v) => v.trim()).filter(Boolean);
const io = new Server(server, { cors: { origin: origins, methods: ['GET', 'POST'] },
  maxHttpBufferSize: 64 * 1024, transports: ['websocket', 'polling'] });
io.use((socket, next) => {
  const player = sessions.verify(socket.handshake.auth?.token);
  if (!player) return next(new Error('UNAUTHORIZED'));
  socket.data.player = player; next();
});
function emitRoom(room) { if (room) io.to(room.id).emit('room:updated', room); }
function ackError(ack, error) {
  if (typeof ack === 'function') ack({ ok: false, error: { code: error.code || 'INTERNAL_ERROR', message: error.message || 'Something went wrong.' } });
}
io.on('connection', (socket) => {
  const player = socket.data.player;
  socket.emit('server:hello', { service: 'rivalrooms-latest', protocolVersion: 1, playerId: player.playerId });
  socket.on('room:connect', ({ roomId } = {}, ack) => {
    try {
      const room = rooms.rooms.get(roomId);
      if (!room || !room.members.has(player.playerId)) throw new RoomError('NOT_A_MEMBER', 'Join this room first.');
      const snapshot = rooms.attachSocket(roomId, player.playerId, socket.id);
      socket.join(roomId); emitRoom(snapshot);
      if (typeof ack === 'function') ack({ ok: true, room: snapshot });
    } catch (error) { ackError(ack, error); }
  });
  socket.on('room:ready', ({ ready } = {}, ack) => {
    try {
      const id = rooms.socketToRoom.get(socket.id);
      if (!id) throw new RoomError('NOT_IN_ROOM', 'Connect to a room first.');
      const snapshot = rooms.setReady(id, player.playerId, ready); emitRoom(snapshot);
      if (typeof ack === 'function') ack({ ok: true, room: snapshot });
    } catch (error) { ackError(ack, error); }
  });
  socket.on('room:start', (_payload = {}, ack) => {
    try {
      const id = rooms.socketToRoom.get(socket.id);
      if (!id) throw new RoomError('NOT_IN_ROOM', 'Connect to a room first.');
      const snapshot = rooms.start(id, player.playerId); emitRoom(snapshot);
      if (typeof ack === 'function') ack({ ok: true, room: snapshot });
    } catch (error) { ackError(ack, error); }
  });
  socket.on('room:leave', (_payload = {}, ack) => {
    try {
      const id = rooms.socketToRoom.get(socket.id);
      if (!id) throw new RoomError('NOT_IN_ROOM', 'Connect to a room first.');
      socket.leave(id); const snapshot = rooms.leave(id, player.playerId); emitRoom(snapshot);
      if (typeof ack === 'function') ack({ ok: true, room: snapshot });
    } catch (error) { ackError(ack, error); }
  });
  socket.on('disconnect', () => emitRoom(rooms.disconnect(socket.id)));
});
const sweepInterval = setInterval(() => rooms.sweepExpired(), 15000);
sweepInterval.unref();
const port = Number(process.env.PORT || 3000);
if (require.main === module) server.listen(port, '0.0.0.0', () =>
  console.log(JSON.stringify({ level: 'info', event: 'server_listening', port, service: 'rivalrooms-latest' })));
module.exports = { app, server, io, rooms, sessions, storage };
