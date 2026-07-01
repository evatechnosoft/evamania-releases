// EvaISYS — SQLite kalıcı veri katmanı (better-sqlite3).
// Şema + ilk kurulum tohumlaması (seed) burada yapılır.

import Database from 'better-sqlite3';
import bcrypt from 'bcryptjs';
import crypto from 'node:crypto';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const DB_PATH = process.env.DB_PATH || path.join(__dirname, 'evaisys.db');

const db = new Database(DB_PATH);
db.pragma('journal_mode = WAL');

db.exec(`
  CREATE TABLE IF NOT EXISTS users (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    username      TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    role          TEXT NOT NULL DEFAULT 'operator',
    created_at    INTEGER NOT NULL
  );

  CREATE TABLE IF NOT EXISTS devices (
    vehicle_id TEXT PRIMARY KEY,
    token      TEXT UNIQUE NOT NULL,
    created_at INTEGER NOT NULL
  );

  CREATE TABLE IF NOT EXISTS vehicles (
    vehicle_id  TEXT PRIMARY KEY,
    speed_kph   REAL DEFAULT 0,
    battery_pct REAL DEFAULT 0,
    voltage     REAL DEFAULT 0,
    odometer_km REAL DEFAULT 0,
    lat         REAL,
    lng         REAL,
    locked      INTEGER DEFAULT 1,
    immobilized INTEGER DEFAULT 0,
    alarm       INTEGER DEFAULT 0,
    fault       TEXT,
    ts          INTEGER,
    last_seen   INTEGER
  );

  CREATE TABLE IF NOT EXISTS telemetry (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    vehicle_id  TEXT NOT NULL,
    ts          INTEGER NOT NULL,
    speed_kph   REAL, battery_pct REAL, voltage REAL, odometer_km REAL,
    lat REAL, lng REAL,
    locked INTEGER, immobilized INTEGER, alarm INTEGER, fault TEXT
  );
  CREATE INDEX IF NOT EXISTS idx_telemetry_vehicle_ts ON telemetry(vehicle_id, ts);

  CREATE TABLE IF NOT EXISTS commands (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    vehicle_id TEXT NOT NULL,
    type       TEXT NOT NULL,
    value      INTEGER,
    ts         INTEGER NOT NULL,
    delivered  INTEGER NOT NULL DEFAULT 0
  );
  CREATE INDEX IF NOT EXISTS idx_commands_pending ON commands(vehicle_id, delivered);
`);

// --- İlk kurulum tohumlaması ---
function seed() {
  const now = Date.now();
  const userCount = db.prepare('SELECT COUNT(*) c FROM users').get().c;
  if (userCount === 0) {
    const hash = bcrypt.hashSync(process.env.ADMIN_PASS || 'admin123', 10);
    db.prepare(
      'INSERT INTO users (username, password_hash, role, created_at) VALUES (?,?,?,?)'
    ).run(process.env.ADMIN_USER || 'admin', hash, 'admin', now);
    console.log(`[seed] admin kullanıcısı oluşturuldu (kullanıcı: ${process.env.ADMIN_USER || 'admin'})`);
  }

  const devCount = db.prepare('SELECT COUNT(*) c FROM devices').get().c;
  if (devCount === 0) {
    // MVP için sabit/tahmin edilemez cihaz token'ları. Üretimde provisioning ile üretin.
    for (const id of ['EVA-001', 'EVA-002']) {
      const token = crypto.createHash('sha256').update(id + '|evaisys-seed').digest('hex').slice(0, 32);
      db.prepare('INSERT INTO devices (vehicle_id, token, created_at) VALUES (?,?,?)').run(id, token, now);
      console.log(`[seed] cihaz token'ı  ${id}: ${token}`);
    }
  }
}
seed();

export default db;
