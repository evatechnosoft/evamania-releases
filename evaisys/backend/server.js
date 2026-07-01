// EvaISYS — MVP backend sunucusu
// REST (telemetri alımı, araç sorgu, komut) + WebSocket (gerçek zamanlı yayın) + statik web panel.

import express from 'express';
import http from 'node:http';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { WebSocketServer } from 'ws';
import {
  ingestTelemetry,
  listVehicles,
  getVehicle,
  enqueueCommand,
  drainCommands,
} from './store.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const PORT = process.env.PORT || 3000;

const app = express();
app.use(express.json());

// --- Gerçek zamanlı yayın altyapısı ---
const server = http.createServer(app);
const wss = new WebSocketServer({ server, path: '/ws' });

function broadcast(event, data) {
  const msg = JSON.stringify({ event, data });
  for (const client of wss.clients) {
    if (client.readyState === 1) client.send(msg);
  }
}

wss.on('connection', (ws) => {
  // Yeni bağlanan istemciye mevcut durumu gönder.
  ws.send(JSON.stringify({ event: 'snapshot', data: listVehicles() }));
});

// --- REST API ---

// ESP32 -> telemetri gönderir
app.post('/api/telemetry', (req, res) => {
  try {
    const state = ingestTelemetry(req.body || {});
    broadcast('telemetry', state);
    res.json({ ok: true, state });
  } catch (err) {
    res.status(400).json({ ok: false, error: err.message });
  }
});

// Web/App -> araç listesi
app.get('/api/vehicles', (_req, res) => {
  res.json(listVehicles());
});

// Web/App -> tek araç
app.get('/api/vehicles/:id', (req, res) => {
  const v = getVehicle(req.params.id);
  if (!v) return res.status(404).json({ ok: false, error: 'araç bulunamadı' });
  res.json(v);
});

// Web/App -> uzaktan komut gönderir
app.post('/api/vehicles/:id/command', (req, res) => {
  const { type, value } = req.body || {};
  const allowed = ['lock', 'immobilize', 'alarm', 'locate'];
  if (!allowed.includes(type)) {
    return res.status(400).json({ ok: false, error: `geçersiz komut: ${type}` });
  }
  const entry = enqueueCommand(req.params.id, { type, value });
  broadcast('command', { vehicleId: req.params.id, ...entry });
  res.json({ ok: true, command: entry });
});

// ESP32 -> bekleyen komutları çeker
app.get('/api/vehicles/:id/commands', (req, res) => {
  res.json(drainCommands(req.params.id));
});

// Basit sağlık kontrolü
app.get('/api/health', (_req, res) => res.json({ ok: true, uptime: process.uptime() }));

// --- Statik web panel ---
app.use('/', express.static(path.join(__dirname, '..', 'web')));

server.listen(PORT, () => {
  console.log(`EvaISYS backend çalışıyor:  http://localhost:${PORT}`);
  console.log(`  Web panel:   http://localhost:${PORT}`);
  console.log(`  WebSocket:   ws://localhost:${PORT}/ws`);
});
