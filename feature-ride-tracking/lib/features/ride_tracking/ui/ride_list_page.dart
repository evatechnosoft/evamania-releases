import 'package:flutter/material.dart';

import '../models/ride.dart';
import '../services/ride_store.dart';
import 'ride_summary_page.dart';

/// History of past rides (newest first), Strava-feed style. Tapping a ride
/// opens its [RideSummaryPage].
class RideListPage extends StatefulWidget {
  final String? vehicleModelAsset;
  const RideListPage({super.key, this.vehicleModelAsset});

  @override
  State<RideListPage> createState() => _RideListPageState();
}

class _RideListPageState extends State<RideListPage> {
  final _store = RideStore();
  late Future<List<Ride>> _future;

  @override
  void initState() {
    super.initState();
    _future = _store.loadAll();
  }

  void _reload() => setState(() => _future = _store.loadAll());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sürüşlerim')),
      body: RefreshIndicator(
        onRefresh: () async => _reload(),
        child: FutureBuilder<List<Ride>>(
          future: _future,
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final rides = snap.data!;
            if (rides.isEmpty) {
              return const Center(child: Text('Henüz kayıtlı sürüş yok'));
            }
            return ListView.separated(
              itemCount: rides.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) => _tile(rides[i]),
            );
          },
        ),
      ),
    );
  }

  Widget _tile(Ride ride) {
    return Dismissible(
      key: ValueKey(ride.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) async {
        await _store.delete(ride.id);
        _reload();
      },
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.two_wheeler)),
        title: Text(ride.title ??
            ride.startAddress ??
            _fmtDate(ride.startTime)),
        subtitle: Text(
          '${ride.distanceKm.toStringAsFixed(1)} km · '
          '${ride.avgSpeedKmh.toStringAsFixed(0)} km/s · '
          '${_fmtDate(ride.startTime)}',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => RideSummaryPage(
            ride: ride,
            vehicleModelAsset: widget.vehicleModelAsset,
          ),
        )),
      ),
    );
  }

  static String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
