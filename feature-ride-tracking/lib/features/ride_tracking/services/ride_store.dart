import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/ride.dart';

/// Persists rides to the app documents directory and exports CSV/JSON.
///
/// Layout:
///   <docs>/rides/<id>.json      <- full ride (source of truth)
///   <docs>/rides/<id>.csv       <- per-point CSV (written on save())
///
/// JSON is the source of truth on reload; CSV is a sibling export for
/// spreadsheets / sharing. Both carry route + address info.
class RideStore {
  static const _dirName = 'rides';

  Future<Directory> _dir() async {
    final base = await getApplicationDocumentsDirectory();
    final d = Directory('${base.path}/$_dirName');
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  /// Writes both `<id>.json` and `<id>.csv`. Returns the JSON file.
  Future<File> save(Ride ride) async {
    final d = await _dir();
    final json = File('${d.path}/${ride.id}.json');
    await json.writeAsString(ride.toJsonString(), flush: true);
    final csv = File('${d.path}/${ride.id}.csv');
    await csv.writeAsString(ride.toCsv(), flush: true);
    return json;
  }

  /// Loads all saved rides, newest first.
  Future<List<Ride>> loadAll() async {
    final d = await _dir();
    final files = (await d.list().toList())
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'))
        .toList();
    final rides = <Ride>[];
    for (final f in files) {
      try {
        rides.add(Ride.fromJson(
            jsonDecode(await f.readAsString()) as Map<String, dynamic>));
      } catch (_) {
        // skip corrupt file
      }
    }
    rides.sort((a, b) => b.startTime.compareTo(a.startTime));
    return rides;
  }

  Future<void> delete(String id) async {
    final d = await _dir();
    for (final ext in ['json', 'csv']) {
      final f = File('${d.path}/$id.$ext');
      if (await f.exists()) await f.delete();
    }
  }

  /// Absolute path to a ride's CSV (for share_plus / open).
  Future<String> csvPath(String id) async => '${(await _dir()).path}/$id.csv';

  /// Absolute path to a ride's JSON.
  Future<String> jsonPath(String id) async => '${(await _dir()).path}/$id.json';
}
