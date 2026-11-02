'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const { app } = require('../src/index');

test('issues a signed guest session and protects room routes', async () => {
  const server = app.listen(0);
  const base = () => `http://127.0.0.1:${server.address().port}`;
  try {
    const denied = await fetch(base() + '/v1/rooms', { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify({ gameId: 'memory' }) });
    assert.equal(denied.status, 401);
    const bad = await fetch(base() + '/v1/sessions', { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify({ deviceId: 'x', displayName: 'Test' }) });
    assert.equal(bad.status, 400);
    const issued = await fetch(base() + '/v1/sessions', { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify({ deviceId: 'device_test_123', displayName: 'Tester' }) });
    assert.equal(issued.status, 503);
    const invalid = await fetch(base() + '/v1/rooms', { method: 'POST', headers: { authorization: 'Bearer invalid', 'content-type': 'application/json' }, body: JSON.stringify({ gameId: 'memory' }) });
    assert.equal(invalid.status, 401);
  } finally {
    await new Promise((resolve) => server.close(resolve));
  }
});
