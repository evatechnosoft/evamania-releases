import 'package:url_launcher/url_launcher.dart';

import '../models/emergency_contact.dart';

/// The SOS payload to deliver.
class SosMessage {
  final String text;
  final double? lat;
  final double? lng;

  const SosMessage({required this.text, this.lat, this.lng});

  String? get mapsUrl => (lat != null && lng != null)
      ? 'https://www.google.com/maps/search/?api=1&query=$lat,$lng'
      : null;
}

/// Strategy for delivering an SOS. Inject your own (e.g. a backend push or a
/// native auto-SMS plugin) for fully hands-free delivery.
abstract class SosSender {
  Future<void> send(SosMessage message, List<EmergencyContact> contacts);
}

/// Default sender: opens the device SMS composer pre-filled with the message and
/// all recipients. The rider taps "send" — reliable and cross-platform.
///
/// NOTE: truly automatic (no-tap) SMS sending requires platform-specific
/// permissions/plugins (Android only) and is intentionally not bundled here.
/// Swap in a custom [SosSender] if you need that.
class UrlLauncherSosSender implements SosSender {
  const UrlLauncherSosSender();

  @override
  Future<void> send(
      SosMessage message, List<EmergencyContact> contacts) async {
    if (contacts.isEmpty) return;
    final recipients = contacts.map((c) => c.phone).join(',');
    final uri = Uri(
      scheme: 'sms',
      path: recipients,
      queryParameters: {'body': message.text},
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Convenience: open a phone dialer for the first contact.
  static Future<void> call(EmergencyContact c) async {
    final uri = Uri(scheme: 'tel', path: c.phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  /// Convenience: open the location in a maps app.
  static Future<void> openMaps(SosMessage m) async {
    final url = m.mapsUrl;
    if (url == null) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
