'use strict';
const { Pool } = require('pg');

function createStorage({ connectionString = process.env.DATABASE_URL } = {}) {
  if (!connectionString) return { enabled: false, close: async () => {} };
  const pool = new Pool({
    connectionString,
    ssl: process.env.DATABASE_SSL === 'false' ? false : { rejectUnauthorized: false },
    max: Number(process.env.DB_POOL_SIZE || 5),
    idleTimeoutMillis: 30000,
    connectionTimeoutMillis: 5000
  });
  return {
    enabled: true,
    async upsertProfile({ playerId, displayName }) {
      await pool.query(
        `INSERT INTO player_profiles (player_id, display_name)
         VALUES ($1, $2)
         ON CONFLICT (player_id) DO UPDATE
         SET display_name = EXCLUDED.display_name, updated_at = NOW()`,
        [playerId, displayName]
      );
    },
    async getLeaderboard(gameId, limit = 50) {
      const result = await pool.query(
        `SELECT p.player_id AS "playerId", p.display_name AS "displayName",
                MAX(l.score)::bigint AS score
         FROM leaderboard_entries l
         JOIN player_profiles p ON p.player_id = l.player_id
         WHERE l.game_id = $1
         GROUP BY p.player_id, p.display_name
         ORDER BY score DESC, MIN(l.created_at) ASC
         LIMIT $2`,
        [gameId, Math.min(Math.max(Number(limit) || 50, 1), 100)]
      );
      return result.rows;
    },
    async ping() { await pool.query('SELECT 1'); },
    close: () => pool.end()
  };
}
module.exports = { createStorage };
