import 'dart:async';

import 'package:flutter/services.dart' show HapticFeedback;

import '../models/antitheft_config.dart';
import 'alarm_siren.dart';
import 'antitheft_detector.dart';

enum AlarmState { disarmed, armed, warning, alarming }

/// Orchestrates the movement alarm: arm/disarm, an entry-delay warning window
/// (haptic chirps so the owner can disarm), then full siren + notification.
class AntiTheftController {
  AntiTheftController({
    required this.config,
    AntiTheftDetector? detector,
    AlarmSiren? siren,
    this.onAlarm,
  })  : detector = detector ??
            AntiTheftDetector(
              sensitivityG: config.sensitivityG,
              useGps: config.useGps,
              gpsRadiusM: config.gpsRadiusM,
            ),
        siren = siren ??
            (config.sirenAsset != null
                ? AudioSiren(config.sirenAsset!)
                : NoopSiren()) {
    _sub = this.detector.events.listen(_onTheft);
  }

  AntiTheftConfig config;
  final AntiTheftDetector detector;
  final AlarmSiren siren;

  /// Called when the alarm goes fully off (e.g. send SOS / push with location).
  final Future<void> Function(TheftEvent event)? onAlarm;

  StreamSubscription<TheftEvent>? _sub;
  Timer? _warnTimer;
  Timer? _chirpTimer;

  final _state = StreamController<AlarmState>.broadcast();
  AlarmState _current = AlarmState.disarmed;

  Stream<AlarmState> get stateStream => _state.stream;
  AlarmState get state => _current;

  void _setState(AlarmState s) {
    _current = s;
    _state.add(s);
  }

  void arm() {
    detector
      ..sensitivityG = config.sensitivityG
      ..useGps = config.useGps
      ..gpsRadiusM = config.gpsRadiusM
      ..arm();
    _setState(AlarmState.armed);
  }

  void disarm() {
    _warnTimer?.cancel();
    _chirpTimer?.cancel();
    siren.stop();
    detector.disarm();
    _setState(AlarmState.disarmed);
  }

  Future<void> _onTheft(TheftEvent e) async {
    if (_current != AlarmState.armed) return; // already warning/alarming
    _setState(AlarmState.warning);

    // Warning chirps during the entry delay.
    _chirpTimer = Timer.periodic(const Duration(milliseconds: 700), (_) {
      HapticFeedback.heavyImpact();
    });
    _warnTimer = Timer(config.entryDelay, () => _fullAlarm(e));
  }

  Future<void> _fullAlarm(TheftEvent e) async {
    _chirpTimer?.cancel();
    if (_current != AlarmState.warning) return;
    _setState(AlarmState.alarming);
    await siren.start();
    if (config.notifyOnAlarm) {
      try {
        await onAlarm?.call(e);
      } catch (_) {/* delivery best-effort */}
    }
  }

  void dispose() {
    _warnTimer?.cancel();
    _chirpTimer?.cancel();
    _sub?.cancel();
    detector.dispose();
    siren.dispose();
    _state.close();
  }
}
