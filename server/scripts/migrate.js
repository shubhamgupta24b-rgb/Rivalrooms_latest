'use strict';
const fs = require('node:fs');
const path = require('node:path');
const { Pool } = require('pg');
async function main() {
  if (!process.env.DATABASE_URL) throw new Error('DATABASE_URL is required to run migrations.');
  const pool = new Pool({ connectionString: process.env.DATABASE_URL,
    ssl: process.env.DATABASE_SSL === 'false' ? false : { rejectUnauthorized: false } });
  try {
    const sql = fs.readFileSync(path.join(__dirname, '../migrations/001_initial.sql'), 'utf8');
    await pool.query(sql);
    process.stdout.write('Database schema is up to date.\n');
  } finally { await pool.end(); }
}
main().catch((error) => { process.stderr.write(error.message + '\n'); process.exitCode = 1; });
