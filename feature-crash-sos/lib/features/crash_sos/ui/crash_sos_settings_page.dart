import 'package:flutter/material.dart';

import '../models/emergency_contact.dart';
import '../models/sos_config.dart';
import '../services/crash_sos_controller.dart';
import 'sos_countdown_dialog.dart';

/// Settings UI for crash detection + SOS: enable, contacts, sensitivity,
/// countdown, and a Test button that runs the full flow with a simulated crash.
class CrashSosSettingsPage extends StatefulWidget {
  final SosConfig config;
  final SosConfigStore store;

  /// Live controller so "Test" can exercise the real countdown + send path.
  final CrashSosController controller;

  const CrashSosSettingsPage({
    super.key,
    required this.config,
    required this.store,
    required this.controller,
  });

  @override
  State<CrashSosSettingsPage> createState() => _CrashSosSettingsPageState();
}

class _CrashSosSettingsPageState extends State<CrashSosSettingsPage> {
  late SosConfig _c;

  @override
  void initState() {
    super.initState();
    _c = widget.config;
  }

  Future<void> _persist() async {
    await widget.store.save(_c);
    widget.controller.config = _c;
    if (_c.enabled) {
      widget.controller.start();
    } else {
      widget.controller.stop();
    }
  }

  Future<void> _addContact() async {
    final c = await showDialog<EmergencyContact>(
      context: context,
      builder: (_) => const _ContactDialog(),
    );
    if (c != null) {
      setState(() => _c.contacts.add(c));
      await _persist();
    }
  }

  Future<void> _test() async {
    await SosCountdownDialog.show(
      context,
      countdown: _c.countdown,
      peakG: _c.impactG,
      onSend: () async {
        final msg = await widget.controller.composeAndSend();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Test gönderildi: ${msg.text}')),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kaza Algılama & SOS')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Kaza algılama açık'),
            subtitle: const Text('İvmeölçerle düşüş/darbe algıla'),
            value: _c.enabled,
            onChanged: (v) {
              setState(() => _c.enabled = v);
              _persist();
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Hassasiyet (darbe eşiği)'),
            subtitle: Text('${_c.impactG.toStringAsFixed(1)} g '
                '(düşük = daha hassas)'),
          ),
          Slider(
            min: 3,
            max: 8,
            divisions: 10,
            label: '${_c.impactG.toStringAsFixed(1)} g',
            value: _c.impactG.clamp(3, 8),
            onChanged: (v) => setState(() => _c.impactG = v),
            onChangeEnd: (_) => _persist(),
          ),
          ListTile(
            title: const Text('Geri sayım'),
            subtitle: Text('${_c.countdown.inSeconds} sn'),
          ),
          Slider(
            min: 5,
            max: 60,
            divisions: 11,
            label: '${_c.countdown.inSeconds} sn',
            value: _c.countdown.inSeconds.toDouble().clamp(5, 60),
            onChanged: (v) =>
                setState(() => _c.countdown = Duration(seconds: v.round())),
            onChangeEnd: (_) => _persist(),
          ),
          SwitchListTile(
            title: const Text('Sadece hareket halindeyken'),
            subtitle: const Text('Park halinde düşen telefonu yok say'),
            value: _c.requirePriorMotion,
            onChanged: (v) {
              setState(() => _c.requirePriorMotion = v);
              _persist();
            },
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                Text('Acil Kişiler',
                    style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Ekle'),
                  onPressed: _addContact,
                ),
              ],
            ),
          ),
          if (_c.contacts.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Henüz acil kişi yok'),
            ),
          for (var i = 0; i < _c.contacts.length; i++)
            ListTile(
              leading: const Icon(Icons.person),
              title: Text(_c.contacts[i].name),
              subtitle: Text(_c.contacts[i].phone),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  setState(() => _c.contacts.removeAt(i));
                  await _persist();
                },
              ),
            ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text('Testi çalıştır'),
              onPressed: _c.contacts.isEmpty ? null : _test,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactDialog extends StatefulWidget {
  const _ContactDialog();
  @override
  State<_ContactDialog> createState() => _ContactDialogState();
}

class _ContactDialogState extends State<_ContactDialog> {
  final _name = TextEditingController();
  final _phone = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Acil Kişi Ekle'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'İsim'),
          ),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration:
                const InputDecoration(labelText: 'Telefon (+90...)'),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Vazgeç')),
        FilledButton(
          onPressed: () {
            if (_name.text.trim().isEmpty || _phone.text.trim().isEmpty) return;
            Navigator.pop(
              context,
              EmergencyContact(
                  name: _name.text.trim(), phone: _phone.text.trim()),
            );
          },
          child: const Text('Ekle'),
        ),
      ],
    );
  }
}
