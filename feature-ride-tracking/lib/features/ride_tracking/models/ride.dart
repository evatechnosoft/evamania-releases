import 'dart:convert';
import 'dart:math' as math;

import 'track_point.dart';

/// A trip / ride: an ordered list of telemetry [TrackPoint]s plus a rich set of
/// derived statistics (distance, speed, energy, efficiency, thermals, battery
/// health) and optional reverse-geocoded start/end addresses.
///
/// This is the data system: feed it samples (GPS + controller/BMS), it computes
/// everything and serializes to JSON (source of truth) + CSV (spreadsheet).
class Ride {
  final String id;
  final DateTime startTime;
  DateTime? endTime;
  final List<TrackPoint> points;

  /// Which vehicle/controller produced this trip (free-form, e.g. "FarDriver").
  String? vehicleId;
  String? title;
  String? startAddress;
  String? endAddress;

  Ride({
    required this.id,
    required this.startTime,
    this.endTime,
    List<TrackPoint>? points,
    this.vehicleId,
    this.title,
    this.startAddress,
    this.endAddress,
  }) : points = points ?? <TrackPoint>[];

  // ---- Time ---------------------------------------------------------------

  Duration get duration =>
      (endTime ?? (points.isNotEmpty ? points.last.time : startTime))
          .difference(startTime);

  /// Time actually moving (speed above [movingThresholdKmh]).
  static const movingThresholdKmh = 1.5;
  Duration get movingTime {
    var secs = 0.0;
    for (var i = 1; i < points.length; i++) {
      final dt = points[i].time.difference(points[i - 1].time).inMilliseconds /
          1000.0;
      if (points[i].speedKmh > movingThresholdKmh) secs += dt;
    }
    return Duration(milliseconds: (secs * 1000).round());
  }

  // ---- Distance & speed ---------------------------------------------------

  double get distanceMeters {
    double d = 0;
    for (var i = 1; i < points.length; i++) {
      d += _haversine(points[i - 1], points[i]);
    }
    return d;
  }

  double get distanceKm => distanceMeters / 1000.0;

  double get maxSpeedKmh =>
      points.fold<double>(0, (m, p) => math.max(m, p.speedKmh));

  /// Average over total elapsed time.
  double get avgSpeedKmh {
    final secs = duration.inSeconds;
    return secs <= 0 ? 0 : distanceKm / (secs / 3600.0);
  }

  /// Average over moving time only (excludes stops).
  double get avgMovingSpeedKmh {
    final secs = movingTime.inSeconds;
    return secs <= 0 ? 0 : distanceKm / (secs / 3600.0);
  }

  // ---- Elevation ----------------------------------------------------------

  double get elevationGain => _elevation(positive: true);
  double get elevationLoss => _elevation(positive: false);

  double _elevation({required bool positive}) {
    double acc = 0;
    for (var i = 1; i < points.length; i++) {
      final dz = points[i].altitude - points[i - 1].altitude;
      if (positive && dz > 0) acc += dz;
      if (!positive && dz < 0) acc += -dz;
    }
    return acc;
  }

  // ---- Energy & efficiency ------------------------------------------------

  /// Energy drawn (Wh), integral of positive electrical power over time.
  double get energyWh => _energy(regen: false);

  /// Energy recovered via regen (Wh), integral of negative power.
  double get regenWh => _energy(regen: true);

  double _energy({required bool regen}) {
    double wh = 0;
    for (var i = 1; i < points.length; i++) {
      final p0 = points[i - 1].powerW, p1 = points[i].powerW;
      if (p0 == null || p1 == null) continue;
      final dtH =
          points[i].time.difference(points[i - 1].time).inMilliseconds /
              3600000.0;
      final avg = (p0 + p1) / 2;
      if (!regen && avg > 0) wh += avg * dtH;
      if (regen && avg < 0) wh += -avg * dtH;
    }
    return wh;
  }

