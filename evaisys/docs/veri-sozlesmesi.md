# EvaISYS — Ortak Veri Sözleşmesi (JSON)

Tüm bileşenler (ESP32, Backend, Web, Flutter) bu sözleşmeyi kullanır. MVP; alanlar geriye dönük
uyumlu şekilde genişletilebilir.

## Telemetri (ESP32 → Backend)

`POST /api/telemetry`

```json
{
  "vehicleId": "EVA-001",
  "ts": 1719840000,
  "speedKph": 32.5,
  "batteryPct": 78,
  "voltage": 60.2,
  "odometerKm": 1234.6,
  "lat": 41.0082,
  "lng": 28.9784,
  "locked": true,
  "immobilized": false,
  "alarm": false,
  "fault": null
}
```

- `vehicleId` (zorunlu): araç/cihaz kimliği.
- `ts`: unix saniye (gönderilmezse backend zaman damgası atar).
- Diğer alanlar opsiyonel; gönderilmeyen alanlar bir önceki değeri korur.

## Araç durumu (Backend → Web/Flutter)

`GET /api/vehicles` → dizi, `GET /api/vehicles/:id` → tek nesne. Telemetri alanlarına ek olarak:

```json
{
  "vehicleId": "EVA-001",
  "online": true,
  "lastSeen": 1719840003,
  "...": "telemetri alanları"
}
```

`online`: son telemetriden bu yana < 15 sn ise `true`.

## Komut (Web/Flutter → Backend → ESP32)

Gönderme: `POST /api/vehicles/:id/command`

```json
{ "type": "lock", "value": true }
```

Desteklenen `type` değerleri:

| type | value | Anlam |
|---|---|---|
| `lock` | `true`/`false` | Aracı kilitle / kilidini aç |
| `immobilize` | `true`/`false` | Motoru kilitle (immobilizer rölesi) |
| `alarm` | `true`/`false` | Sesli alarmı (buzzer) aç/kapat |
| `locate` | — | Anlık konum/beep isteği |

ESP32 çekme: `GET /api/vehicles/:id/commands` → bekleyen komut dizisi (çekince kuyruk temizlenir).

## WebSocket olayları (Backend → paneller)

`ws://<host>/ws` — JSON mesajlar:

```json
{ "event": "telemetry", "data": { "...araç durumu..." } }
{ "event": "command",   "data": { "vehicleId": "EVA-001", "type": "lock", "value": true } }
```
