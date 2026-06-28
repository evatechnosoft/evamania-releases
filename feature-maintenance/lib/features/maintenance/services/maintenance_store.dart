import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/maintenance_item.dart';

/// Persists maintenance items as a single JSON file. Seeds defaults on first run.
class MaintenanceStore {
  static const _fileName = 'maintenance.json';

  Future<File> _file() async {
    final base = await getApplicationDocumentsDirectory();
    return File('${base.path}/$_fileName');
  }

  Future<List<MaintenanceItem>> loadAll() async {
    final f = await _file();
    if (!await f.exists()) {
      final defs = MaintenanceItem.defaults();
      await saveAll(defs);
      return defs;
    }
    try {
      final list = jsonDecode(await f.readAsString()) as List;
      return list
          .map((e) => MaintenanceItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return MaintenanceItem.defaults();
    }
  }

  Future<void> saveAll(List<MaintenanceItem> items) async {
    final f = await _file();
    await f.writeAsString(
      jsonEncode(items.map((e) => e.toJson()).toList()),
      flush: true,
    );
  }

  Future<void> upsert(MaintenanceItem item) async {
    final all = await loadAll();
    final i = all.indexWhere((e) => e.id == item.id);
    if (i >= 0) {
      all[i] = item;
    } else {
      all.add(item);
    }
    await saveAll(all);
  }

  Future<void> delete(String id) async {
    final all = await loadAll();
    all.removeWhere((e) => e.id == id);
    await saveAll(all);
  }
}
