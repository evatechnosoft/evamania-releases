// EvaISYS backend istemcisi (REST).
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/vehicle.dart';

class EvaISYSApi {
  final String base;
  EvaISYSApi({String? base}) : base = base ?? Config.apiBase;

  Future<List<Vehicle>> fetchVehicles() async {
    final res = await http.get(Uri.parse('$base/api/vehicles'));
    if (res.statusCode != 200) {
      throw Exception('Araçlar alınamadı (${res.statusCode})');
    }
    final list = jsonDecode(res.body) as List<dynamic>;
    return list
        .map((e) => Vehicle.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Vehicle> fetchVehicle(String id) async {
    final res = await http.get(Uri.parse('$base/api/vehicles/$id'));
    if (res.statusCode != 200) {
      throw Exception('Araç alınamadı (${res.statusCode})');
    }
    return Vehicle.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<void> sendCommand(String id, String type, {bool? value}) async {
    final res = await http.post(
      Uri.parse('$base/api/vehicles/$id/command'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'type': type, 'value': value}),
    );
    if (res.statusCode != 200) {
      throw Exception('Komut gönderilemedi (${res.statusCode})');
    }
  }
}
