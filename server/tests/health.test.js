'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { app } = require('../src/index');

test('health endpoint identifies the independent service', async () => {
  const server = app.listen(0);
  try {
    const address = server.address();
    const response = await fetch(`http://127.0.0.1:${address.port}/health`);
    assert.equal(response.status, 200);
    assert.deepEqual(await response.json(), {
      ok: true,
      service: 'rivalrooms-latest-api',
      version: '0.3.0'
    });
  } finally {
    await new Promise((resolve) => server.close(resolve));
  }
});
