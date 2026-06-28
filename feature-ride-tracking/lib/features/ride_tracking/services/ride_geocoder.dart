import 'package:geocoding/geocoding.dart';

import '../models/ride.dart';

/// Fills in [Ride.startAddress] / [Ride.endAddress] by reverse-geocoding the
/// first and last GPS points. Best-effort: failures (offline, no result) are
/// swallowed so a ride is never lost just because geocoding failed.
class RideGeocoder {
  /// Optional locale identifier, e.g. 'tr_TR' / 'en_US' / 'de_DE'.
  final String? localeIdentifier;

  const RideGeocoder({this.localeIdentifier});

  Future<void> annotate(Ride ride) async {
    if (ride.points.isEmpty) return;
    ride.startAddress = await _lookup(
      ride.points.first.lat,
      ride.points.first.lng,
    );
    ride.endAddress = await _lookup(
      ride.points.last.lat,
      ride.points.last.lng,
    );
  }

  Future<String?> _lookup(double lat, double lng) async {
    try {
      final list = localeIdentifier != null
          ? await placemarkFromCoordinates(lat, lng,
              localeIdentifier: localeIdentifier)
          : await placemarkFromCoordinates(lat, lng);
      if (list.isEmpty) return null;
      return _format(list.first);
    } catch (_) {
      return null; // offline or no result — keep coordinates only
    }
  }

  String _format(Placemark p) {
    final parts = <String?>[
      p.thoroughfare, // street
      p.subLocality, // neighbourhood
      p.locality, // town/city
      p.administrativeArea, // province/state
    ];
    return parts
        .where((s) => s != null && s.trim().isNotEmpty)
        .join(', ');
  }
}
