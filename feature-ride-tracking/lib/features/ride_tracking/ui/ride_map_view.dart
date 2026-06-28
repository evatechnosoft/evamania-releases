import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/ride.dart';
import '../models/track_point.dart';

/// Strava-style route map: the track is drawn as a polyline whose colour
/// follows speed (slow = blue, fast = red), with start/end markers.
///
/// Uses free OpenStreetMap tiles via flutter_map (no API token). Swap the
/// [TileLayer.urlTemplate] for Mapbox/your own tiles if desired.
class RideMapView extends StatelessWidget {
  final Ride ride;
  final double height;

  const RideMapView({super.key, required this.ride, this.height = 280});

  @override
  Widget build(BuildContext context) {
    if (ride.points.length < 2) {
      return SizedBox(
        height: height,
        child: const Center(child: Text('Rota verisi yok')),
      );
    }

    final pts = ride.points.map((p) => LatLng(p.lat, p.lng)).toList();
    final maxSpeed = math.max(ride.maxSpeedKmh, 1.0);

    // One Polyline per segment so each can carry its own speed colour.
    final segments = <Polyline>[];
    for (var i = 1; i < ride.points.length; i++) {
      segments.add(Polyline(
        points: [pts[i - 1], pts[i]],
        strokeWidth: 5,
        color: _speedColor(ride.points[i].speedKmh / maxSpeed),
      ));
    }

    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: FlutterMap(
          options: MapOptions(
            initialCameraFit: CameraFit.bounds(
              bounds: LatLngBounds.fromPoints(pts),
              padding: const EdgeInsets.all(32),
            ),
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.evamania.app',
            ),
            PolylineLayer(polylines: segments),
            MarkerLayer(markers: [
              _marker(pts.first, Colors.green, Icons.trip_origin),
              _marker(pts.last, Colors.red, Icons.flag),
            ]),
          ],
        ),
      ),
    );
  }

  Marker _marker(LatLng at, Color color, IconData icon) => Marker(
        point: at,
        width: 36,
        height: 36,
        child: Icon(icon, color: color, size: 30),
      );

  /// 0..1 -> blue→green→yellow→red, like a Strava pace gradient.
  static Color _speedColor(double t) {
    t = t.clamp(0.0, 1.0);
    if (t < 0.5) {
      return Color.lerp(Colors.blue, Colors.green, t / 0.5)!;
    }
    return Color.lerp(Colors.orange, Colors.red, (t - 0.5) / 0.5)!;
  }
}

/// Convenience: live map that recenters on the latest point while recording.
class LiveRideMap extends StatelessWidget {
  final List<TrackPoint> points;
  final double height;

  const LiveRideMap({super.key, required this.points, this.height = 280});

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(child: Text('GPS bekleniyor...')),
      );
    }
    final pts = points.map((p) => LatLng(p.lat, p.lng)).toList();
    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: pts.last,
            initialZoom: 16,
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.evamania.app',
            ),
            PolylineLayer(polylines: [
              Polyline(
                  points: pts, strokeWidth: 5, color: Colors.blueAccent),
            ]),
            MarkerLayer(markers: [
              Marker(
                point: pts.last,
                width: 24,
                height: 24,
                child: const Icon(Icons.navigation,
                    color: Colors.blue, size: 24),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
