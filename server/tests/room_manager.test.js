'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { RoomManager, RoomError } = require('../src/rooms/room_manager');

const player = (n) => ({ playerId: `player_id_${n}`, displayName: `Player ${n}` });

test('creates a private waiting room and allows a second player to join', () => {
  const rooms = new RoomManager();
  const created = rooms.create({ ...player(1), gameId: 'connect_four' });
  assert.match(created.code, /^[A-Z2-9]{6}$/);
  assert.equal(created.members.length, 1);
  const joined = rooms.join({ ...player(2), code: created.code, socketId: 'socket-2' });
  assert.equal(joined.members.length, 2);
  assert.equal(joined.version, 2);
});

test('rejects non-host start and requires all guests ready', () => {
  const rooms = new RoomManager();
  const created = rooms.create({ ...player(1), gameId: 'memory' });
  rooms.join({ ...player(2), code: created.code });
  assert.throws(() => rooms.start(created.id, player(2).playerId),
    (error) => error instanceof RoomError && error.code === 'HOST_ONLY');
  assert.throws(() => rooms.start(created.id, player(1).playerId),
    (error) => error.code === 'PLAYERS_NOT_READY');
  rooms.setReady(created.id, player(2).playerId, true);
  assert.equal(rooms.start(created.id, player(1).playerId).status, 'playing');
});

test('disconnect marks player offline and allows same identity to reconnect', () => {
  const rooms = new RoomManager();
  const created = rooms.create({ ...player(1), gameId: 'memory' });
  rooms.join({ ...player(2), code: created.code, socketId: 'socket-old' });
  const disconnected = rooms.disconnect('socket-old');
  assert.equal(disconnected.members.find((m) => m.playerId === player(2).playerId).connected, false);
  const rejoined = rooms.join({ ...player(2), code: created.code, socketId: 'socket-new' });
  assert.equal(rejoined.members.find((m) => m.playerId === player(2).playerId).connected, true);
});

test('transfers host when host leaves and deletes empty room', () => {
  const rooms = new RoomManager();
  const created = rooms.create({ ...player(1), gameId: 'ludo' });
  rooms.join({ ...player(2), code: created.code });
  const updated = rooms.leave(created.id, player(1).playerId);
  assert.equal(updated.hostId, player(2).playerId);
  assert.equal(rooms.leave(created.id, player(2).playerId), null);
});

test('validates game identifiers, player identity and capacity', () => {
  const rooms = new RoomManager();
  assert.throws(() => rooms.create({ ...player(1), gameId: 'Bad Game' }), /valid game/);
  assert.throws(() => rooms.create({ playerId: 'x', displayName: 'A', gameId: 'ludo' }),
    (error) => error.code === 'INVALID_PLAYER');
  assert.throws(() => rooms.create({ ...player(1), gameId: 'ludo', maxMembers: 50 }),
    (error) => error.code === 'INVALID_CAPACITY');
});

test('expires disconnected members after reconnect grace', () => {
  let now = 1000;
  const rooms = new RoomManager({ reconnectGraceMs: 500, now: () => now });
  const created = rooms.create({ ...player(1), gameId: 'ludo' });
  rooms.join({ ...player(2), code: created.code, socketId: 'socket-2' });
  rooms.disconnect('socket-2');
  now = 1600;
  assert.equal(rooms.sweepExpired().length, 1);
  assert.equal(rooms.getByCode(created.code).members.length, 1);
});
