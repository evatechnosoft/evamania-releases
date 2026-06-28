import 'package:flutter_tts/flutter_tts.dart';

/// Thin wrapper around flutter_tts: language, rate, mute, and a "critical
/// interrupts everything else" behaviour. Safe to call before init() — the
/// first speak() lazily initializes the engine.
class TtsSpeaker {
  TtsSpeaker({this.language = 'tr-TR', this.rate = 0.5, this.pitch = 1.0});

  final String language;
  final double rate;
  final double pitch;

  final FlutterTts _tts = FlutterTts();
  bool _ready = false;
  bool muted = false;

  Future<void> init() async {
    if (_ready) return;
    await _tts.setLanguage(language);
    await _tts.setSpeechRate(rate);
    await _tts.setPitch(pitch);
    await _tts.awaitSpeakCompletion(true);
    _ready = true;
  }

  /// Speaks [text]. When [interrupt] is true, stops any current speech first
  /// (use for critical alarms).
  Future<void> speak(String text, {bool interrupt = false}) async {
    if (muted || text.trim().isEmpty) return;
    await init();
    if (interrupt) await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> stop() => _tts.stop();

  void dispose() => _tts.stop();
}
