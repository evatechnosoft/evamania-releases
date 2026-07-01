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
#include <TinyGPSPlus.h>
#include "config.h"
#include "can_bus.h"

// --- GPS ---
TinyGPSPlus gps;
HardwareSerial GPSSerial(2);
bool canReady = false;

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
  String fault = "";
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

// --- Sensör okuma: önce gerçek CAN/GPS; veri yoksa simülasyona düş ---
void readSensors() {
  bool realSpeed = false, realBattery = false;

  // 1) CAN'den hız/batarya (varsa).
  if (canReady) {
    CanData c;
    if (canPoll(c)) {
      if (c.haveSpeed) { veh.speedKph = c.speedKph; realSpeed = true; }
      if (c.haveBattery) { veh.batteryPct = c.batteryPct; veh.voltage = c.voltage; realBattery = true; }
      if (c.fault) veh.fault = String(c.fault);
    }
  }

  // 2) CAN yoksa batarya için ADC (gerilim bölücü).
  if (!realBattery) {
    int raw = analogRead(PIN_VBAT_ADC);
    float v = (raw / 4095.0f) * 3.3f * VBAT_SCALE;
    if (v > 5.0f) {
      veh.voltage = v;
      veh.batteryPct = constrain((v - 54.0f) / (67.2f - 54.0f) * 100.0f, 0.0f, 100.0f);
      realBattery = true;
    }
  }

  // 3) Hız gerçek değilse simüle et (immobilize ise 0).
  static float t = 0; t += 0.2f;
  if (!realSpeed) {
    veh.speedKph = veh.immobilized ? 0 : max(0.0f, 25.0f + 15.0f * sinf(t / 5.0f));
  } else if (veh.immobilized) {
    veh.speedKph = 0;
  }
  veh.odometerKm += veh.speedKph / 3600.0f * (TELEMETRY_PERIOD_MS / 1000.0f);

  // 4) Konum: gerçek GPS fix'i varsa kullan; yoksa son bilinen konumu koru.
  while (GPSSerial.available()) gps.encode(GPSSerial.read());
  if (gps.location.isValid() && gps.location.age() < 5000) {
    veh.lat = gps.location.lat();
    veh.lng = gps.location.lng();
  }
}

// --- Telemetri gönder ---
void sendTelemetry() {
  if (WiFi.status() != WL_CONNECTED) return;
  HTTPClient http;
  http.begin(String(BACKEND_URL) + "/api/telemetry");
  http.addHeader("Content-Type", "application/json");
  http.addHeader("X-Device-Token", DEVICE_TOKEN);

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
  if (veh.fault.length()) doc["fault"] = veh.fault;

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
  http.addHeader("X-Device-Token", DEVICE_TOKEN);
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

  // GPS UART başlat.
  GPSSerial.begin(GPS_BAUD, SERIAL_8N1, PIN_GPS_RX, PIN_GPS_TX);

  // CAN/TWAI başlat (başarısızsa simülasyon/ADC ile devam).
  canReady = canBegin();
  Serial.println(canReady ? "CAN başlatıldı" : "CAN yok — ADC/simülasyon ile devam");

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
