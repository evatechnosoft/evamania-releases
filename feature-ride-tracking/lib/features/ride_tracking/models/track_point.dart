/// A single time-stamped telemetry sample taken during a trip.
///
/// One [TrackPoint] is a full snapshot of everything EvaMania knows at an
/// instant: GPS position **plus** whatever the controller / BMS reported over
/// BLE (FarDriver / Votol / JK / Daly / ANT). Every vehicle field is optional
/// because data availability differs per controller and per moment — feed
/// whatever you have and the stats layer copes with the gaps.
class TrackPoint {
  // ---- Time & GPS (always present) ---------------------------------------
  final DateTime time;
  final double lat;
  final double lng;

  /// Altitude in meters (0 when no fix yet).
  final double altitude;

  /// Speed from the GPS provider, m/s (>=0).
  final double gpsSpeedMs;

  /// GPS heading in degrees (0..360), null if unknown.
  final double? heading;

  // ---- Vehicle / controller ----------------------------------------------
  /// Speed reported by the controller (km/h), preferred over GPS when present.
  final double? vehicleSpeedKmh;

  /// Motor RPM.
  final double? rpm;

  /// Ride mode / gear label (e.g. "ECO", "NORMAL", "SPORT").
  final String? mode;

  /// Throttle position 0..100 %.
  final double? throttlePct;

  // ---- Electrical (controller) -------------------------------------------
  /// Pack/bus voltage at the controller (V).
  final double? voltage;

  /// Bus current (A). Negative = regen/charging.
  final double? current;

  // ---- Battery / BMS ------------------------------------------------------
  /// State of charge 0..100 %.
  final double? soc;

  /// Remaining capacity (Ah) as reported by the BMS.
  final double? remainingAh;

  /// Cumulative consumed capacity (Ah) since some baseline (monotonic).
  final double? consumedAh;

  final double? packVoltage;
  final double? batteryCurrent;
  final int? cellMinMv;
  final int? cellMaxMv;
  final int? cycles;

  // ---- Temperatures (°C) --------------------------------------------------
  final double? motorTempC;
  final double? controllerTempC;
  final double? batteryTempC;

  // ---- Faults -------------------------------------------------------------
  /// Active fault/error labels at this instant (e.g. decoded FarDriver bits).
  final List<String> faults;

  const TrackPoint({
    required this.time,
    required this.lat,
    required this.lng,
    this.altitude = 0,
    this.gpsSpeedMs = 0,
    this.heading,
    this.vehicleSpeedKmh,
    this.rpm,
    this.mode,
    this.throttlePct,
    this.voltage,
    this.current,
    this.soc,
    this.remainingAh,
    this.consumedAh,
    this.packVoltage,
    this.batteryCurrent,
    this.cellMinMv,
    this.cellMaxMv,
    this.cycles,
    this.motorTempC,
    this.controllerTempC,
    this.batteryTempC,
    this.faults = const [],
  });

  /// Effective speed in km/h: controller speed if known, else GPS speed.
  double get speedKmh => vehicleSpeedKmh ?? gpsSpeedMs * 3.6;

  /// Instantaneous electrical power in watts (V·A), null if either is missing.
  double? get powerW =>
      (voltage != null && current != null) ? voltage! * current! : null;

  /// Cell spread in mV (BMS balance health), null if cells unknown.
  int? get cellDeltaMv =>
      (cellMinMv != null && cellMaxMv != null) ? cellMaxMv! - cellMinMv! : null;

  Map<String, dynamic> toJson() => {
        't': time.toUtc().toIso8601String(),
        'lat': lat,
        'lng': lng,
        'alt': altitude,
        'gpsSpeedMs': gpsSpeedMs,
        if (heading != null) 'heading': heading,
        if (vehicleSpeedKmh != null) 'speedKmh': vehicleSpeedKmh,
        if (rpm != null) 'rpm': rpm,
        if (mode != null) 'mode': mode,
        if (throttlePct != null) 'throttle': throttlePct,
        if (voltage != null) 'voltage': voltage,
        if (current != null) 'current': current,
        if (soc != null) 'soc': soc,
        if (remainingAh != null) 'remainingAh': remainingAh,
        if (consumedAh != null) 'consumedAh': consumedAh,
        if (packVoltage != null) 'packVoltage': packVoltage,
        if (batteryCurrent != null) 'batteryCurrent': batteryCurrent,
        if (cellMinMv != null) 'cellMinMv': cellMinMv,
        if (cellMaxMv != null) 'cellMaxMv': cellMaxMv,
        if (cycles != null) 'cycles': cycles,
        if (motorTempC != null) 'motorTemp': motorTempC,
        if (controllerTempC != null) 'controllerTemp': controllerTempC,
        if (batteryTempC != null) 'batteryTemp': batteryTempC,
        if (faults.isNotEmpty) 'faults': faults,
      };

  factory TrackPoint.fromJson(Map<String, dynamic> j) {
    double? d(String k) => (j[k] as num?)?.toDouble();
    int? i(String k) => (j[k] as num?)?.toInt();
    return TrackPoint(
      time: DateTime.parse(j['t'] as String).toLocal(),
      lat: (j['lat'] as num).toDouble(),
      lng: (j['lng'] as num).toDouble(),
      altitude: d('alt') ?? 0,
      gpsSpeedMs: d('gpsSpeedMs') ?? 0,
      heading: d('heading'),
      vehicleSpeedKmh: d('speedKmh'),
      rpm: d('rpm'),
      mode: j['mode'] as String?,
      throttlePct: d('throttle'),
      voltage: d('voltage'),
      current: d('current'),
      soc: d('soc'),
      remainingAh: d('remainingAh'),
      consumedAh: d('consumedAh'),
      packVoltage: d('packVoltage'),
      batteryCurrent: d('batteryCurrent'),
      cellMinMv: i('cellMinMv'),
      cellMaxMv: i('cellMaxMv'),
      cycles: i('cycles'),
      motorTempC: d('motorTemp'),
      controllerTempC: d('controllerTemp'),
      batteryTempC: d('batteryTemp'),
      faults: ((j['faults'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  /// Returns a copy with the given vehicle fields overridden — used by the
  /// recorder to merge the latest BLE telemetry onto a fresh GPS fix.
  TrackPoint mergeTelemetry(TrackPoint t) => TrackPoint(
        time: time,
        lat: lat,
        lng: lng,
        altitude: altitude,
        gpsSpeedMs: gpsSpeedMs,
        heading: heading,
        vehicleSpeedKmh: t.vehicleSpeedKmh ?? vehicleSpeedKmh,
        rpm: t.rpm ?? rpm,
        mode: t.mode ?? mode,
        throttlePct: t.throttlePct ?? throttlePct,
        voltage: t.voltage ?? voltage,
        current: t.current ?? current,
        soc: t.soc ?? soc,
        remainingAh: t.remainingAh ?? remainingAh,
        consumedAh: t.consumedAh ?? consumedAh,
        packVoltage: t.packVoltage ?? packVoltage,
        batteryCurrent: t.batteryCurrent ?? batteryCurrent,
        cellMinMv: t.cellMinMv ?? cellMinMv,
        cellMaxMv: t.cellMaxMv ?? cellMaxMv,
        cycles: t.cycles ?? cycles,
        motorTempC: t.motorTempC ?? motorTempC,
        controllerTempC: t.controllerTempC ?? controllerTempC,
        batteryTempC: t.batteryTempC ?? batteryTempC,
        faults: t.faults.isNotEmpty ? t.faults : faults,
      );
}
