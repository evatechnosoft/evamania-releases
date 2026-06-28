import 'package:flutter/material.dart';

import '../models/tuning_preset.dart';

/// Create or edit a preset: name, controller type, note, and a key/value editor
/// for the tuning parameters.
class PresetEditPage extends StatefulWidget {
  /// Existing preset to edit, or null to create a new one.
  final TuningPreset? preset;

  /// Optional list of known parameter keys to suggest while typing.
  final List<String> knownKeys;

  const PresetEditPage({super.key, this.preset, this.knownKeys = const []});

  @override
  State<PresetEditPage> createState() => _PresetEditPageState();
}

class _PresetEditPageState extends State<PresetEditPage> {
  late TextEditingController _name;
  late TextEditingController _type;
  late TextEditingController _note;
  late List<MapEntry<String, num>> _params;

  @override
  void initState() {
    super.initState();
    final p = widget.preset;
    _name = TextEditingController(text: p?.name ?? '');
    _type = TextEditingController(text: p?.controllerType ?? '');
    _note = TextEditingController(text: p?.note ?? '');
    _params = p?.params.entries.toList() ?? <MapEntry<String, num>>[];
  }

  @override
  void dispose() {
    _name.dispose();
    _type.dispose();
    _note.dispose();
    super.dispose();
  }

  void _save() {
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İsim gerekli')),
      );
      return;
    }
    final params = <String, num>{};
    for (final e in _params) {
      if (e.key.trim().isNotEmpty) params[e.key.trim()] = e.value;
    }
    final result = (widget.preset ??
        TuningPreset(
          id: 'preset_${DateTime.now().millisecondsSinceEpoch}',
          name: '',
        ))
      ..name = _name.text.trim()
      ..controllerType = _type.text.trim()
      ..note = _note.text.trim().isEmpty ? null : _note.text.trim()
      ..params = params;
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.preset == null ? 'Yeni Preset' : 'Preset Düzenle'),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: _save),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'İsim'),
          ),
          TextField(
            controller: _type,
            decoration: const InputDecoration(
                labelText: 'Kontrolcü tipi (FarDriver/Votol/JK...)'),
          ),
          TextField(
            controller: _note,
            decoration: const InputDecoration(labelText: 'Not (opsiyonel)'),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text('Parametreler',
                  style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              TextButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Ekle'),
                onPressed: () => setState(
                    () => _params.add(const MapEntry('', 0))),
              ),
            ],
          ),
          for (var i = 0; i < _params.length; i++) _paramRow(i),
        ],
      ),
    );
  }

  Widget _paramRow(int i) {
    final e = _params[i];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextFormField(
              initialValue: e.key,
              decoration: const InputDecoration(labelText: 'Anahtar'),
              onChanged: (v) =>
                  _params[i] = MapEntry(v, _params[i].value),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextFormField(
              initialValue: '${e.value}',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true, signed: true),
              decoration: const InputDecoration(labelText: 'Değer'),
              onChanged: (v) => _params[i] =
                  MapEntry(_params[i].key, num.tryParse(v) ?? 0),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => setState(() => _params.removeAt(i)),
          ),
        ],
      ),
    );
  }
}
