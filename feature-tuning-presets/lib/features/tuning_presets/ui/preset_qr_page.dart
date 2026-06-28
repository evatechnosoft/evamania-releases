import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/tuning_preset.dart';

/// Shows a preset as a QR code so another phone can scan & import it.
class PresetQrPage extends StatelessWidget {
  final TuningPreset preset;
  const PresetQrPage({super.key, required this.preset});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${preset.name} — QR')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: QrImageView(
                data: preset.toShareString(),
                size: 280,
              ),
            ),
            const SizedBox(height: 16),
            Text('Diğer telefonda "Preset Tara" ile okut',
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

/// Scans a preset QR and returns the decoded [TuningPreset] via Navigator.pop.
class PresetScanPage extends StatefulWidget {
  const PresetScanPage({super.key});

  @override
  State<PresetScanPage> createState() => _PresetScanPageState();
}

class _PresetScanPageState extends State<PresetScanPage> {
  bool _handled = false;

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    for (final b in capture.barcodes) {
      final raw = b.rawValue;
      if (raw == null) continue;
      try {
        final preset = TuningPreset.fromShareString(raw);
        _handled = true;
        Navigator.of(context).pop(preset);
        return;
      } catch (_) {
        // not a preset QR — keep scanning
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Preset Tara')),
      body: MobileScanner(onDetect: _onDetect),
    );
  }
}
