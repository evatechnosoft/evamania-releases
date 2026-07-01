// EvaISYS — donanımsız uçtan uca test için sahte araç simülatörü.
// Backend'e periyodik telemetri gönderir ve bekleyen komutları çekip durumunu günceller.
//
// Kullanım:  node backend/sim/vehicle-sim.js  [vehicleId] [backendUrl]

const VEHICLE_ID = process.argv[2] || 'EVA-001';
const BASE = process.argv[3] || 'http://localhost:3000';
const PERIOD_MS = 2000;

// İstanbul çevresinde küçük bir tur atan sahte konum.
let t = 0;
const state = {
  vehicleId: VEHICLE_ID,
  speedKph: 0,
  batteryPct: 92,
  voltage: 60.8,
  odometerKm: 1200,
  lat: 41.0082,
  lng: 28.9784,
  locked: true,
  immobilized: false,
  alarm: false,
  fault: null,
};

function step() {
  t += 1;
  // Hareket simülasyonu (immobilize değilse).
  if (!state.immobilized) {
    state.speedKph = Math.max(0, 25 + 15 * Math.sin(t / 5));
  } else {
    state.speedKph = 0;
  }
  state.lat += 0.0002 * Math.cos(t / 8);
  state.lng += 0.0002 * Math.sin(t / 8);
  state.odometerKm += state.speedKph / 3600 * (PERIOD_MS / 1000);
  state.batteryPct = Math.max(0, state.batteryPct - 0.05);
  state.voltage = 54 + state.batteryPct * 0.07;
  state.ts = Math.floor(Date.now() / 1000);
}

async function applyCommands() {
  try {
    const res = await fetch(`${BASE}/api/vehicles/${VEHICLE_ID}/commands`);
    const cmds = await res.json();
    for (const c of cmds) {
      if (c.type === 'lock') state.locked = !!c.value;
      if (c.type === 'immobilize') state.immobilized = !!c.value;
      if (c.type === 'alarm') state.alarm = !!c.value;
      if (c.type === 'locate') console.log(`[${VEHICLE_ID}] konum istendi -> ${state.lat.toFixed(5)},${state.lng.toFixed(5)}`);
      if (c.type) console.log(`[${VEHICLE_ID}] komut uygulandı: ${c.type}=${c.value}`);
    }
  } catch (e) {
    // Backend hazır değilse sessiz geç.
  }
}

async function sendTelemetry() {
  try {
    await fetch(`${BASE}/api/telemetry`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(state),
    });
  } catch (e) {
    console.error('telemetri gönderilemedi:', e.message);
  }
}

console.log(`Simülatör başladı: ${VEHICLE_ID} -> ${BASE} (her ${PERIOD_MS}ms)`);
async function loop() {
  step();
  await applyCommands();
  await sendTelemetry();
}
loop();
setInterval(loop, PERIOD_MS);
