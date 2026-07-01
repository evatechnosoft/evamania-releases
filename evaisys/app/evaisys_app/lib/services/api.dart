// EvaISYS backend istemcisi (REST).
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/vehicle.dart';

class EvaISYSApi {
  final String base;
  String? _token; // oturum JWT'si

  EvaISYSApi({String? base}) : base = base ?? Config.apiBase;

  bool get isAuthenticated => _token != null;
  void logout() => _token = null;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  /// Kullanıcı adı/parola ile giriş; başarılıysa token saklanır.
  Future<bool> login(String username, String password) async {
    final res = await http.post(
      Uri.parse('$base/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    if (res.statusCode != 200) return false;
    _token = (jsonDecode(res.body) as Map<String, dynamic>)['token'] as String?;
    return _token != null;
  }

  Future<List<Vehicle>> fetchVehicles() async {
    final res = await http.get(Uri.parse('$base/api/vehicles'), headers: _headers);
    if (res.statusCode != 200) {
      throw Exception('Araçlar alınamadı (${res.statusCode})');
    }
    final list = jsonDecode(res.body) as List<dynamic>;
    return list
        .map((e) => Vehicle.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Vehicle> fetchVehicle(String id) async {
    final res = await http.get(Uri.parse('$base/api/vehicles/$id'), headers: _headers);
    if (res.statusCode != 200) {
      throw Exception('Araç alınamadı (${res.statusCode})');
    }
    return Vehicle.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<void> sendCommand(String id, String type, {bool? value}) async {
    final res = await http.post(
      Uri.parse('$base/api/vehicles/$id/command'),
      headers: _headers,
      body: jsonEncode({'type': type, 'value': value}),
    );
    if (res.statusCode != 200) {
      throw Exception('Komut gönderilemedi (${res.statusCode})');
    }
  }
}
