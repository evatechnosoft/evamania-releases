import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/tuning_preset.dart';

/// Persists tuning presets as a single JSON file in app documents, with
/// import/export helpers for sharing.
class PresetStore {
  static const _fileName = 'tuning_presets.json';

  Future<File> _file() async {
    final base = await getApplicationDocumentsDirectory();
    return File('${base.path}/$_fileName');
  }

  Future<List<TuningPreset>> loadAll() async {
    final f = await _file();
    if (!await f.exists()) return [];
    try {
      final list = jsonDecode(await f.readAsString()) as List;
      final presets = list
          .map((e) => TuningPreset.fromJson(e as Map<String, dynamic>))
          .toList();
      presets.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return presets;
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveAll(List<TuningPreset> presets) async {
    final f = await _file();
    await f.writeAsString(
      jsonEncode(presets.map((p) => p.toJson()).toList()),
      flush: true,
    );
  }

  /// Insert or update by id.
  Future<void> upsert(TuningPreset preset) async {
    preset.updatedAt = DateTime.now();
    final all = await loadAll();
    final i = all.indexWhere((p) => p.id == preset.id);
    if (i >= 0) {
      all[i] = preset;
    } else {
      all.add(preset);
    }
    await _saveAll(all);
  }

  Future<void> delete(String id) async {
    final all = await loadAll();
    all.removeWhere((p) => p.id == id);
    await _saveAll(all);
  }

  /// Writes a single preset to a shareable `.json` file, returns its path.
  Future<String> exportToFile(TuningPreset preset) async {
    final base = await getApplicationDocumentsDirectory();
    final safe = preset.name.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    final f = File('${base.path}/preset_$safe.json');
    await f.writeAsString(preset.toShareString(), flush: true);
    return f.path;
  }

  /// Imports a preset from a share payload, giving it a fresh id to avoid
  /// clobbering an existing one, then saves it.
  Future<TuningPreset> importFromShareString(String payload) async {
    final p = TuningPreset.fromShareString(payload);
    final fresh = TuningPreset(
      id: 'preset_${DateTime.now().millisecondsSinceEpoch}',
      name: p.name,
      controllerType: p.controllerType,
      params: p.params,
      note: p.note,
      colorValue: p.colorValue,
    );
    await upsert(fresh);
    return fresh;
  }
}
