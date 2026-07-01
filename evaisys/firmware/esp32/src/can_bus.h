#pragma once
// EvaISYS — ESP32 TWAI (CAN) okuma katmanı.
// Kontrolcü ve BMS'ten hız/batarya/voltaj verilerini çözer.
//
// NOT: CAN mesaj ID'leri ve byte düzeni araç/kontrolcü markasına göre değişir.
// Aşağıdaki ID ve ölçekler ÖRNEKTİR — kendi kontrolcü/BMS dokümanınıza göre güncelleyin.

#include <stdbool.h>

struct CanData {
  bool haveSpeed = false;
  bool haveBattery = false;
  float speedKph = 0;
  float batteryPct = 0;
  float voltage = 0;
  const char* fault = nullptr;
};

// TWAI sürücüsünü başlat (pinler config.h'de). Başarılıysa true.
bool canBegin();

// Bekleyen CAN çerçevelerini oku ve out'a çöz. Yeni veri geldiyse true.
bool canPoll(CanData& out);
