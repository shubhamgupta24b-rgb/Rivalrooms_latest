'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const { app } = require('../src/index');

test('issues guest sessions and protects room routes without a database', async () => {
  const server = app.listen(0);
  const base = () => `http://127.0.0.1:${server.address().port}`;
  try {
    const denied = await fetch(base() + '/v1/rooms', {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ gameId: 'tic_tac_toe' }),
    });
    assert.equal(denied.status, 401);

    const bad = await fetch(base() + '/v1/sessions', {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ deviceId: 'x', displayName: 'Test' }),
    });
    assert.equal(bad.status, 400);

    const issued = await fetch(base() + '/v1/sessions', {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ deviceId: 'device_test_123', displayName: 'Tester' }),
    });
    assert.equal(issued.status, 201);
    const session = await issued.json();
    assert.equal(typeof session.token, 'string');
    assert.equal(session.player.playerId, 'device_test_123');

    const created = await fetch(base() + '/v1/rooms', {
      method: 'POST',
      headers: {
        authorization: 'Bearer ' + session.token,
        'content-type': 'application/json',
      },
      body: JSON.stringify({ gameId: 'tic_tac_toe', maxMembers: 2 }),
    });
    assert.equal(created.status, 201);
    const room = await created.json();
    assert.equal(room.room.members.length, 1);
    assert.equal(room.room.gameId, 'tic_tac_toe');

    const invalid = await fetch(base() + '/v1/rooms', {
      method: 'POST',
      headers: {
        authorization: 'Bearer invalid',
        'content-type': 'application/json',
      },
      body: JSON.stringify({ gameId: 'tic_tac_toe' }),
    });
    assert.equal(invalid.status, 401);
  } finally {
    await new Promise((resolve) => server.close(resolve));
  }
});
