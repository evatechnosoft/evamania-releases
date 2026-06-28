import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// User-tunable anti-theft (movement alarm) settings.
class AntiTheftConfig {
  bool enabled;

  /// Accelerometer deviation from rest (in g) that counts as tampering.
  /// ~0.25 (sensitive) … ~1.0 (only hard movement).
  double sensitivityG;

  /// Also trip the alarm if the vehicle is dragged/towed beyond this many
  /// meters from the armed position (GPS).
  bool useGps;
  double gpsRadiusM;

  /// Warning window before the full siren — lets the owner disarm.
  Duration entryDelay;

  /// Asset path of the siren sound (looped), e.g. 'assets/sounds/siren.mp3'.
  /// Null → no audio, haptics only.
  String? sirenAsset;

  /// Notify emergency/owner (via the injected onTheft callback) on full alarm.
  bool notifyOnAlarm;

  AntiTheftConfig({
    this.enabled = false,
    this.sensitivityG = 0.35,
    this.useGps = true,
    this.gpsRadiusM = 25,
    this.entryDelay = const Duration(seconds: 8),
    this.sirenAsset,
    this.notifyOnAlarm = true,
  });

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'sensitivityG': sensitivityG,
        'useGps': useGps,
        'gpsRadiusM': gpsRadiusM,
        'entryDelaySec': entryDelay.inSeconds,
        'sirenAsset': sirenAsset,
        'notifyOnAlarm': notifyOnAlarm,
      };

  factory AntiTheftConfig.fromJson(Map<String, dynamic> j) => AntiTheftConfig(
        enabled: j['enabled'] as bool? ?? false,
        sensitivityG: (j['sensitivityG'] as num?)?.toDouble() ?? 0.35,
        useGps: j['useGps'] as bool? ?? true,
        gpsRadiusM: (j['gpsRadiusM'] as num?)?.toDouble() ?? 25,
        entryDelay: Duration(seconds: (j['entryDelaySec'] as num?)?.toInt() ?? 8),
        sirenAsset: j['sirenAsset'] as String?,
        notifyOnAlarm: j['notifyOnAlarm'] as bool? ?? true,
      );
}

/// Persists [AntiTheftConfig] to a small JSON file.
class AntiTheftConfigStore {
  static const _fileName = 'antitheft_config.json';

  Future<File> _file() async {
    final base = await getApplicationDocumentsDirectory();
    return File('${base.path}/$_fileName');
  }

  Future<AntiTheftConfig> load() async {
    final f = await _file();
    if (!await f.exists()) return AntiTheftConfig();
    try {
      return AntiTheftConfig.fromJson(
          jsonDecode(await f.readAsString()) as Map<String, dynamic>);
    } catch (_) {
      return AntiTheftConfig();
    }
  }

  Future<void> save(AntiTheftConfig c) async {
    final f = await _file();
    await f.writeAsString(jsonEncode(c.toJson()), flush: true);
  }
}
