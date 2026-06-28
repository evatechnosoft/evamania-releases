import 'package:flutter/material.dart';

import '../models/tuning_preset.dart';
import '../services/preset_store.dart';
import 'preset_edit_page.dart';
import 'preset_qr_page.dart';

/// One-tap tuning-preset manager: list, apply, edit, delete, share via QR,
/// import via scan.
///
/// [onApply] is where the app turns a preset into real BLE writes to the
/// controller — this module never talks BLE itself.
class PresetListPage extends StatefulWidget {
  /// Called when the user taps "Uygula". Return when the writes are done.
  final Future<void> Function(TuningPreset preset)? onApply;

  /// Known parameter keys to suggest in the editor.
  final List<String> knownKeys;

  const PresetListPage({super.key, this.onApply, this.knownKeys = const []});

  @override
  State<PresetListPage> createState() => _PresetListPageState();
}

class _PresetListPageState extends State<PresetListPage> {
  final _store = PresetStore();
  late Future<List<TuningPreset>> _future;

  @override
  void initState() {
    super.initState();
    _future = _store.loadAll();
  }

  void _reload() => setState(() => _future = _store.loadAll());

  Future<void> _edit([TuningPreset? p]) async {
    final result = await Navigator.of(context).push<TuningPreset>(
      MaterialPageRoute(
        builder: (_) => PresetEditPage(preset: p, knownKeys: widget.knownKeys),
      ),
    );
    if (result != null) {
      await _store.upsert(result);
      _reload();
    }
  }

  Future<void> _scanImport() async {
    final scanned = await Navigator.of(context).push<TuningPreset>(
      MaterialPageRoute(builder: (_) => const PresetScanPage()),
    );
    if (scanned != null) {
      await _store.importFromShareString(scanned.toShareString());
      _reload();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${scanned.name}" içe aktarıldı')),
        );
      }
    }
  }

  Future<void> _apply(TuningPreset p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${p.name} uygulansın mı?'),
        content: Text(
            '${p.params.length} parametre kontrolcüye yazılacak.'
            '${p.controllerType.isNotEmpty ? '\nKontrolcü: ${p.controllerType}' : ''}'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Vazgeç')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Uygula')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await widget.onApply?.call(p);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${p.name}" uygulandı')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Uygulanamadı: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tuning Presetleri'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Preset Tara',
            onPressed: _scanImport,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _edit(),
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<TuningPreset>>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final presets = snap.data!;
          if (presets.isEmpty) {
            return const Center(child: Text('Henüz preset yok'));
          }
          return ListView.separated(
            itemCount: presets.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) => _tile(presets[i]),
          );
        },
      ),
    );
  }

  Widget _tile(TuningPreset p) {
    return Dismissible(
      key: ValueKey(p.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) async {
        await _store.delete(p.id);
        _reload();
      },
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              p.colorValue != null ? Color(p.colorValue!) : null,
          child: const Icon(Icons.tune),
        ),
        title: Text(p.name),
        subtitle: Text([
          if (p.controllerType.isNotEmpty) p.controllerType,
          '${p.params.length} parametre',
          if (p.note != null) p.note!,
        ].join(' · ')),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.qr_code),
              tooltip: 'QR paylaş',
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => PresetQrPage(preset: p),
              )),
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _edit(p),
            ),
            FilledButton(
              onPressed: () => _apply(p),
              child: const Text('Uygula'),
            ),
          ],
        ),
      ),
    );
  }
}
