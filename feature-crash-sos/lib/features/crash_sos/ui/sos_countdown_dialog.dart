import 'dart:async';

import 'package:flutter/material.dart';

/// A full-screen countdown shown after a crash is detected. If the rider does
/// nothing, [onSend] is called when the countdown hits zero; "İyiyim" cancels.
///
/// Returns true if the SOS was sent, false if cancelled.
class SosCountdownDialog extends StatefulWidget {
  final Duration countdown;
  final double peakG;
  final Future<void> Function() onSend;

  const SosCountdownDialog({
    super.key,
    required this.countdown,
    required this.peakG,
    required this.onSend,
  });

  static Future<bool?> show(
    BuildContext context, {
    required Duration countdown,
    required double peakG,
    required Future<void> Function() onSend,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => SosCountdownDialog(
        countdown: countdown,
        peakG: peakG,
        onSend: onSend,
      ),
    );
  }

  @override
  State<SosCountdownDialog> createState() => _SosCountdownDialogState();
}

class _SosCountdownDialogState extends State<SosCountdownDialog> {
  late int _remaining;
  Timer? _timer;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _remaining = widget.countdown.inSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _remaining--);
      if (_remaining <= 0) _send();
    });
  }

  Future<void> _send() async {
    if (_sending) return;
    _sending = true;
    _timer?.cancel();
    try {
      await widget.onSend();
    } finally {
      if (mounted) Navigator.of(context).pop(true);
    }
  }

  void _cancel() {
    _timer?.cancel();
    Navigator.of(context).pop(false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.red.shade700,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Colors.white, size: 72),
              const SizedBox(height: 16),
              const Text(
                'Kaza algılandı',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Acil kişilere konum gönderilecek',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.9)),
              ),
              const SizedBox(height: 32),
              Text(
                _sending ? '...' : '$_remaining',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 80,
                    fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red.shade700,
                  minimumSize: const Size.fromHeight(64),
                ),
                onPressed: _sending ? null : _cancel,
                child: const Text('İYİYİM, İPTAL ET',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _sending ? null : _send,
                child: const Text('Şimdi gönder',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Wrap part of your widget tree with this to automatically show the countdown
/// whenever a crash is detected.
class CrashSosListener extends StatefulWidget {
  final Stream<dynamic> crashes; // CrashEvent stream (peakG accessed dynamically)
  final Duration countdown;
  final Future<void> Function() onSend;
  final Widget child;

  const CrashSosListener({
    super.key,
    required this.crashes,
    required this.countdown,
    required this.onSend,
    required this.child,
  });

  @override
  State<CrashSosListener> createState() => _CrashSosListenerState();
}

class _CrashSosListenerState extends State<CrashSosListener> {
  StreamSubscription? _sub;
  bool _dialogOpen = false;

  @override
  void initState() {
    super.initState();
    _sub = widget.crashes.listen((e) async {
      if (_dialogOpen || !mounted) return;
      _dialogOpen = true;
      await SosCountdownDialog.show(
        context,
        countdown: widget.countdown,
        peakG: (e.peakG as num).toDouble(),
        onSend: widget.onSend,
      );
      _dialogOpen = false;
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
