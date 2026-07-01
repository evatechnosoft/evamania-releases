// EvaISYS web panel — WebSocket ile canlı telemetri, Leaflet harita, uzaktan komut.

const API = location.origin;
const WS_BASE = (location.protocol === 'https:' ? 'wss://' : 'ws://') + location.host + '/ws';

const vehicles = new Map(); // id -> state
const markers = new Map();  // id -> Leaflet marker

const statusEl = document.getElementById('status');
const cardsEl = document.getElementById('cards');
const countEl = document.getElementById('count');
const loginEl = document.getElementById('login');
const loginForm = document.getElementById('login-form');
const loginError = document.getElementById('login-error');

// --- Kimlik (JWT localStorage'da) ---
let token = localStorage.getItem('evaisys_token');

function authHeaders() {
  return token ? { Authorization: `Bearer ${token}` } : {};
}

function showLogin(show) {
  loginEl.classList.toggle('hidden', !show);
}

async function doLogin(username, password) {
  const res = await fetch(`${API}/api/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username, password }),
  });
  if (!res.ok) throw new Error('kullanıcı adı veya parola hatalı');
  const data = await res.json();
  token = data.token;
  localStorage.setItem('evaisys_token', token);
}

function logout() {
  token = null;
  localStorage.removeItem('evaisys_token');
  vehicles.clear();
  render();
  showLogin(true);
}

loginForm.addEventListener('submit', async (e) => {
  e.preventDefault();
  loginError.textContent = '';
  try {
    await doLogin(document.getElementById('username').value, document.getElementById('password').value);
    showLogin(false);
    start();
  } catch (err) {
    loginError.textContent = err.message;
  }
});
document.getElementById('logout').addEventListener('click', logout);

// --- Harita ---
const map = L.map('map').setView([41.0082, 28.9784], 13);
L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
  attribution: '© OpenStreetMap',
}).addTo(map);

function upsertMarker(v) {
  if (v.lat == null || v.lng == null) return;
  if (markers.has(v.vehicleId)) {
    markers.get(v.vehicleId).setLatLng([v.lat, v.lng]);
  } else {
    const m = L.marker([v.lat, v.lng]).addTo(map);
    m.bindPopup(v.vehicleId);
    markers.set(v.vehicleId, m);
  }
}

// --- Komut gönderme ---
async function sendCommand(id, type, value) {
  try {
    const res = await fetch(`${API}/api/vehicles/${id}/command`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', ...authHeaders() },
      body: JSON.stringify({ type, value }),
    });
    if (res.status === 401) return logout();
  } catch (e) {
    alert('Komut gönderilemedi: ' + e.message);
  }
}

// --- Kart render ---
function num(x, d = 0) { return x == null ? '—' : Number(x).toFixed(d); }

function render() {
  countEl.textContent = vehicles.size;
  const list = [...vehicles.values()].sort((a, b) => a.vehicleId.localeCompare(b.vehicleId));
  cardsEl.innerHTML = '';
  for (const v of list) {
    const card = document.createElement('div');
    card.className = 'card' + (v.online ? '' : ' offline');
    card.innerHTML = `
      <div class="row">
        <span class="id"><span class="dot ${v.online ? 'on' : 'off'}"></span>${v.vehicleId}</span>
        <span class="badge ${v.online ? 'good' : ''}">${v.online ? 'çevrimiçi' : 'çevrimdışı'}</span>
      </div>
      <div class="metrics">
        <div class="metric"><div class="v">${num(v.speedKph)}</div><div class="l">km/s</div></div>
        <div class="metric"><div class="v">${num(v.batteryPct)}%</div><div class="l">batarya</div></div>
        <div class="metric"><div class="v">${num(v.odometerKm, 1)}</div><div class="l">km</div></div>
      </div>
      <div class="badges">
        <span class="badge ${v.locked ? 'good' : 'warn'}">${v.locked ? '🔒 kilitli' : '🔓 açık'}</span>
        <span class="badge ${v.immobilized ? 'warn' : ''}">${v.immobilized ? '⛔ immobilize' : 'motor serbest'}</span>
        <span class="badge ${v.alarm ? 'warn' : ''}">${v.alarm ? '🚨 alarm' : 'alarm kapalı'}</span>
        ${v.fault ? `<span class="badge warn">arıza: ${v.fault}</span>` : ''}
      </div>
      <div class="controls">
        <button class="${v.locked ? 'active' : ''}" data-cmd="lock" data-val="${!v.locked}">${v.locked ? 'Kilidi Aç' : 'Kilitle'}</button>
        <button class="${v.immobilized ? 'danger' : ''}" data-cmd="immobilize" data-val="${!v.immobilized}">${v.immobilized ? 'Serbest Bırak' : 'Immobilize'}</button>
        <button class="${v.alarm ? 'danger' : ''}" data-cmd="alarm" data-val="${!v.alarm}">${v.alarm ? 'Alarmı Kapat' : 'Alarm'}</button>
        <button class="primary" data-cmd="locate">Konum</button>
      </div>`;
    card.querySelectorAll('button').forEach((btn) => {
      btn.addEventListener('click', () => {
        const val = btn.dataset.val;
        sendCommand(v.vehicleId, btn.dataset.cmd, val === undefined ? null : val === 'true');
        if (btn.dataset.cmd === 'locate' && markers.has(v.vehicleId)) {
          map.setView(markers.get(v.vehicleId).getLatLng(), 15);
          markers.get(v.vehicleId).openPopup();
        }
      });
    });
    cardsEl.appendChild(card);
  }
}

function applyState(v) {
  vehicles.set(v.vehicleId, v);
  upsertMarker(v);
  render();
}

// --- WebSocket ---
let ws = null;
function connect() {
  if (!token) return;
  ws = new WebSocket(`${WS_BASE}?token=${encodeURIComponent(token)}`);
  ws.onopen = () => { statusEl.textContent = 'canlı'; statusEl.className = 'status ok'; };
  ws.onclose = (ev) => {
    statusEl.textContent = 'bağlantı koptu — yeniden deneniyor';
    statusEl.className = 'status err';
    if (ev.code === 4001) return logout(); // yetkisiz
    if (token) setTimeout(connect, 2000);
  };
  ws.onmessage = (ev) => {
    const msg = JSON.parse(ev.data);
    if (msg.event === 'snapshot') msg.data.forEach(applyState);
    else if (msg.event === 'telemetry') applyState(msg.data);
  };
}

// Oturum açıksa başlat: REST snapshot + WS canlı akış.
function start() {
  fetch(`${API}/api/vehicles`, { headers: authHeaders() })
    .then((r) => { if (r.status === 401) { logout(); throw new Error('yetkisiz'); } return r.json(); })
    .then((list) => list.forEach(applyState))
    .catch(() => {});
  connect();
}

if (token) { showLogin(false); start(); } else { showLogin(true); }
