import 'dart:async';

import '../models/ride.dart';
import 'ride_geocoder.dart';
import 'ride_recorder.dart';
import 'ride_store.dart';

/// Zero-tap convenience layer over [RideRecorder]: starts a trip automatically
/// when the vehicle starts moving (and/or the controller is connected) and
/// stops it after a sustained idle period, then geocodes + saves it.
///
/// Wire it to your app once and forget it:
/// ```dart
/// final auto = AutoTripController(onTripSaved: (ride) => refreshList());
/// // from connection state changes:
/// auto.setConnected(true);
/// // from your telemetry loop (speed + the usual fields):
/// auto.tick(speedKmh: speed);
/// auto.updateTelemetry(voltage: v, current: i, soc: soc, motorTempC: mt);
/// ```
class AutoTripController {
  AutoTripController({
    this.startSpeedKmh = 3.0,
    this.idleSpeedKmh = 1.0,
    this.startSustain = const Duration(seconds: 3),
    this.idleTimeout = const Duration(minutes: 2),
    this.requireConnection = false,
    this.localeIdentifier = 'tr_TR',
    this.onTripStarted,
    this.onTripSaved,
    RideRecorder? recorder,
    RideStore? store,
  }) : _recorder = recorder ?? RideRecorder(),
        _store = store ?? RideStore();

  /// Speed above which a trip auto-starts (km/h).
  final double startSpeedKmh;

  /// Speed at or below which the vehicle is considered stopped (km/h).
  final double idleSpeedKmh;

  /// How long movement must persist before auto-start.
  final Duration startSustain;

  /// How long the vehicle must be idle before auto-stop+save.
  final Duration idleTimeout;

  /// When true, only auto-start while the controller is connected.
  final bool requireConnection;

  final String localeIdentifier;
  final void Function()? onTripStarted;
  final void Function(Ride ride)? onTripSaved;

  final RideRecorder _recorder;
  final RideStore _store;

  bool _connected = false;
  DateTime? _movingSince;
  DateTime? _idleSince;
  bool _saving = false;

  bool get isRecording => _recorder.isRecording;
  Stream<Ride> get rideStream => _recorder.rideStream;
  RideRecorder get recorder => _recorder;

  void setConnected(bool connected) {
    _connected = connected;
  }

  /// Forward controller/BMS telemetry straight to the underlying recorder.
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
    _recorder.updateTelemetry(
      vehicleSpeedKmh: vehicleSpeedKmh,
      rpm: rpm,
      mode: mode,
      throttlePct: throttlePct,
      voltage: voltage,
      current: current,
      soc: soc,
      remainingAh: remainingAh,
      consumedAh: consumedAh,
      packVoltage: packVoltage,
      batteryCurrent: batteryCurrent,
      cellMinMv: cellMinMv,
      cellMaxMv: cellMaxMv,
      cycles: cycles,
      motorTempC: motorTempC,
      controllerTempC: controllerTempC,
      batteryTempC: batteryTempC,
      faults: faults,
    );
  }

  /// Drive the state machine. Call regularly (e.g. every telemetry update)
  /// with the current speed. [now] is injectable for testing.
  Future<void> tick({required double speedKmh, DateTime? now}) async {
    final t = now ?? DateTime.now();

    if (!_recorder.isRecording) {
      final canStart = !requireConnection || _connected;
      if (canStart && speedKmh > startSpeedKmh) {
        _movingSince ??= t;
        if (t.difference(_movingSince!) >= startSustain) {
          await _start(vehicleId: null);
        }
      } else {
        _movingSince = null;
      }
      return;
    }

    // Recording: track idle to decide auto-stop.
    if (speedKmh <= idleSpeedKmh) {
      _idleSince ??= t;
      if (t.difference(_idleSince!) >= idleTimeout) {
        await _stopAndSave();
      }
    } else {
      _idleSince = null;
    }
  }

  /// Force-start a trip now (e.g. a manual "record" button).
  Future<void> startManually({String? vehicleId}) => _start(vehicleId: vehicleId);

  /// Force-stop + save now.
  Future<Ride?> stopManually() => _stopAndSave();

  Future<void> _start({String? vehicleId}) async {
    if (_recorder.isRecording) return;
    _idleSince = null;
    _movingSince = null;
    await _recorder.start(vehicleId: vehicleId);
    onTripStarted?.call();
  }

  Future<Ride?> _stopAndSave() async {
    if (_saving) return null;
    _saving = true;
    try {
      final ride = await _recorder.stop();
      _idleSince = null;
      _movingSince = null;
      if (ride == null || ride.points.length < 2) return ride; // discard noise
      try {
        await RideGeocoder(localeIdentifier: localeIdentifier).annotate(ride);
      } catch (_) {/* offline — keep coords */}
      await _store.save(ride);
      onTripSaved?.call(ride);
      return ride;
    } finally {
      _saving = false;
    }
  }

  void dispose() => _recorder.dispose();
}
