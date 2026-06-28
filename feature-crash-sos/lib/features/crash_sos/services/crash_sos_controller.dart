import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../models/sos_config.dart';
import 'crash_detector.dart';
import 'sos_sender.dart';

/// Ties crash detection, location lookup, and SOS delivery together.
///
/// The UI subscribes to [crashes] and shows a countdown; on confirm it calls
/// [composeAndSend]. Keeps no BuildContext, so it's UI-framework agnostic.
class CrashSosController {
  CrashSosController({
    required this.config,
    CrashDetector? detector,
    this.sender = const UrlLauncherSosSender(),
  }) : detector = detector ??
            CrashDetector(
              impactG: config.impactG,
              requirePriorMotion: config.requirePriorMotion,
              priorMotionWindow: config.priorMotionWindow,
            );

  SosConfig config;
  final CrashDetector detector;
  final SosSender sender;

  Stream<CrashEvent> get crashes => detector.events;

  void start() {
    detector
      ..impactG = config.impactG
      ..requirePriorMotion = config.requirePriorMotion
      ..priorMotionWindow = config.priorMotionWindow
      ..start();
  }

  void stop() => detector.stop();

  /// Forward current speed (km/h) for prior-motion gating.
  void setSpeed(double speedKmh) => detector.setSpeed(speedKmh);

  /// Builds the SOS message with a best-effort current location.
  Future<SosMessage> compose() async {
    double? lat, lng;
    try {
      final p = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 6));
      lat = p.latitude;
      lng = p.longitude;
    } catch (_) {
      // no fix — send without coordinates
    }
    final maps = (lat != null && lng != null)
        ? 'https://www.google.com/maps/search/?api=1&query=$lat,$lng'
        : 'konum alınamadı';
    final coords =
        (lat != null && lng != null) ? '$lat, $lng' : 'bilinmiyor';
    final text = config.messageTemplate
        .replaceAll('{maps}', maps)
        .replaceAll('{coords}', coords);
    return SosMessage(text: text, lat: lat, lng: lng);
  }

  /// Compose + deliver in one call.
  Future<SosMessage> composeAndSend() async {
    final msg = await compose();
    await sender.send(msg, config.contacts);
    return msg;
  }

  void dispose() => detector.dispose();
}
