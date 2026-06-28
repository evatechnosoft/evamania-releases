import 'package:audioplayers/audioplayers.dart';

/// Plays the alarm sound. Swap the implementation if you prefer a native
/// ringtone, a foreground-service alarm, etc.
abstract class AlarmSiren {
  Future<void> start();
  Future<void> stop();
  void dispose();
}

/// Loops a bundled audio asset at full volume (e.g. 'assets/sounds/siren.mp3').
/// Add the asset to pubspec.yaml.
class AudioSiren implements AlarmSiren {
  AudioSiren(this.assetPath);

  /// Path relative to the assets root, WITHOUT the leading `assets/`
  /// (audioplayers convention). e.g. asset 'assets/sounds/siren.mp3' → 'sounds/siren.mp3'.
  final String assetPath;
  final AudioPlayer _player = AudioPlayer();

  @override
  Future<void> start() async {
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.setVolume(1.0);
    await _player.play(AssetSource(assetPath));
  }

  @override
  Future<void> stop() => _player.stop();

  @override
  void dispose() => _player.dispose();
}

/// No-audio fallback (haptics still fire from the controller).
class NoopSiren implements AlarmSiren {
  @override
  Future<void> start() async {}
  @override
  Future<void> stop() async {}
  @override
  void dispose() {}
}
