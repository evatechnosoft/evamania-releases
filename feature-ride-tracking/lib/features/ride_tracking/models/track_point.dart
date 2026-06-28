/// A single GPS sample recorded during a ride.
///
/// Speed is stored in m/s (as reported by the OS); convert to km/h at the UI
/// layer with [speedKmh]. Telemetry fields ([current], [batteryAh]) are
/// optional hooks so you can overlay controller/BMS data (e.g. FarDriver /
/// Votol / JK) on the route the same way Strava overlays heart-rate/power.
class TrackPoint {
  final double lat;
  final double lng;

  /// Altitude in meters (may be 0 when the device has no fix yet).
  final double altitude;

  /// Instantaneous speed in m/s from the GPS provider.
  final double speedMs;

  /// Wall-clock time of the sample.
  final DateTime time;

  /// Optional: instantaneous current (A) pulled from the controller/BMS.
  final double? current;

  /// Optional: consumed capacity so far (Ah) for range/consumption overlay.
  final double? batteryAh;

  const TrackPoint({
    required this.lat,
    required this.lng,
    required this.altitude,
    required this.speedMs,
    required this.time,
    this.current,
    this.batteryAh,
  });

  double get speedKmh => speedMs * 3.6;

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lng': lng,
        'alt': altitude,
        'speedMs': speedMs,
        't': time.toUtc().toIso8601String(),
        if (current != null) 'current': current,
        if (batteryAh != null) 'ah': batteryAh,
      };

  factory TrackPoint.fromJson(Map<String, dynamic> j) => TrackPoint(
        lat: (j['lat'] as num).toDouble(),
        lng: (j['lng'] as num).toDouble(),
        altitude: (j['alt'] as num?)?.toDouble() ?? 0,
        speedMs: (j['speedMs'] as num?)?.toDouble() ?? 0,
        time: DateTime.parse(j['t'] as String).toLocal(),
        current: (j['current'] as num?)?.toDouble(),
        batteryAh: (j['ah'] as num?)?.toDouble(),
      );
}
