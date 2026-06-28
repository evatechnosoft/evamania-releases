import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'emergency_contact.dart';

/// User-tunable crash-detection + SOS settings.
class SosConfig {
  bool enabled;

  /// Impact magnitude (in g) above which a crash candidate fires.
  /// ~3.5–6 g is a reasonable two-wheeler range; higher = less sensitive.
  double impactG;

  /// Only treat an impact as a crash if the vehicle was moving recently
  /// (avoids false positives from a dropped phone while parked).
  bool requirePriorMotion;
  Duration priorMotionWindow;

  /// Grace period for the rider to cancel before the SOS is sent.
  Duration countdown;

  List<EmergencyContact> contacts;

  /// Message template. `{maps}` → maps link, `{coords}` → "lat, lng".
  String messageTemplate;

  SosConfig({
    this.enabled = false,
    this.impactG = 4.5,
    this.requirePriorMotion = true,
    this.priorMotionWindow = const Duration(seconds: 10),
    this.countdown = const Duration(seconds: 20),
    List<EmergencyContact>? contacts,
    this.messageTemplate =
        'Otomatik kaza uyarısı: bir kaza algılanmış olabilir. Konumum: {maps}',
  }) : contacts = contacts ?? <EmergencyContact>[];

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'impactG': impactG,
        'requirePriorMotion': requirePriorMotion,
        'priorMotionWindowSec': priorMotionWindow.inSeconds,
        'countdownSec': countdown.inSeconds,
        'contacts': contacts.map((c) => c.toJson()).toList(),
        'messageTemplate': messageTemplate,
      };

  factory SosConfig.fromJson(Map<String, dynamic> j) => SosConfig(
        enabled: j['enabled'] as bool? ?? false,
        impactG: (j['impactG'] as num?)?.toDouble() ?? 4.5,
        requirePriorMotion: j['requirePriorMotion'] as bool? ?? true,
        priorMotionWindow:
            Duration(seconds: (j['priorMotionWindowSec'] as num?)?.toInt() ?? 10),
        countdown: Duration(seconds: (j['countdownSec'] as num?)?.toInt() ?? 20),
        contacts: ((j['contacts'] as List?) ?? const [])
            .map((e) => EmergencyContact.fromJson(e as Map<String, dynamic>))
            .toList(),
        messageTemplate: j['messageTemplate'] as String? ??
            'Otomatik kaza uyarısı: bir kaza algılanmış olabilir. Konumum: {maps}',
      );
}

/// Persists [SosConfig] to a small JSON file.
class SosConfigStore {
  static const _fileName = 'sos_config.json';

  Future<File> _file() async {
    final base = await getApplicationDocumentsDirectory();
    return File('${base.path}/$_fileName');
  }

  Future<SosConfig> load() async {
    final f = await _file();
    if (!await f.exists()) return SosConfig();
    try {
      return SosConfig.fromJson(
          jsonDecode(await f.readAsString()) as Map<String, dynamic>);
    } catch (_) {
      return SosConfig();
    }
  }

  Future<void> save(SosConfig c) async {
    final f = await _file();
    await f.writeAsString(jsonEncode(c.toJson()), flush: true);
  }
}
