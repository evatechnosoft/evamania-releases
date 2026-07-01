// EvaISYS — Flutter MVP uygulaması
// Araç listesi + detay ekranı; telemetri gösterimi ve uzaktan komutlar.
import 'dart:async';
import 'package:flutter/material.dart';
import 'config.dart';
import 'models/vehicle.dart';
import 'services/api.dart';

void main() => runApp(const EvaISYSApp());

class EvaISYSApp extends StatelessWidget {
  const EvaISYSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EvaISYS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF35D07F),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0E1116),
      ),
      home: const LoginScreen(),
    );
  }
}

/// Giriş ekranı — JWT alır, başarılıysa filo ekranına geçer.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _api = EvaISYSApi();
  final _user = TextEditingController(text: 'admin');
  final _pass = TextEditingController(text: 'admin123');
  bool _busy = false;
  String? _error;

  Future<void> _submit() async {
    setState(() { _busy = true; _error = null; });
    try {
      final ok = await _api.login(_user.text, _pass.text);
      if (!ok) {
        setState(() => _error = 'Kullanıcı adı veya parola hatalı');
      } else if (mounted) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => FleetScreen(api: _api)));
      }
    } catch (e) {
      setState(() => _error = 'Bağlantı hatası: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('⚡ EvaISYS',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('Araç İzleme ve Kontrol',
                  style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 28),
              TextField(
                controller: _user,
                decoration: const InputDecoration(
                    labelText: 'Kullanıcı adı', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _pass,
                obscureText: true,
                decoration: const InputDecoration(
                    labelText: 'Parola', border: OutlineInputBorder()),
                onSubmitted: (_) => _submit(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.redAccent)),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _busy ? null : _submit,
                style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50)),
                child: _busy
                    ? const CircularProgressIndicator()
                    : const Text('Giriş'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Araç listesi ekranı — periyodik telemetri yenilemesi.
class FleetScreen extends StatefulWidget {
  final EvaISYSApi api;
  const FleetScreen({super.key, required this.api});
  @override
  State<FleetScreen> createState() => _FleetScreenState();
}

class _FleetScreenState extends State<FleetScreen> {
  EvaISYSApi get _api => widget.api;
  List<Vehicle> _vehicles = [];
  String? _error;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _refresh();
    _timer = Timer.periodic(Config.pollInterval, (_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final list = await _api.fetchVehicles();
      if (mounted) setState(() { _vehicles = list; _error = null; });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('⚡ EvaISYS — Araçlar'),
        backgroundColor: const Color(0xFF171C24),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Çıkış',
            onPressed: () {
              _api.logout();
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _error != null && _vehicles.isEmpty
            ? ListView(children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Bağlantı hatası:\n$_error',
                      style: const TextStyle(color: Colors.redAccent)),
                )
              ])
            : ListView.builder(
                itemCount: _vehicles.length,
                itemBuilder: (_, i) => _VehicleCard(
                  vehicle: _vehicles[i],
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VehicleDetailScreen(
                          vehicleId: _vehicles[i].vehicleId, api: _api),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback onTap;
  const _VehicleCard({required this.vehicle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1E2530),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        onTap: onTap,
        leading: Icon(Icons.electric_moped,
            color: vehicle.online ? const Color(0xFF35D07F) : Colors.grey),
        title: Text(vehicle.vehicleId,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
            '${vehicle.speedKph.toStringAsFixed(0)} km/s • '
            '%${vehicle.batteryPct.toStringAsFixed(0)} • '
            '${vehicle.locked ? "🔒" : "🔓"}'
            '${vehicle.immobilized ? " ⛔" : ""}'
            '${vehicle.alarm ? " 🚨" : ""}'),
        trailing: Text(vehicle.online ? 'çevrimiçi' : 'çevrimdışı',
            style: TextStyle(
                color: vehicle.online ? const Color(0xFF35D07F) : Colors.grey,
                fontSize: 12)),
      ),
    );
  }
}

/// Araç detay + uzaktan kontrol ekranı.
class VehicleDetailScreen extends StatefulWidget {
  final String vehicleId;
  final EvaISYSApi api;
  const VehicleDetailScreen(
      {super.key, required this.vehicleId, required this.api});
  @override
  State<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen> {
  Vehicle? _v;
  Timer? _timer;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _refresh();
    _timer = Timer.periodic(Config.pollInterval, (_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final v = await widget.api.fetchVehicle(widget.vehicleId);
      if (mounted) setState(() => _v = v);
    } catch (_) {}
  }

  Future<void> _cmd(String type, {bool? value}) async {
    setState(() => _busy = true);
    try {
      await widget.api.sendCommand(widget.vehicleId, type, value: value);
      await _refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = _v;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.vehicleId),
        backgroundColor: const Color(0xFF171C24),
      ),
      body: v == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _metric('${v.speedKph.toStringAsFixed(0)}', 'km/s'),
                    _metric('%${v.batteryPct.toStringAsFixed(0)}', 'batarya'),
                    _metric(v.voltage.toStringAsFixed(1), 'volt'),
                    _metric(v.odometerKm.toStringAsFixed(0), 'km'),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(spacing: 8, children: [
                  _badge(v.locked ? '🔒 kilitli' : '🔓 açık', v.locked),
                  _badge(v.immobilized ? '⛔ immobilize' : 'motor serbest',
                      !v.immobilized),
                  _badge(v.alarm ? '🚨 alarm' : 'alarm kapalı', !v.alarm),
                  if (v.lat != null)
                    _badge(
                        '📍 ${v.lat!.toStringAsFixed(4)}, ${v.lng!.toStringAsFixed(4)}',
                        true),
                ]),
                const SizedBox(height: 20),
                _cmdButton(v.locked ? 'Kilidi Aç' : 'Kilitle', Icons.lock,
                    () => _cmd('lock', value: !v.locked)),
                _cmdButton(
                    v.immobilized ? 'Motoru Serbest Bırak' : 'Immobilize Et',
                    Icons.block,
                    () => _cmd('immobilize', value: !v.immobilized),
                    danger: !v.immobilized),
                _cmdButton(v.alarm ? 'Alarmı Kapat' : 'Alarmı Çal',
                    Icons.notifications_active,
                    () => _cmd('alarm', value: !v.alarm),
                    danger: !v.alarm),
                _cmdButton('Konum İste (beep)', Icons.my_location,
                    () => _cmd('locate')),
              ],
            ),
    );
  }

  Widget _metric(String value, String label) => Column(children: [
        Text(value,
            style:
                const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        Text(label,
            style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ]);

  Widget _badge(String text, bool good) => Chip(
        label: Text(text, style: const TextStyle(fontSize: 12)),
        backgroundColor:
            good ? const Color(0xFF16321F) : const Color(0xFF3A1414),
      );

  Widget _cmdButton(String label, IconData icon, VoidCallback onTap,
          {bool danger = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: FilledButton.icon(
          onPressed: _busy ? null : onTap,
          icon: Icon(icon),
          label: Text(label),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            backgroundColor:
                danger ? const Color(0xFFFF5A5A) : const Color(0xFF2F9BFF),
          ),
        ),
      );
}
