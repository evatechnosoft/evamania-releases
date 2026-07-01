// EvaISYS — MVP backend sunucusu (auth + SQLite + realtime)
// REST + WebSocket (gerçek zamanlı yayın) + statik web panel.

import express from 'express';
import http from 'node:http';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { WebSocketServer } from 'ws';
import {
  ingestTelemetry,
  listVehicles,
  getVehicle,
  getHistory,
  enqueueCommand,
  drainCommands,
} from './store.js';
import { login, requireUser, requireDevice, verifyUserToken } from './auth.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const PORT = process.env.PORT || 3000;

const app = express();
app.use(express.json());

// --- Gerçek zamanlı yayın ---
const server = http.createServer(app);
const wss = new WebSocketServer({ server, path: '/ws' });

function broadcast(event, data) {
  const msg = JSON.stringify({ event, data });
  for (const client of wss.clients) {
    if (client.readyState === 1) client.send(msg);
  }
}

// WebSocket: bağlantıda ?token=<JWT> ister.
wss.on('connection', (ws, req) => {
  const url = new URL(req.url, 'http://localhost');
  const token = url.searchParams.get('token');
  if (!verifyUserToken(token)) {
    ws.close(4001, 'yetkisiz');
    return;
  }
  ws.send(JSON.stringify({ event: 'snapshot', data: listVehicles() }));
});

// --- Kimlik ---
app.post('/api/auth/login', (req, res) => {
  const { username, password } = req.body || {};
  const result = login(username || '', password || '');
  if (!result) return res.status(401).json({ ok: false, error: 'kullanıcı adı veya parola hatalı' });
  res.json({ ok: true, ...result });
});

// --- Cihaz uçları (ESP32) — cihaz token ile korunur ---

// Telemetri gönderme; token'ın aracı ile gönderilen vehicleId eşleşmeli.
app.post('/api/telemetry', requireDevice, (req, res) => {
  try {
    const body = req.body || {};
    if (body.vehicleId && body.vehicleId !== req.deviceVehicleId) {
      return res.status(403).json({ ok: false, error: 'vehicleId cihaz token ile eşleşmiyor' });
    }
    body.vehicleId = req.deviceVehicleId;
    const state = ingestTelemetry(body);
    broadcast('telemetry', state);
    res.json({ ok: true, state });
  } catch (err) {
    res.status(400).json({ ok: false, error: err.message });
  }
});

// Bekleyen komutları çekme.
app.get('/api/vehicles/:id/commands', requireDevice, (req, res) => {
  if (req.params.id !== req.deviceVehicleId) {
    return res.status(403).json({ ok: false, error: 'yetkisiz araç' });
  }
  res.json(drainCommands(req.params.id));
});

// --- Kullanıcı uçları — JWT ile korunur ---
app.get('/api/vehicles', requireUser, (_req, res) => res.json(listVehicles()));

app.get('/api/vehicles/:id', requireUser, (req, res) => {
  const v = getVehicle(req.params.id);
  if (!v) return res.status(404).json({ ok: false, error: 'araç bulunamadı' });
  res.json(v);
});

app.get('/api/vehicles/:id/history', requireUser, (req, res) => {
  const limit = Math.min(parseInt(req.query.limit) || 100, 1000);
  res.json(getHistory(req.params.id, limit));
});

app.post('/api/vehicles/:id/command', requireUser, (req, res) => {
  const { type, value } = req.body || {};
  const allowed = ['lock', 'immobilize', 'alarm', 'locate'];
  if (!allowed.includes(type)) {
    return res.status(400).json({ ok: false, error: `geçersiz komut: ${type}` });
  }
  const entry = enqueueCommand(req.params.id, { type, value });
  broadcast('command', { vehicleId: req.params.id, ...entry });
  res.json({ ok: true, command: entry });
});

// Sağlık kontrolü (açık)
app.get('/api/health', (_req, res) => res.json({ ok: true, uptime: process.uptime() }));

// --- Statik web panel ---
app.use('/', express.static(path.join(__dirname, '..', 'web')));

server.listen(PORT, () => {
  console.log(`EvaISYS backend çalışıyor:  http://localhost:${PORT}`);
});
