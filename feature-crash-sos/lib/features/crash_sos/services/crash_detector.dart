import 'dart:async';
import 'dart:math' as math;

import 'package:sensors_plus/sensors_plus.dart';

/// A detected impact.
class CrashEvent {
  final double peakG;
  final DateTime time;
  const CrashEvent({required this.peakG, required this.time});
}

/// Detects crash-like impacts from the accelerometer.
///
/// Heuristic: total acceleration magnitude (including gravity) briefly spikes
/// far above 1 g on a hard impact/fall. We threshold the magnitude, debounce,
/// and — when [requirePriorMotion] is set — only report if the vehicle was
/// moving recently (suppresses dropped-phone-while-parked false positives).
///
/// Feed speed via [setSpeed] from your telemetry/GPS loop for prior-motion.
class CrashDetector {
  CrashDetector({
    this.impactG = 4.5,
    this.requirePriorMotion = true,
    this.priorMotionWindow = const Duration(seconds: 10),
    this.movingSpeedKmh = 5.0,
    this.debounce = const Duration(seconds: 5),
  });

  double impactG;
  bool requirePriorMotion;
  Duration priorMotionWindow;

  /// Speed above which the vehicle counts as "moving".
  final double movingSpeedKmh;

  /// Minimum time between two reported crashes.
  final Duration debounce;

  static const _g = 9.80665;

  final _controller = StreamController<CrashEvent>.broadcast();
  StreamSubscription<AccelerometerEvent>? _sub;
  DateTime? _lastMoving;
  DateTime? _lastFired;

  Stream<CrashEvent> get events => _controller.stream;
  bool get isRunning => _sub != null;

  /// Update with the latest speed (km/h) to support prior-motion gating.
  void setSpeed(double speedKmh, {DateTime? now}) {
    if (speedKmh >= movingSpeedKmh) _lastMoving = now ?? DateTime.now();
  }

  void start() {
    if (_sub != null) return;
    _sub = accelerometerEventStream().listen(_onSample);
  }

  void _onSample(AccelerometerEvent e) {
    final mag = math.sqrt(e.x * e.x + e.y * e.y + e.z * e.z) / _g; // in g
    if (mag < impactG) return;

    final now = DateTime.now();
    if (_lastFired != null && now.difference(_lastFired!) < debounce) return;

    if (requirePriorMotion) {
      final lm = _lastMoving;
      if (lm == null || now.difference(lm) > priorMotionWindow) return;
    }

    _lastFired = now;
    _controller.add(CrashEvent(peakG: mag, time: now));
  }

  /// Simulate a crash (for the settings "Test" button).
  void simulate() =>
      _controller.add(CrashEvent(peakG: impactG, time: DateTime.now()));

  void stop() {
    _sub?.cancel();
    _sub = null;
  }

  void dispose() {
    stop();
    _controller.close();
  }
}
