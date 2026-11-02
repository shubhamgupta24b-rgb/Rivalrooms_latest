'use strict';
const fs = require('node:fs');
const path = require('node:path');
const { Pool } = require('pg');
async function main() {
  if (!process.env.DATABASE_URL) throw new Error('DATABASE_URL is required to run migrations.');
  const pool = new Pool({ connectionString: process.env.DATABASE_URL,
    ssl: process.env.DATABASE_SSL === 'false' ? false : { rejectUnauthorized: false } });
  try {
    const directory = path.join(__dirname, '../migrations');
    for (const file of fs.readdirSync(directory).filter((name) => name.endsWith('.sql')).sort()) {
      await pool.query(fs.readFileSync(path.join(directory, file), 'utf8'));
      process.stdout.write(`Applied ${file}\n`);
    }
  } finally { await pool.end(); }
}
main().catch((error) => { process.stderr.write(error.message + '\n'); process.exitCode = 1; });
