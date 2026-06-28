import 'dart:async';

import '../models/alarm_rule.dart';
import '../models/rider_telemetry.dart';

/// Fired when a rule trips (or a new fault appears).
class AlarmEvent {
  final AlarmRule? rule;
  final double? value;
  final AlarmSeverity severity;
  final String message;
  final DateTime time;

  const AlarmEvent({
    required this.rule,
    required this.value,
    required this.severity,
    required this.message,
    required this.time,
  });

  bool get isFault => rule == null;
}

/// Evaluates [RiderTelemetry] against a set of [AlarmRule]s with per-rule
/// cooldown debouncing, and surfaces newly-appeared controller faults.
class AlarmEngine {
  AlarmEngine({List<AlarmRule>? rules}) : rules = rules ?? AlarmRule.defaults();

  final List<AlarmRule> rules;
  final _controller = StreamController<AlarmEvent>.broadcast();
  final Map<String, DateTime> _lastFired = {};
  Set<String> _knownFaults = {};

  Stream<AlarmEvent> get events => _controller.stream;

  /// Evaluate one snapshot. Call on every telemetry update. [now] injectable
  /// for testing.
  void evaluate(RiderTelemetry t, {DateTime? now}) {
    final at = now ?? DateTime.now();

    for (final rule in rules) {
      final v = rule.evaluate(t);
      if (v == null) continue;
      final last = _lastFired[rule.id];
      if (last != null && at.difference(last) < rule.cooldown) continue;
      _lastFired[rule.id] = at;
      _controller.add(AlarmEvent(
        rule: rule,
        value: v,
        severity: rule.severity,
        message: rule.renderMessage(v),
        time: at,
      ));
    }

    // New faults (not seen in the previous snapshot) are announced once.
    final current = t.faults.toSet();
    final fresh = current.difference(_knownFaults);
    for (final f in fresh) {
      _controller.add(AlarmEvent(
        rule: null,
        value: null,
        severity: AlarmSeverity.critical,
        message: 'Arıza: $f',
        time: at,
      ));
    }
    _knownFaults = current;
  }

  /// Clears cooldowns + fault memory (e.g. on a new ride / reconnect).
  void reset() {
    _lastFired.clear();
    _knownFaults = {};
  }

  void dispose() => _controller.close();
}
