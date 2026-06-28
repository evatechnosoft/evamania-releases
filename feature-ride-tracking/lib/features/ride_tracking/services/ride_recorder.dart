import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../models/ride.dart';
import '../models/track_point.dart';

/// Records a live ride from the GPS stream, Strava-style.
///
/// Usage:
/// ```dart
/// final rec = RideRecorder();
/// await rec.start();
/// rec.rideStream.listen((ride) => setState(() => _live = ride));
/// // Optionally feed controller/BMS telemetry as it arrives:
/// rec.attachTelemetry(current: 42.0, batteryAh: 12.3);
/// final ride = await rec.stop();
/// ```
class RideRecorder {
  RideRecorder({this.distanceFilterMeters = 3});

  /// Minimum movement (m) between recorded points. Keeps tracks compact.
  final int distanceFilterMeters;

  Ride? _ride;
  StreamSubscription<Position>? _sub;
  final _controller = StreamController<Ride>.broadcast();

  double? _pendingCurrent;
  double? _pendingAh;

  /// Emits the in-progress [Ride] every time a new point is appended.
  Stream<Ride> get rideStream => _controller.stream;

  bool get isRecording => _ride != null;
  Ride? get current => _ride;

  /// Requests permission + location services, then begins recording.
  /// Throws a [StateError] with a code you can map to a localized message
  /// (e.g. `locationServiceNotActive`, `locationPermissionDenied`).
  Future<void> start() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw StateError('locationServiceNotActive');
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      throw StateError('locationPermissionDenied');
    }

    _ride = Ride(
      id: 'ride_${DateTime.now().millisecondsSinceEpoch}',
      startTime: DateTime.now(),
    );

    _sub = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: distanceFilterMeters,
      ),
    ).listen(_onPosition);
  }

  /// Latches the latest controller/BMS telemetry; the next GPS point picks it
  /// up. Call this from your existing BLE data handler.
  void attachTelemetry({double? current, double? batteryAh}) {
    _pendingCurrent = current ?? _pendingCurrent;
    _pendingAh = batteryAh ?? _pendingAh;
  }

  void _onPosition(Position p) {
    final ride = _ride;
    if (ride == null) return;
    ride.points.add(TrackPoint(
      lat: p.latitude,
      lng: p.longitude,
      altitude: p.altitude,
      speedMs: p.speed < 0 ? 0 : p.speed,
      time: p.timestamp.toLocal(),
      current: _pendingCurrent,
      batteryAh: _pendingAh,
    ));
    _controller.add(ride);
  }

  /// Stops recording and returns the finished ride (null if never started).
  Future<Ride?> stop() async {
    await _sub?.cancel();
    _sub = null;
    final ride = _ride;
    ride?.endTime = DateTime.now();
    _ride = null;
    return ride;
  }

  void dispose() {
    _sub?.cancel();
    _controller.close();
  }
}
