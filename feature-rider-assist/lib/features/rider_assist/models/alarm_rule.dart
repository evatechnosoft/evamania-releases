import 'rider_telemetry.dart';

enum AlarmComparator { gt, gte, lt, lte }

enum AlarmSeverity { info, warning, critical }

/// A single threshold rule, e.g. "battery SOC < 20 % → warning, speak it".
class AlarmRule {
  final String id;
  final AlarmField field;
  final AlarmComparator comparator;
  final double threshold;
  final AlarmSeverity severity;

  /// Spoken/printed message. `{v}` is replaced with the live value, `{t}` with
  /// the threshold. If null, a default message is generated from the field.
  final String? message;

  /// Minimum time between re-firing the same rule.
  final Duration cooldown;

  /// Whether the voice assistant should speak this alarm.
  final bool speak;

  bool enabled;

  AlarmRule({
    required this.id,
    required this.field,
    required this.comparator,
    required this.threshold,
    this.severity = AlarmSeverity.warning,
    this.message,
    this.cooldown = const Duration(seconds: 30),
    this.speak = true,
    this.enabled = true,
  });

  bool _matches(double v) {
    switch (comparator) {
      case AlarmComparator.gt:
        return v > threshold;
      case AlarmComparator.gte:
        return v >= threshold;
      case AlarmComparator.lt:
        return v < threshold;
      case AlarmComparator.lte:
        return v <= threshold;
    }
  }

  /// Returns the triggering value if the rule fires for [t], else null.
  double? evaluate(RiderTelemetry t) {
    if (!enabled) return null;
    final v = t.value(field);
    if (v == null) return null;
    return _matches(v) ? v : null;
  }

  String renderMessage(double v) {
    final tmpl = message ?? _defaultTemplate();
    return tmpl
        .replaceAll('{v}', _fmt(v))
        .replaceAll('{t}', _fmt(threshold));
  }

  String _defaultTemplate() {
    final dir = (comparator == AlarmComparator.lt ||
            comparator == AlarmComparator.lte)
        ? 'düşük'
        : 'yüksek';
    return '${field.label} $dir: {v}';
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  Map<String, dynamic> toJson() => {
        'id': id,
        'field': field.name,
        'comparator': comparator.name,
        'threshold': threshold,
        'severity': severity.name,
        'message': message,
        'cooldownSec': cooldown.inSeconds,
        'speak': speak,
        'enabled': enabled,
      };

  factory AlarmRule.fromJson(Map<String, dynamic> j) => AlarmRule(
        id: j['id'] as String,
        field: AlarmField.values.byName(j['field'] as String),
        comparator: AlarmComparator.values.byName(j['comparator'] as String),
        threshold: (j['threshold'] as num).toDouble(),
        severity: AlarmSeverity.values.byName(j['severity'] as String),
        message: j['message'] as String?,
        cooldown: Duration(seconds: (j['cooldownSec'] as num?)?.toInt() ?? 30),
        speak: j['speak'] as bool? ?? true,
        enabled: j['enabled'] as bool? ?? true,
      );

  /// Sensible defaults for a typical EV two-wheeler. Tune per build / per pack.
  static List<AlarmRule> defaults() => [
        AlarmRule(
          id: 'soc_low',
          field: AlarmField.soc,
          comparator: AlarmComparator.lte,
          threshold: 20,
          severity: AlarmSeverity.warning,
          message: 'Batarya yüzde {v}',
        ),
        AlarmRule(
          id: 'soc_critical',
          field: AlarmField.soc,
          comparator: AlarmComparator.lte,
          threshold: 8,
          severity: AlarmSeverity.critical,
          message: 'Dikkat, batarya kritik, yüzde {v}',
          cooldown: const Duration(seconds: 60),
        ),
        AlarmRule(
          id: 'motor_temp_high',
          field: AlarmField.motorTempC,
          comparator: AlarmComparator.gte,
          threshold: 110,
          severity: AlarmSeverity.warning,
          message: 'Motor sıcaklığı yüksek, {v} derece',
        ),
        AlarmRule(
          id: 'ctrl_temp_high',
          field: AlarmField.controllerTempC,
          comparator: AlarmComparator.gte,
          threshold: 80,
          severity: AlarmSeverity.warning,
          message: 'Sürücü sıcaklığı yüksek, {v} derece',
        ),
        AlarmRule(
          id: 'cell_delta_high',
          field: AlarmField.cellDeltaMv,
          comparator: AlarmComparator.gte,
          threshold: 200,
          severity: AlarmSeverity.warning,
          message: 'Hücre dengesizliği, {v} milivolt',
          cooldown: const Duration(minutes: 2),
        ),
        AlarmRule(
          id: 'voltage_low',
          field: AlarmField.voltage,
          comparator: AlarmComparator.lte,
          threshold: 60,
          severity: AlarmSeverity.warning,
          message: 'Voltaj düşük, {v} volt',
        ),
      ];
}
