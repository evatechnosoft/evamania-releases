import 'dart:async';

import 'package:flutter/services.dart' show HapticFeedback;

import '../models/alarm_rule.dart';
import '../models/rider_telemetry.dart';
import 'alarm_engine.dart';
import 'tts_speaker.dart';

/// Hands-free riding assistant: evaluates telemetry, **speaks** threshold
/// alarms + faults (with haptic feedback), and optionally announces a periodic
/// spoken status ("hız 60, batarya yüzde 80").
///
/// ```dart
/// final assist = VoiceAssistant()..start();
/// // from your BLE telemetry loop:
/// assist.update(RiderTelemetry(speedKmh: 62, soc: 18, motorTempC: 112));
/// // ...
/// assist.dispose();
/// ```
class VoiceAssistant {
  VoiceAssistant({
    AlarmEngine? engine,
    TtsSpeaker? speaker,
    this.haptics = true,
    this.statusInterval = const Duration(minutes: 5),
    this.announceStatus = false,
  })  : engine = engine ?? AlarmEngine(),
        speaker = speaker ?? TtsSpeaker() {
    _sub = this.engine.events.listen(_onAlarm);
  }

  final AlarmEngine engine;
  final TtsSpeaker speaker;

  /// Vibrate on alarms.
  final bool haptics;

  /// How often to speak a routine status (only if [announceStatus]).
  final Duration statusInterval;

  /// Whether to speak periodic status updates.
  bool announceStatus;

  StreamSubscription<AlarmEvent>? _sub;
  Timer? _statusTimer;
  RiderTelemetry _latest = const RiderTelemetry();

  /// Mute/unmute all speech.
  set muted(bool m) => speaker.muted = m;
  bool get muted => speaker.muted;

  List<AlarmRule> get rules => engine.rules;

  void start() {
    _statusTimer?.cancel();
    if (announceStatus) {
      _statusTimer = Timer.periodic(statusInterval, (_) => _speakStatus());
    }
  }

  /// Feed the latest telemetry — drives alarms and (optionally) status.
  void update(RiderTelemetry t) {
    _latest = t;
    engine.evaluate(t);
  }

  /// Speak the current status immediately ("hız X, batarya yüzde Y").
  Future<void> announceNow() => _speakStatus();

  Future<void> _speakStatus() async {
    final parts = <String>[];
    if (_latest.speedKmh != null) {
      parts.add('hız ${_latest.speedKmh!.toStringAsFixed(0)}');
    }
    if (_latest.soc != null) {
      parts.add('batarya yüzde ${_latest.soc!.toStringAsFixed(0)}');
    }
    if (_latest.motorTempC != null) {
      parts.add('motor ${_latest.motorTempC!.toStringAsFixed(0)} derece');
    }
    if (parts.isNotEmpty) await speaker.speak(parts.join(', '));
  }

  Future<void> _onAlarm(AlarmEvent e) async {
    if (haptics) {
      if (e.severity == AlarmSeverity.critical) {
        await HapticFeedback.heavyImpact();
      } else {
        await HapticFeedback.mediumImpact();
      }
    }
    final shouldSpeak = e.isFault || (e.rule?.speak ?? true);
    if (shouldSpeak) {
      await speaker.speak(e.message,
          interrupt: e.severity == AlarmSeverity.critical);
    }
  }

  void dispose() {
    _statusTimer?.cancel();
    _sub?.cancel();
    engine.dispose();
    speaker.dispose();
  }
}
