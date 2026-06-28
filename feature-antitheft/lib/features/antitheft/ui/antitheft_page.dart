import 'package:flutter/material.dart';

import '../models/antitheft_config.dart';
import '../services/antitheft_controller.dart';

/// Arm/disarm screen + sensitivity settings for the movement alarm.
class AntiTheftPage extends StatefulWidget {
  final AntiTheftController controller;
  final AntiTheftConfig config;
  final AntiTheftConfigStore store;

  const AntiTheftPage({
    super.key,
    required this.controller,
    required this.config,
    required this.store,
  });

  @override
  State<AntiTheftPage> createState() => _AntiTheftPageState();
}

class _AntiTheftPageState extends State<AntiTheftPage> {
  late AntiTheftConfig _c;

  @override
  void initState() {
    super.initState();
    _c = widget.config;
  }

  Future<void> _persist() async {
    await widget.store.save(_c);
    widget.controller.config = _c;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hareket Alarmı')),
      body: ListView(
        children: [
          StreamBuilder<AlarmState>(
            stream: widget.controller.stateStream,
            initialData: widget.controller.state,
            builder: (context, snap) {
              final s = snap.data ?? AlarmState.disarmed;
              return _statusHeader(s);
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Hassasiyet'),
            subtitle: Text('${_c.sensitivityG.toStringAsFixed(2)} g '
                '(düşük = daha hassas)'),
          ),
          Slider(
            min: 0.2,
            max: 1.2,
            divisions: 10,
            label: _c.sensitivityG.toStringAsFixed(2),
            value: _c.sensitivityG.clamp(0.2, 1.2),
            onChanged: (v) => setState(() => _c.sensitivityG = v),
            onChangeEnd: (_) => _persist(),
          ),
          SwitchListTile(
            title: const Text('GPS ile çekme algılama'),
            subtitle: Text('${_c.gpsRadiusM.toStringAsFixed(0)} m uzaklaşınca'),
            value: _c.useGps,
            onChanged: (v) {
              setState(() => _c.useGps = v);
              _persist();
            },
          ),
          if (_c.useGps)
            Slider(
              min: 10,
              max: 100,
              divisions: 9,
              label: '${_c.gpsRadiusM.toStringAsFixed(0)} m',
              value: _c.gpsRadiusM.clamp(10, 100),
              onChanged: (v) => setState(() => _c.gpsRadiusM = v),
              onChangeEnd: (_) => _persist(),
            ),
          ListTile(
            title: const Text('Giriş gecikmesi'),
            subtitle: Text('${_c.entryDelay.inSeconds} sn (iptal süresi)'),
          ),
          Slider(
            min: 0,
            max: 30,
            divisions: 6,
            label: '${_c.entryDelay.inSeconds} sn',
            value: _c.entryDelay.inSeconds.toDouble().clamp(0, 30),
            onChanged: (v) =>
                setState(() => _c.entryDelay = Duration(seconds: v.round())),
            onChangeEnd: (_) => _persist(),
          ),
          SwitchListTile(
            title: const Text('Alarmda bildir (SOS)'),
            subtitle: const Text('Tam alarmda konum/uyarı gönder'),
            value: _c.notifyOnAlarm,
            onChanged: (v) {
              setState(() => _c.notifyOnAlarm = v);
              _persist();
            },
          ),
        ],
      ),
    );
  }

  Widget _statusHeader(AlarmState s) {
    final (label, color, icon) = switch (s) {
      AlarmState.disarmed => ('Kapalı', Colors.grey, Icons.lock_open),
      AlarmState.armed => ('Korumada', Colors.green, Icons.lock),
      AlarmState.warning => ('Uyarı!', Colors.orange, Icons.warning_amber),
      AlarmState.alarming => ('ALARM!', Colors.red, Icons.notifications_active),
    };
    final armed = s != AlarmState.disarmed;
    return Container(
      color: color.withOpacity(0.12),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(icon, color: color, size: 64),
          const SizedBox(height: 8),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: armed ? Colors.red : Colors.green,
                minimumSize: const Size.fromHeight(56),
              ),
              icon: Icon(armed ? Icons.lock_open : Icons.lock),
              label: Text(armed ? 'ALARMI KAPAT' : 'KORUMAYA AL',
                  style: const TextStyle(fontSize: 18)),
              onPressed: () =>
                  armed ? widget.controller.disarm() : widget.controller.arm(),
            ),
          ),
        ],
      ),
    );
  }
}
