import 'package:flutter/material.dart';

import '../models/maintenance_item.dart';
import '../services/maintenance_store.dart';

/// Km-based maintenance reminders. Pass the current odometer ([currentOdoKm]) —
/// e.g. the controller's odo, or lifetime total distance from the ride module.
class MaintenancePage extends StatefulWidget {
  final double currentOdoKm;
  const MaintenancePage({super.key, required this.currentOdoKm});

  @override
  State<MaintenancePage> createState() => _MaintenancePageState();
}

class _MaintenancePageState extends State<MaintenancePage> {
  final _store = MaintenanceStore();
  late Future<List<MaintenanceItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = _store.loadAll();
  }

  void _reload() => setState(() => _future = _store.loadAll());

  Future<void> _edit([MaintenanceItem? item]) async {
    final result = await showDialog<MaintenanceItem>(
      context: context,
      builder: (_) => _EditDialog(item: item, currentOdoKm: widget.currentOdoKm),
    );
    if (result != null) {
      await _store.upsert(result);
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bakım'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text('Güncel: ${widget.currentOdoKm.toStringAsFixed(0)} km',
                style: const TextStyle(color: Colors.white70)),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _edit(),
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<MaintenanceItem>>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data!.where((e) => e.enabled).toList();
          if (items.isEmpty) {
            return const Center(child: Text('Bakım öğesi yok'));
          }
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [for (final it in items) _tile(it)],
          );
        },
      ),
    );
  }

  Widget _tile(MaintenanceItem it) {
    final odo = widget.currentOdoKm;
    final remaining = it.remainingKm(odo);
    final due = it.isDue(odo);
    final progress = it.progress(odo);
    final color = due
        ? Colors.red
        : (progress > 0.8 ? Colors.orange : Colors.green);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(due ? Icons.warning_amber_rounded : Icons.build, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(it.name,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () => _edit(it),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () async {
                    await _store.delete(it.id);
                    _reload();
                  },
                ),
              ],
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: progress,
              color: color,
              backgroundColor: color.withOpacity(0.15),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(due
                    ? '${(-remaining).toStringAsFixed(0)} km gecikti'
                    : '${remaining.toStringAsFixed(0)} km kaldı'),
                Text('her ${it.intervalKm.toStringAsFixed(0)} km',
                    style: const TextStyle(color: Colors.grey)),
              ],
            ),
            if (it.note != null && it.note!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(it.note!,
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.check_circle, size: 18),
                label: const Text('Servis yapıldı'),
                onPressed: () async {
                  it.markServiced(odo);
                  await _store.upsert(it);
                  _reload();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditDialog extends StatefulWidget {
  final MaintenanceItem? item;
  final double currentOdoKm;
  const _EditDialog({this.item, required this.currentOdoKm});

  @override
  State<_EditDialog> createState() => _EditDialogState();
}

class _EditDialogState extends State<_EditDialog> {
  late TextEditingController _name;
  late TextEditingController _interval;
  late TextEditingController _note;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.item?.name ?? '');
    _interval =
        TextEditingController(text: widget.item?.intervalKm.toStringAsFixed(0) ?? '');
    _note = TextEditingController(text: widget.item?.note ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _interval.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.item == null ? 'Bakım Ekle' : 'Bakım Düzenle'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'İsim'),
          ),
          TextField(
            controller: _interval,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Aralık (km)'),
          ),
          TextField(
            controller: _note,
            decoration: const InputDecoration(labelText: 'Not (opsiyonel)'),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Vazgeç')),
        FilledButton(
          onPressed: () {
            final interval = double.tryParse(_interval.text) ?? 0;
            if (_name.text.trim().isEmpty || interval <= 0) return;
            final item = widget.item ??
                MaintenanceItem(
                  id: 'mnt_${DateTime.now().millisecondsSinceEpoch}',
                  name: '',
                  intervalKm: 0,
                  lastServiceKm: widget.currentOdoKm,
                );
            item
              ..name = _name.text.trim()
              ..intervalKm = interval
              ..note = _note.text.trim().isEmpty ? null : _note.text.trim();
            Navigator.pop(context, item);
          },
          child: const Text('Kaydet'),
        ),
      ],
    );
  }
}
