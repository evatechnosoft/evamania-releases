// EvaISYS — ESP32 VCU düğümü (MVP firmware)
// Görev:
//   1) WiFi'ye bağlan
//   2) Araç telemetrisini (hız/batarya/konum/durum) periyodik olarak backend'e POST et
//   3) Backend'den bekleyen uzaktan komutları çek ve uygula:
//        - lock/unlock (kilit rölesi)
//        - immobilize (motor kesme rölesi)  -> anti-hırsızlık otomasyonu
//        - alarm (buzzer)
//        - locate (kısa beep + anlık konum)
//
// Not: Hız ve GPS için gerçek sensör bağlanana kadar basit üretim/placeholder kullanılır.
//      Gerçek CAN entegrasyonunda hız/batarya kontrolcü/BMS mesajlarından okunmalıdır.

#include <Arduino.h>
#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include "config.h"

// --- Araç durumu ---
struct VehicleState {
  float speedKph = 0;
  float batteryPct = 90;
  float voltage = 60.0;
  float odometerKm = 1200;
  double lat = 41.0082;
  double lng = 28.9784;
  bool locked = true;
  bool immobilized = false;
  bool alarm = false;
} veh;

unsigned long lastCycle = 0;
unsigned long alarmToggle = 0;

// --- WiFi ---
void connectWiFi() {
  if (WiFi.status() == WL_CONNECTED) return;
  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASS);
  Serial.print("WiFi bağlanıyor");
  uint8_t tries = 0;
  while (WiFi.status() != WL_CONNECTED && tries++ < 40) {
    delay(250);
    Serial.print(".");
  }
  Serial.println(WiFi.status() == WL_CONNECTED ? " bağlandı" : " BAŞARISIZ");
}

// --- Röle/aktüatör uygula ---
void applyOutputs() {
  digitalWrite(PIN_IMMOBILIZER, veh.immobilized ? HIGH : LOW);
  digitalWrite(PIN_LOCK, veh.locked ? HIGH : LOW);
  // Alarm aktifse buzzer'ı kes-çal (non-blocking).
  if (veh.alarm) {
    if (millis() - alarmToggle > 400) {
      alarmToggle = millis();
      digitalWrite(PIN_BUZZER, !digitalRead(PIN_BUZZER));
    }
  } else {
    digitalWrite(PIN_BUZZER, LOW);
  }
}

// --- Sensör okuma (MVP: batarya ADC gerçek, hız/konum simüle) ---
void readSensors() {
  // Batarya voltajı (gerilim bölücü). Gerçek donanımda kalibre edin.
  int raw = analogRead(PIN_VBAT_ADC);
  float v = (raw / 4095.0f) * 3.3f * VBAT_SCALE;
  if (v > 5.0f) {  // makul okuma varsa kullan
    veh.voltage = v;
    veh.batteryPct = constrain((v - 54.0f) / (67.2f - 54.0f) * 100.0f, 0.0f, 100.0f);
  }
  // Hız: immobilize ise 0, değilse hafif dalga (gerçekte CAN'den okunur).
  static float t = 0; t += 0.2f;
  veh.speedKph = veh.immobilized ? 0 : max(0.0f, 25.0f + 15.0f * sinf(t / 5.0f));
  veh.odometerKm += veh.speedKph / 3600.0f * (TELEMETRY_PERIOD_MS / 1000.0f);
  // Konum: gerçek GPS bağlanınca TinyGPS++ ile doldurun; şimdilik hafif drift.
  veh.lat += 0.0002 * cos(t / 8.0);
  veh.lng += 0.0002 * sin(t / 8.0);
}

// --- Telemetri gönder ---
void sendTelemetry() {
  if (WiFi.status() != WL_CONNECTED) return;
  HTTPClient http;
  http.begin(String(BACKEND_URL) + "/api/telemetry");
  http.addHeader("Content-Type", "application/json");

  JsonDocument doc;
  doc["vehicleId"]  = VEHICLE_ID;
  doc["speedKph"]   = veh.speedKph;
  doc["batteryPct"] = veh.batteryPct;
  doc["voltage"]    = veh.voltage;
  doc["odometerKm"] = veh.odometerKm;
  doc["lat"]        = veh.lat;
  doc["lng"]        = veh.lng;
  doc["locked"]     = veh.locked;
  doc["immobilized"]= veh.immobilized;
  doc["alarm"]      = veh.alarm;

  String body;
  serializeJson(doc, body);
  int code = http.POST(body);
  Serial.printf("telemetri -> %d\n", code);
  http.end();
}

// --- Komutları çek ve uygula ---
void pollCommands() {
  if (WiFi.status() != WL_CONNECTED) return;
  HTTPClient http;
  http.begin(String(BACKEND_URL) + "/api/vehicles/" + VEHICLE_ID + "/commands");
  int code = http.GET();
  if (code == 200) {
    JsonDocument doc;
    if (deserializeJson(doc, http.getString()) == DeserializationError::Ok) {
      for (JsonObject cmd : doc.as<JsonArray>()) {
        const char* type = cmd["type"];
        bool val = cmd["value"].as<bool>();
        if (!type) continue;
        if (!strcmp(type, "lock")) veh.locked = val;
        else if (!strcmp(type, "immobilize")) veh.immobilized = val;
        else if (!strcmp(type, "alarm")) veh.alarm = val;
        else if (!strcmp(type, "locate")) {
          digitalWrite(PIN_BUZZER, HIGH); delay(120); digitalWrite(PIN_BUZZER, LOW);
        }
        Serial.printf("komut: %s = %d\n", type, val);
      }
    }
  }
  http.end();
}

void setup() {
  Serial.begin(115200);
  pinMode(PIN_IMMOBILIZER, OUTPUT);
  pinMode(PIN_LOCK, OUTPUT);
  pinMode(PIN_BUZZER, OUTPUT);
  analogReadResolution(12);
  applyOutputs();
  connectWiFi();
  Serial.println("EvaISYS ESP32 VCU hazır: " VEHICLE_ID);
}

void loop() {
  connectWiFi();
  applyOutputs();  // buzzer için sık çağrılır (non-blocking)

  if (millis() - lastCycle >= TELEMETRY_PERIOD_MS) {
    lastCycle = millis();
    readSensors();
    pollCommands();   // önce komutları al (durum güncellensin)
    applyOutputs();
    sendTelemetry();  // sonra güncel durumu bildir
  }
  delay(20);
}
