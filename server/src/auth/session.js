'use strict';
const crypto = require('node:crypto');
function createSessionService({ secret, ttlSeconds = 2592000, now = () => Date.now() } = {}) {
  if (!secret || Buffer.byteLength(secret) < 32) throw new Error('SESSION_SECRET must contain at least 32 bytes.');
  const sign = (value) => crypto.createHmac('sha256', secret).update(value).digest('base64url');
  function issue({ playerId, displayName }) {
    const payload = Buffer.from(JSON.stringify({ sub: playerId, name: displayName,
      iat: Math.floor(now() / 1000), exp: Math.floor(now() / 1000) + ttlSeconds })).toString('base64url');
    return payload + '.' + sign(payload);
  }
  function verify(token) {
    if (typeof token !== 'string' || token.length > 2048) return null;
    const parts = token.split('.');
    if (parts.length !== 2) return null;
    const expected = Buffer.from(sign(parts[0]));
    const actual = Buffer.from(parts[1]);
    if (expected.length !== actual.length || !crypto.timingSafeEqual(expected, actual)) return null;
    try {
      const data = JSON.parse(Buffer.from(parts[0], 'base64url').toString('utf8'));
      if (!data.sub || !data.name || data.exp <= Math.floor(now() / 1000)) return null;
      return { playerId: data.sub, displayName: data.name };
    } catch { return null; }
  }
  return { issue, verify };
}
module.exports = { createSessionService };
