import 'dart:convert';

/// A named, reusable set of controller tuning parameters.
///
/// Deliberately controller-agnostic: [params] is a free-form map of
/// parameter-key → value, so it works for FarDriver / Votol / JK / any source.
/// The app maps these keys to actual BLE writes in its `onApply` callback —
/// this module just stores, edits, shares and lists presets.
class TuningPreset {
  final String id;
  String name;

  /// e.g. "FarDriver", "Votol", "JK" — free text; used for filtering/labeling.
  String controllerType;

  /// Parameter key → value (e.g. {'phaseCurrent': 380, 'speedLimit': 90}).
  Map<String, num> params;

  /// Optional free note ("yağmur modu", "şehir içi" vb.).
  String? note;

  /// Optional ARGB color for the card.
  int? colorValue;

  final DateTime createdAt;
  DateTime updatedAt;

  TuningPreset({
    required this.id,
    required this.name,
    this.controllerType = '',
    Map<String, num>? params,
    this.note,
    this.colorValue,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : params = params ?? <String, num>{},
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  TuningPreset copy() => TuningPreset(
        id: id,
        name: name,
        controllerType: controllerType,
        params: Map<String, num>.from(params),
        note: note,
        colorValue: colorValue,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'controllerType': controllerType,
        'params': params,
        'note': note,
        'colorValue': colorValue,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
      };

  factory TuningPreset.fromJson(Map<String, dynamic> j) => TuningPreset(
        id: j['id'] as String,
        name: j['name'] as String,
        controllerType: j['controllerType'] as String? ?? '',
        params: ((j['params'] as Map?) ?? const {})
            .map((k, v) => MapEntry(k as String, v as num)),
        note: j['note'] as String?,
        colorValue: (j['colorValue'] as num?)?.toInt(),
        createdAt: j['createdAt'] != null
            ? DateTime.parse(j['createdAt'] as String).toLocal()
            : null,
        updatedAt: j['updatedAt'] != null
            ? DateTime.parse(j['updatedAt'] as String).toLocal()
            : null,
      );

  /// Compact share payload (for QR / clipboard). Versioned so a future format
  /// can be detected.
  String toShareString() => jsonEncode({'v': 1, 'preset': toJson()});

  /// Parses a payload produced by [toShareString]; throws on bad data.
  factory TuningPreset.fromShareString(String s) {
    final m = jsonDecode(s) as Map<String, dynamic>;
    final p = (m['preset'] ?? m) as Map<String, dynamic>;
    return TuningPreset.fromJson(p);
  }

  /// Keys that differ from [other] (for "what will change?" confirmation).
  Map<String, num> diffFrom(TuningPreset other) {
    final out = <String, num>{};
    params.forEach((k, v) {
      if (other.params[k] != v) out[k] = v;
    });
    return out;
  }
}
