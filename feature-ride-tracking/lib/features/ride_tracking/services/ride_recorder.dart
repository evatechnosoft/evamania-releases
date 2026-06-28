import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../models/ride.dart';
import '../models/track_point.dart';

/// Records a trip by fusing the GPS stream with controller/BMS telemetry that
/// you push from your existing BLE handlers, sampling both at a fixed rate.
///
/// ```dart
/// final rec = RideRecorder(sampleInterval: const Duration(seconds: 1));
/// await rec.start(vehicleId: 'FarDriver');
/// rec.rideStream.listen((trip) => setState(() => _live = trip));
///
/// // From your BLE data callbacks, whenever fresh values arrive:
/// rec.updateTelemetry(vehicleSpeedKmh: 42, voltage: 78.4, current: 31.2,
///                     soc: 86, motorTempC: 64);
///
/// final trip = await rec.stop();
/// ```
class RideRecorder {
  RideRecorder({
    this.sampleInterval = const Duration(seconds: 1),
    this.distanceFilterMeters = 0,
  });

  /// How often a [TrackPoint] is captured (GPS + latest telemetry).
  final Duration sampleInterval;

  /// Optional GPS distance filter (0 = report every fix).
  final int distanceFilterMeters;

  Ride? _ride;
  Position? _lastPosition;
  TrackPoint? _latestTelemetry;
  StreamSubscription<Position>? _gpsSub;
  Timer? _timer;
  final _controller = StreamController<Ride>.broadcast();

  Stream<Ride> get rideStream => _controller.stream;
  bool get isRecording => _ride != null;
  Ride? get current => _ride;

  /// Requests permissions/services then starts recording. Throws [StateError]
  /// with a code you can localize: `locationServiceNotActive`,
  /// `locationPermissionDenied`.
  Future<void> start({String? vehicleId}) async {
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
      id: 'trip_${DateTime.now().millisecondsSinceEpoch}',
      startTime: DateTime.now(),
      vehicleId: vehicleId,
    );

    _gpsSub = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: distanceFilterMeters,
      ),
    ).listen((p) => _lastPosition = p);

    _timer = Timer.periodic(sampleInterval, (_) => _sample());
  }

  /// Latches the latest controller/BMS values. Only non-null fields override
  /// the previous snapshot, so you can call it from several callbacks.
  void updateTelemetry({
    double? vehicleSpeedKmh,
    double? rpm,
    String? mode,
    double? throttlePct,
    double? voltage,
    double? current,
    double? soc,
    double? remainingAh,
    double? consumedAh,
    double? packVoltage,
    double? batteryCurrent,
    int? cellMinMv,
    int? cellMaxMv,
    int? cycles,
    double? motorTempC,
    double? controllerTempC,
    double? batteryTempC,
    List<String>? faults,
  }) {
    final prev = _latestTelemetry;
    _latestTelemetry = TrackPoint(
      time: DateTime.now(),
      lat: 0,
      lng: 0,
      vehicleSpeedKmh: vehicleSpeedKmh ?? prev?.vehicleSpeedKmh,
      rpm: rpm ?? prev?.rpm,
      mode: mode ?? prev?.mode,
      throttlePct: throttlePct ?? prev?.throttlePct,
      voltage: voltage ?? prev?.voltage,
      current: current ?? prev?.current,
      soc: soc ?? prev?.soc,
      remainingAh: remainingAh ?? prev?.remainingAh,
      consumedAh: consumedAh ?? prev?.consumedAh,
      packVoltage: packVoltage ?? prev?.packVoltage,
      batteryCurrent: batteryCurrent ?? prev?.batteryCurrent,
      cellMinMv: cellMinMv ?? prev?.cellMinMv,
      cellMaxMv: cellMaxMv ?? prev?.cellMaxMv,
      cycles: cycles ?? prev?.cycles,
      motorTempC: motorTempC ?? prev?.motorTempC,
      controllerTempC: controllerTempC ?? prev?.controllerTempC,
      batteryTempC: batteryTempC ?? prev?.batteryTempC,
      faults: faults ?? prev?.faults ?? const [],
    );
  }

  void _sample() {
    final ride = _ride;
    final pos = _lastPosition;
    if (ride == null || pos == null) return; // wait for first GPS fix

    var sample = TrackPoint(
      time: DateTime.now(),
      lat: pos.latitude,
      lng: pos.longitude,
      altitude: pos.altitude,
      gpsSpeedMs: pos.speed < 0 ? 0 : pos.speed,
      heading: pos.heading,
    );
    if (_latestTelemetry != null) {
      sample = sample.mergeTelemetry(_latestTelemetry!);
    }
    ride.points.add(sample);
    _controller.add(ride);
  }

  Future<Ride?> stop() async {
    _timer?.cancel();
    _timer = null;
    await _gpsSub?.cancel();
    _gpsSub = null;
    final ride = _ride;
    ride?.endTime = DateTime.now();
    _ride = null;
    _latestTelemetry = null;
    _lastPosition = null;
    return ride;
  }

  void dispose() {
    _timer?.cancel();
    _gpsSub?.cancel();
    _controller.close();
  }
}
