import 'dart:convert';
import 'dart:math' as math;

import 'track_point.dart';

/// A completed (or in-progress) ride: an ordered list of [TrackPoint]s plus
/// derived statistics and optional reverse-geocoded start/end addresses.
class Ride {
  final String id;
  final DateTime startTime;
  DateTime? endTime;
  final List<TrackPoint> points;

  /// Reverse-geocoded human-readable addresses (filled in after recording).
  String? startAddress;
  String? endAddress;

  /// Optional free-text name the user gives the ride.
  String? title;

  Ride({
    required this.id,
    required this.startTime,
    this.endTime,
    List<TrackPoint>? points,
    this.startAddress,
    this.endAddress,
    this.title,
  }) : points = points ?? <TrackPoint>[];

  // ---- Derived statistics -------------------------------------------------

  Duration get duration =>
      (endTime ?? (points.isNotEmpty ? points.last.time : startTime))
          .difference(startTime);

  /// Total distance in meters (haversine over consecutive points).
  double get distanceMeters {
    double d = 0;
    for (var i = 1; i < points.length; i++) {
      d += _haversine(points[i - 1], points[i]);
    }
    return d;
  }

  double get distanceKm => distanceMeters / 1000.0;

  /// Max speed in km/h seen during the ride.
  double get maxSpeedKmh =>
      points.fold<double>(0, (m, p) => math.max(m, p.speedKmh));

  /// Moving-average speed in km/h (distance / moving-time). Falls back to
  /// total time when there is no clear stopped period.
  double get avgSpeedKmh {
    final secs = duration.inSeconds;
    if (secs <= 0) return 0;
    return distanceKm / (secs / 3600.0);
  }

  /// Cumulative positive elevation gain in meters.
  double get elevationGain {
    double gain = 0;
    for (var i = 1; i < points.length; i++) {
      final dz = points[i].altitude - points[i - 1].altitude;
      if (dz > 0) gain += dz;
    }
    return gain;
  }

  /// Consumed capacity (Ah) if telemetry was attached, else null.
  double? get consumedAh {
    final withAh = points.where((p) => p.batteryAh != null).toList();
    if (withAh.length < 2) return null;
    return withAh.last.batteryAh! - withAh.first.batteryAh!;
  }

  /// Average consumption in Ah/km, null when no telemetry / no distance.
  double? get consumptionAhPerKm {
    final ah = consumedAh;
    if (ah == null || distanceKm <= 0) return null;
    return ah / distanceKm;
  }

  // ---- Serialization ------------------------------------------------------

  Map<String, dynamic> toJson() => {
        'id': id,
        'start': startTime.toUtc().toIso8601String(),
        'end': endTime?.toUtc().toIso8601String(),
        'title': title,
        'startAddress': startAddress,
        'endAddress': endAddress,
        'stats': {
          'distanceKm': distanceKm,
          'durationSec': duration.inSeconds,
          'avgSpeedKmh': avgSpeedKmh,
          'maxSpeedKmh': maxSpeedKmh,
          'elevationGain': elevationGain,
          'consumedAh': consumedAh,
          'consumptionAhPerKm': consumptionAhPerKm,
        },
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
        title: j['title'] as String?,
        startAddress: j['startAddress'] as String?,
        endAddress: j['endAddress'] as String?,
        points: ((j['points'] as List?) ?? const [])
            .map((e) => TrackPoint.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  /// CSV with one row per track point. Header is RFC-4180 friendly and opens
  /// cleanly in Excel/Sheets. The address columns repeat the ride-level
  /// start/end address on the first/last row so a single file is self-contained.
  String toCsv() {
    final b = StringBuffer();
    b.writeln(
        'index,timestamp,lat,lng,altitude_m,speed_kmh,current_a,battery_ah,address');
    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      final addr = i == 0
          ? startAddress
          : (i == points.length - 1 ? endAddress : null);
      b.writeln([
        i,
        p.time.toIso8601String(),
        p.lat.toStringAsFixed(6),
        p.lng.toStringAsFixed(6),
        p.altitude.toStringAsFixed(1),
        p.speedKmh.toStringAsFixed(1),
        p.current?.toStringAsFixed(2) ?? '',
        p.batteryAh?.toStringAsFixed(3) ?? '',
        _csvField(addr ?? ''),
      ].join(','));
    }
    return b.toString();
  }

  static String _csvField(String v) {
    if (v.contains(',') || v.contains('"') || v.contains('\n')) {
      return '"${v.replaceAll('"', '""')}"';
    }
    return v;
  }

  static double _haversine(TrackPoint a, TrackPoint b) {
    const r = 6371000.0; // earth radius, meters
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