  /// Consumed capacity (Ah): prefers BMS consumedAh delta, else integrates
  /// current over time. Null when neither is available.
  double? get consumedAh {
    final withAh = points.where((p) => p.consumedAh != null).toList();
    if (withAh.length >= 2) {
      return withAh.last.consumedAh! - withAh.first.consumedAh!;
    }
    double ah = 0;
    var any = false;
    for (var i = 1; i < points.length; i++) {
      final c0 = points[i - 1].current, c1 = points[i].current;
      if (c0 == null || c1 == null) continue;
      any = true;
      final dtH =
          points[i].time.difference(points[i - 1].time).inMilliseconds /
              3600000.0;
      final avg = (c0 + c1) / 2;
      if (avg > 0) ah += avg * dtH;
    }
    return any ? ah : null;
  }

  double? get efficiencyWhPerKm =>
      distanceKm > 0 && energyWh > 0 ? energyWh / distanceKm : null;

  double? get consumptionAhPerKm {
    final ah = consumedAh;
    return (ah != null && distanceKm > 0) ? ah / distanceKm : null;
  }

  // ---- Peaks / thermals / battery health ---------------------------------

  double? get maxPowerW => _max((p) => p.powerW);
  double? get maxCurrentA => _max((p) => p.current);
  double? get minVoltage => _min((p) => p.voltage);
  double? get maxMotorTempC => _max((p) => p.motorTempC);
  double? get maxControllerTempC => _max((p) => p.controllerTempC);
  double? get maxBatteryTempC => _max((p) => p.batteryTempC);
  int? get maxCellDeltaMv {
    final vals = points.map((p) => p.cellDeltaMv).whereType<int>();
    return vals.isEmpty ? null : vals.reduce(math.max);
  }

  double? get socStart => points.map((p) => p.soc).whereType<double>().isEmpty
      ? null
      : points.map((p) => p.soc).whereType<double>().first;
  double? get socEnd => points.map((p) => p.soc).whereType<double>().isEmpty
      ? null
      : points.map((p) => p.soc).whereType<double>().last;
  double? get socUsed =>
      (socStart != null && socEnd != null) ? socStart! - socEnd! : null;

  /// Estimated remaining range (km) from last SOC/remainingAh and efficiency.
  double? get estimatedRangeKm {
    final eff = consumptionAhPerKm;
    final last = points.isNotEmpty ? points.last.remainingAh : null;
    if (eff != null && eff > 0 && last != null) return last / eff;
    return null;
  }

  /// All distinct fault labels seen during the trip.
  Set<String> get faultsSeen =>
      points.expand((p) => p.faults).toSet();

  double? _max(double? Function(TrackPoint) f) {
    final vals = points.map(f).whereType<double>();
    return vals.isEmpty ? null : vals.reduce(math.max);
  }

  double? _min(double? Function(TrackPoint) f) {
    final vals = points.map(f).whereType<double>();
    return vals.isEmpty ? null : vals.reduce(math.min);
  }

  // ---- Serialization ------------------------------------------------------

  Map<String, dynamic> statsMap() => {
        'distanceKm': distanceKm,
        'durationSec': duration.inSeconds,
        'movingTimeSec': movingTime.inSeconds,
        'avgSpeedKmh': avgSpeedKmh,
        'avgMovingSpeedKmh': avgMovingSpeedKmh,
        'maxSpeedKmh': maxSpeedKmh,
        'elevationGain': elevationGain,
        'elevationLoss': elevationLoss,
        'energyWh': energyWh,
        'regenWh': regenWh,
        'consumedAh': consumedAh,
        'efficiencyWhPerKm': efficiencyWhPerKm,
        'consumptionAhPerKm': consumptionAhPerKm,
        'maxPowerW': maxPowerW,
        'maxCurrentA': maxCurrentA,
        'minVoltage': minVoltage,
        'maxMotorTempC': maxMotorTempC,
        'maxControllerTempC': maxControllerTempC,
        'maxBatteryTempC': maxBatteryTempC,
        'maxCellDeltaMv': maxCellDeltaMv,
        'socStart': socStart,
        'socEnd': socEnd,
        'socUsed': socUsed,
        'estimatedRangeKm': estimatedRangeKm,
        'faultsSeen': faultsSeen.toList(),
      };

