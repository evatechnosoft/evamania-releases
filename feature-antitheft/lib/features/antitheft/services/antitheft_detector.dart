import 'dart:async';
import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';

enum TheftReason { motion, towed }

class TheftEvent {
  final TheftReason reason;

  /// For motion: accel deviation in g. For towed: distance moved in meters.
  final double magnitude;
  final DateTime time;

  const TheftEvent({
    required this.reason,
    required this.magnitude,
    required this.time,
  });
}

/// Detects tampering while the vehicle is parked & armed: accelerometer motion
/// beyond a deviation threshold, and (optionally) GPS displacement (towing).
class AntiTheftDetector {
  AntiTheftDetector({
    this.sensitivityG = 0.35,
    this.useGps = true,
    this.gpsRadiusM = 25,
    this.debounce = const Duration(seconds: 5),
  });

  double sensitivityG;
  bool useGps;
  double gpsRadiusM;
  final Duration debounce;

  static const _g = 9.80665;

  final _controller = StreamController<TheftEvent>.broadcast();
  StreamSubscription<AccelerometerEvent>? _accel;
  StreamSubscription<Position>? _gps;
  Position? _armedPosition;
  DateTime? _lastFired;
  bool _armed = false;

  Stream<TheftEvent> get events => _controller.stream;
  bool get isArmed => _armed;

  /// Arm the alarm. [armedPosition] is the reference for GPS towing detection;
  /// if null and [useGps], the first GPS fix becomes the reference.
  void arm({Position? armedPosition}) {
    if (_armed) return;
    _armed = true;
    _armedPosition = armedPosition;
    _accel = accelerometerEventStream().listen(_onAccel);
    if (useGps) {
      _gps = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ).listen(_onGps);
    }
  }

  void disarm() {
    _armed = false;
    _accel?.cancel();
    _accel = null;
    _gps?.cancel();
    _gps = null;
    _armedPosition = null;
    _lastFired = null;
  }

  void _onAccel(AccelerometerEvent e) {
    if (!_armed) return;
    final mag = math.sqrt(e.x * e.x + e.y * e.y + e.z * e.z) / _g;
    final deviation = (mag - 1.0).abs(); // 1g at rest
    if (deviation >= sensitivityG) {
      _fire(TheftReason.motion, deviation);
    }
  }

  void _onGps(Position p) {
    if (!_armed) return;
    _armedPosition ??= p;
    final d = Geolocator.distanceBetween(
      _armedPosition!.latitude,
      _armedPosition!.longitude,
      p.latitude,
      p.longitude,
    );
    if (d >= gpsRadiusM) _fire(TheftReason.towed, d);
  }

  void _fire(TheftReason reason, double magnitude) {
    final now = DateTime.now();
    if (_lastFired != null && now.difference(_lastFired!) < debounce) return;
    _lastFired = now;
    _controller.add(TheftEvent(reason: reason, magnitude: magnitude, time: now));
  }

  void dispose() {
    disarm();
    _controller.close();
  }
}
