// EvaISYS araç modeli — backend veri sözleşmesiyle hizalı.
class Vehicle {
  final String vehicleId;
  final bool online;
  final double speedKph;
  final double batteryPct;
  final double voltage;
  final double odometerKm;
  final double? lat;
  final double? lng;
  final bool locked;
  final bool immobilized;
  final bool alarm;
  final String? fault;

  Vehicle({
    required this.vehicleId,
    required this.online,
    required this.speedKph,
    required this.batteryPct,
    required this.voltage,
    required this.odometerKm,
    required this.lat,
    required this.lng,
    required this.locked,
    required this.immobilized,
    required this.alarm,
    required this.fault,
  });

  factory Vehicle.fromJson(Map<String, dynamic> j) {
    double d(dynamic v) => (v is num) ? v.toDouble() : 0.0;
    double? dn(dynamic v) => (v is num) ? v.toDouble() : null;
    return Vehicle(
      vehicleId: j['vehicleId'] as String? ?? '—',
      online: j['online'] as bool? ?? false,
      speedKph: d(j['speedKph']),
      batteryPct: d(j['batteryPct']),
      voltage: d(j['voltage']),
      odometerKm: d(j['odometerKm']),
      lat: dn(j['lat']),
      lng: dn(j['lng']),
      locked: j['locked'] as bool? ?? false,
      immobilized: j['immobilized'] as bool? ?? false,
      alarm: j['alarm'] as bool? ?? false,
      fault: j['fault'] as String?,
    );
  }
}
