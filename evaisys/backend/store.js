// EvaISYS — bellek içi durum deposu (MVP).
// Üretimde bir veritabanı (PostgreSQL/TimescaleDB) ile değiştirin.

const ONLINE_WINDOW_MS = 15_000;

/** vehicleId -> { ...telemetri, lastSeen } */
const vehicles = new Map();
/** vehicleId -> [ {type, value, ts} ] bekleyen komutlar */
const commandQueues = new Map();

function now() {
  return Date.now();
}

/** Telemetriyi birleştir (verilmeyen alanlar korunur) ve durumu döndür. */
export function ingestTelemetry(payload) {
  const id = payload.vehicleId;
  if (!id) throw new Error('vehicleId zorunlu');

  const prev = vehicles.get(id) || { vehicleId: id };
  const merged = { ...prev };

  // Yalnızca gelen (undefined olmayan) alanları uygula.
  for (const [k, v] of Object.entries(payload)) {
    if (v !== undefined && v !== null) merged[k] = v;
  }
  merged.vehicleId = id;
  merged.ts = payload.ts ?? Math.floor(now() / 1000);
  merged.lastSeen = now();

  vehicles.set(id, merged);
  return toPublic(merged);
}

function toPublic(v) {
  const online = now() - (v.lastSeen ?? 0) < ONLINE_WINDOW_MS;
  const { lastSeen, ...rest } = v;
  return { ...rest, online, lastSeen: Math.floor((lastSeen ?? 0) / 1000) };
}

export function listVehicles() {
  return [...vehicles.values()].map(toPublic);
}

export function getVehicle(id) {
  const v = vehicles.get(id);
  return v ? toPublic(v) : null;
}

/** Komutu araç kuyruğuna ekle. */
export function enqueueCommand(id, cmd) {
  if (!vehicles.has(id)) vehicles.set(id, { vehicleId: id });
  const q = commandQueues.get(id) || [];
  const entry = { type: cmd.type, value: cmd.value ?? null, ts: Math.floor(now() / 1000) };
  q.push(entry);
  commandQueues.set(id, q);
  return entry;
}

/** Bekleyen komutları döndür ve kuyruğu temizle (ESP32 çekişi). */
export function drainCommands(id) {
  const q = commandQueues.get(id) || [];
  commandQueues.set(id, []);
  return q;
}