  Map<String, dynamic> toJson() => {
        'id': id,
        'start': startTime.toUtc().toIso8601String(),
        'end': endTime?.toUtc().toIso8601String(),
        'vehicleId': vehicleId,
        'title': title,
        'startAddress': startAddress,
        'endAddress': endAddress,
        'stats': statsMap(),
        'points': points.map((p) => p.toJson()).toList(),
      };

  String toJsonString({bool pretty = true}) => pretty
      ? const JsonEncoder.withIndent('  ').convert(toJson())
      : jsonEncode(toJson());

  factory Ride.fromJson(Map<String, dynamic> j) => Ride(
        id: j['id'] as String,
        startTime: DateTime.parse(j['start'] as String).toLocal(),
        endTime: j['end'] != null
            ? DateTime.parse(j['end'] as String).toLocal()
            : null,
        vehicleId: j['vehicleId'] as String?,
        title: j['title'] as String?,
        startAddress: j['startAddress'] as String?,
        endAddress: j['endAddress'] as String?,
        points: ((j['points'] as List?) ?? const [])
            .map((e) => TrackPoint.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  /// Per-point CSV (RFC-4180 friendly; opens in Excel/Sheets). Address column
  /// repeats the ride-level start/end address on the first/last row.
  String toCsv() {
    const header = [
      'index',
      'timestamp',
      'lat',
      'lng',
      'altitude_m',
      'gps_speed_kmh',
      'speed_kmh',
      'rpm',
      'mode',
      'throttle_pct',
      'voltage_v',
      'current_a',
      'power_w',
      'soc_pct',
      'remaining_ah',
      'consumed_ah',
      'motor_temp_c',
      'controller_temp_c',
      'battery_temp_c',
      'cell_min_mv',
      'cell_max_mv',
      'cell_delta_mv',
      'faults',
      'address',
    ];
    final b = StringBuffer()..writeln(header.join(','));
    String n(num? v, [int frac = 2]) => v == null ? '' : v.toStringAsFixed(frac);
    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      final addr =
          i == 0 ? startAddress : (i == points.length - 1 ? endAddress : null);
      b.writeln([
        i,
        p.time.toIso8601String(),
        p.lat.toStringAsFixed(6),
        p.lng.toStringAsFixed(6),
        n(p.altitude, 1),
        n(p.gpsSpeedMs * 3.6, 1),
        n(p.vehicleSpeedKmh, 1),
        n(p.rpm, 0),
        _csv(p.mode ?? ''),
        n(p.throttlePct, 0),
        n(p.voltage, 1),
        n(p.current, 2),
        n(p.powerW, 0),
        n(p.soc, 1),
        n(p.remainingAh, 3),
        n(p.consumedAh, 3),
        n(p.motorTempC, 1),
        n(p.controllerTempC, 1),
        n(p.batteryTempC, 1),
        p.cellMinMv ?? '',
        p.cellMaxMv ?? '',
        p.cellDeltaMv ?? '',
        _csv(p.faults.join('|')),
        _csv(addr ?? ''),
      ].join(','));
    }
    return b.toString();
  }

  static String _csv(String v) =>
      (v.contains(',') || v.contains('"') || v.contains('\n'))
          ? '"${v.replaceAll('"', '""')}"'
          : v;

  static double _haversine(TrackPoint a, TrackPoint b) {
    const r = 6371000.0;
    final dLat = _rad(b.lat - a.lat);
    final dLng = _rad(b.lng - a.lng);
    final s = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_rad(a.lat)) *
            math.cos(_rad(b.lat)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return r * 2 * math.atan2(math.sqrt(s), math.sqrt(1 - s));
  }

  static double _rad(double deg) => deg * math.pi / 180.0;
}
