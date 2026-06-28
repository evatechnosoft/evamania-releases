import 'package:flutter/material.dart';

import '../models/ride.dart';
import '../services/ride_aggregates.dart';
import '../services/ride_store.dart';

/// Lifetime stats dashboard: totals across every saved ride.
class RideStatsDashboardPage extends StatefulWidget {
  /// Grams CO2/km a comparable petrol two-wheeler would emit.
  final double co2PerKmGrams;

  const RideStatsDashboardPage({super.key, this.co2PerKmGrams = 90});

  @override
  State<RideStatsDashboardPage> createState() => _RideStatsDashboardPageState();
}

class _RideStatsDashboardPageState extends State<RideStatsDashboardPage> {
  late Future<RideAggregates> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<RideAggregates> _load() async {
    final List<Ride> rides = await RideStore().loadAll();
    return RideAggregates.from(rides, co2PerKmGrams: widget.co2PerKmGrams);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Toplam İstatistikler')),
      body: FutureBuilder<RideAggregates>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final a = snap.data!;
          if (a.rideCount == 0) {
            return const Center(child: Text('Henüz kayıtlı sürüş yok'));
          }
          return GridView.count(
            crossAxisCount: 2,
            padding: const EdgeInsets.all(16),
            childAspectRatio: 1.6,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              _card('Toplam Mesafe',
                  '${a.totalDistanceKm.toStringAsFixed(1)} km', Icons.route),
              _card('Sürüş Sayısı', '${a.rideCount}', Icons.two_wheeler),
              _card('Toplam Süre', _fmt(a.totalDuration), Icons.timer),
              _card('Toplam Enerji',
                  '${(a.totalEnergyWh / 1000).toStringAsFixed(1)} kWh',
                  Icons.bolt),
              _card('Geri Kazanım',
                  '${(a.totalRegenWh / 1000).toStringAsFixed(2)} kWh',
                  Icons.recycling),
              if (a.avgEfficiencyWhPerKm != null)
                _card('Ort. Verim',
                    '${a.avgEfficiencyWhPerKm!.toStringAsFixed(0)} Wh/km',
                    Icons.eco),
              _card('En Uzun Sürüş',
                  '${a.longestRideKm.toStringAsFixed(1)} km', Icons.straighten),
              _card('Maks. Hız',
                  '${a.maxSpeedKmh.toStringAsFixed(0)} km/s', Icons.speed),
              _card('Tırmanış',
                  '${a.totalElevationGain.toStringAsFixed(0)} m', Icons.terrain),
              _card('CO₂ Tasarrufu',
                  '${a.co2SavedKg.toStringAsFixed(1)} kg', Icons.forest),
            ],
          );
        },
      ),
    );
  }

  Widget _card(String label, String value, IconData icon) => Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 22),
              const Spacer(),
              Text(value,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),
              Text(label, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      );

  static String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    return h > 0 ? '${h}s ${m}d' : '${m}d';
  }
}
