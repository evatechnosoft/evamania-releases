import 'package:flutter/material.dart';

import '../models/ride.dart';
import '../services/ride_store.dart';
import 'ride_map_view.dart';
import 'ride_stats_chart.dart';
import 'vehicle_3d_view.dart';

/// Strava-style ride summary: optional 3D vehicle hero, route map coloured by
/// speed, headline stats, and a speed/elevation profile. Includes CSV/JSON
/// export hooks.
class RideSummaryPage extends StatelessWidget {
  final Ride ride;

  /// Optional 3D model asset (e.g. 'assets/models/vehicle.glb'). When null the
  /// hero is skipped.
  final String? vehicleModelAsset;

  /// Called when the user taps export; receives the on-disk file path. Wire
  /// this to share_plus or your own share sheet.
  final void Function(String path)? onShareCsv;
  final void Function(String path)? onShareJson;

  const RideSummaryPage({
    super.key,
    required this.ride,
    this.vehicleModelAsset,
    this.onShareCsv,
    this.onShareJson,
  });

  @override
  Widget build(BuildContext context) {
    final store = RideStore();
    return Scaffold(
      appBar: AppBar(
        title: Text(ride.title ?? 'Sürüş Özeti'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.ios_share),
            onSelected: (v) async {
              await store.save(ride); // ensure files exist
              if (v == 'csv') {
                onShareCsv?.call(await store.csvPath(ride.id));
              } else {
                onShareJson?.call(await store.jsonPath(ride.id));
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'csv', child: Text('CSV dışa aktar')),
              PopupMenuItem(value: 'json', child: Text('JSON dışa aktar')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (vehicleModelAsset != null) ...[
            Vehicle3DView(modelAsset: vehicleModelAsset!),
            const SizedBox(height: 16),
          ],
          RideMapView(ride: ride),
          const SizedBox(height: 16),
          _statsGrid(context),
          const SizedBox(height: 16),
          if (ride.startAddress != null || ride.endAddress != null)
            _addresses(context),
          const SizedBox(height: 16),
          Text('Hız / Yükseklik Profili',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          RideStatsChart(ride: ride),
        ],
      ),
    );
  }

  Widget _statsGrid(BuildContext context) {
    final cards = <Widget>[
      _stat('Mesafe', '${ride.distanceKm.toStringAsFixed(2)} km'),
      _stat('Süre', _fmtDuration(ride.duration)),
      _stat('Ort. Hız', '${ride.avgSpeedKmh.toStringAsFixed(1)} km/s'),
      _stat('Maks. Hız', '${ride.maxSpeedKmh.toStringAsFixed(1)} km/s'),
      _stat('Tırmanış', '${ride.elevationGain.toStringAsFixed(0)} m'),
      if (ride.consumptionAhPerKm != null)
        _stat('Tüketim',
            '${ride.consumptionAhPerKm!.toStringAsFixed(2)} Ah/km'),
    ];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: cards,
    );
  }

  Widget _stat(String label, String value) => Card(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(value,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(label, style: const TextStyle(fontSize: 11)),
            ],
          ),
        ),
      );

  Widget _addresses(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (ride.startAddress != null)
                _addrRow(Icons.trip_origin, Colors.green, ride.startAddress!),
              if (ride.endAddress != null) ...[
                const SizedBox(height: 8),
                _addrRow(Icons.flag, Colors.red, ride.endAddress!),
              ],
            ],
          ),
        ),
      );

  Widget _addrRow(IconData icon, Color color, String text) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      );

  static String _fmtDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    if (h > 0) return '${h}s ${m}d';
    if (m > 0) return '${m}d ${s}sn';
    return '${s}sn';
  }
}
