// EvaISYS — veri erişim katmanı (SQLite üzerinden).
// Bellek içi sürümün yerini alır; arayüz geriye dönük uyumludur.

import db from './db.js';

const ONLINE_WINDOW_MS = 15_000;
const now = () => Date.now();
const b = (x) => (x ? 1 : 0);

// Telemetri sütun -> JSON alan eşlemesi
function rowToPublic(r) {
  if (!r) return null;
  const online = now() - (r.last_seen ?? 0) < ONLINE_WINDOW_MS;
  return {
    vehicleId: r.vehicle_id,
    speedKph: r.speed_kph,
    batteryPct: r.battery_pct,
    voltage: r.voltage,
    odometerKm: r.odometer_km,
    lat: r.lat,
    lng: r.lng,
    locked: !!r.locked,
    immobilized: !!r.immobilized,
    alarm: !!r.alarm,
    fault: r.fault ?? null,
    ts: r.ts,
    online,
    lastSeen: Math.floor((r.last_seen ?? 0) / 1000),
  };
}

const getRow = db.prepare('SELECT * FROM vehicles WHERE vehicle_id = ?');

/** Telemetriyi birleştir (verilmeyen alanlar korunur), kaydet, geçmişe ekle. */
export function ingestTelemetry(p) {
  const id = p.vehicleId;
  if (!id) throw new Error('vehicleId zorunlu');

  const prev = getRow.get(id) || {};
  const merged = {
    speed_kph: p.speedKph ?? prev.speed_kph ?? 0,
    battery_pct: p.batteryPct ?? prev.battery_pct ?? 0,
    voltage: p.voltage ?? prev.voltage ?? 0,
    odometer_km: p.odometerKm ?? prev.odometer_km ?? 0,
    lat: p.lat ?? prev.lat ?? null,
    lng: p.lng ?? prev.lng ?? null,
    locked: p.locked !== undefined ? b(p.locked) : prev.locked ?? 1,
    immobilized: p.immobilized !== undefined ? b(p.immobilized) : prev.immobilized ?? 0,
    alarm: p.alarm !== undefined ? b(p.alarm) : prev.alarm ?? 0,
    fault: p.fault ?? prev.fault ?? null,
    ts: p.ts ?? Math.floor(now() / 1000),
    last_seen: now(),
  };

  db.prepare(`
    INSERT INTO vehicles (vehicle_id, speed_kph, battery_pct, voltage, odometer_km, lat, lng, locked, immobilized, alarm, fault, ts, last_seen)
    VALUES (@vehicle_id, @speed_kph, @battery_pct, @voltage, @odometer_km, @lat, @lng, @locked, @immobilized, @alarm, @fault, @ts, @last_seen)
    ON CONFLICT(vehicle_id) DO UPDATE SET
      speed_kph=@speed_kph, battery_pct=@battery_pct, voltage=@voltage, odometer_km=@odometer_km,
      lat=@lat, lng=@lng, locked=@locked, immobilized=@immobilized, alarm=@alarm, fault=@fault,
      ts=@ts, last_seen=@last_seen
  `).run({ vehicle_id: id, ...merged });

  db.prepare(`
    INSERT INTO telemetry (vehicle_id, ts, speed_kph, battery_pct, voltage, odometer_km, lat, lng, locked, immobilized, alarm, fault)
    VALUES (@vehicle_id, @ts, @speed_kph, @battery_pct, @voltage, @odometer_km, @lat, @lng, @locked, @immobilized, @alarm, @fault)
  `).run({ vehicle_id: id, ...merged });

  return rowToPublic(getRow.get(id));
}

export function listVehicles() {
  return db.prepare('SELECT * FROM vehicles ORDER BY vehicle_id').all().map(rowToPublic);
}

export function getVehicle(id) {
  return rowToPublic(getRow.get(id));
}

/** Araç telemetri geçmişi (en yeni önce). */
export function getHistory(id, limit = 100) {
  return db
    .prepare('SELECT ts, speed_kph, battery_pct, voltage, lat, lng FROM telemetry WHERE vehicle_id = ? ORDER BY ts DESC LIMIT ?')
    .all(id, limit)
    .map((r) => ({
      ts: r.ts,
      speedKph: r.speed_kph,
      batteryPct: r.battery_pct,
      voltage: r.voltage,
      lat: r.lat,
      lng: r.lng,
    }));
}

/** Komutu kuyruğa ekle. */
export function enqueueCommand(id, cmd) {
  const entry = { type: cmd.type, value: cmd.value === null || cmd.value === undefined ? null : b(cmd.value), ts: Math.floor(now() / 1000) };
  const info = db
    .prepare('INSERT INTO commands (vehicle_id, type, value, ts, delivered) VALUES (?,?,?,?,0)')
    .run(id, entry.type, entry.value, entry.ts);
  return { id: info.lastInsertRowid, type: entry.type, value: entry.value === null ? null : !!entry.value, ts: entry.ts };
}

/** Bekleyen komutları döndür ve teslim edildi işaretle (ESP32 çekişi). */
export function drainCommands(id) {
  const rows = db.prepare('SELECT * FROM commands WHERE vehicle_id = ? AND delivered = 0 ORDER BY id').all(id);
  if (rows.length) {
    db.prepare('UPDATE commands SET delivered = 1 WHERE vehicle_id = ? AND delivered = 0').run(id);
  }
  return rows.map((r) => ({ type: r.type, value: r.value === null ? null : !!r.value, ts: r.ts }));
}

// --- Kimlik / cihaz erişimi ---
export function findUser(username) {
  return db.prepare('SELECT * FROM users WHERE username = ?').get(username);
}

export function deviceByToken(token) {
  return db.prepare('SELECT * FROM devices WHERE token = ?').get(token);
}
