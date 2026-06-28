import '../models/ride.dart';

/// Lifetime totals across all saved rides — feeds a "stats dashboard".
class RideAggregates {
  final int rideCount;
  final double totalDistanceKm;
  final Duration totalDuration;
  final double totalEnergyWh;
  final double totalRegenWh;
  final double totalElevationGain;
  final double maxSpeedKmh;
  final double longestRideKm;
  final double? avgEfficiencyWhPerKm;
  final DateTime? firstRideDate;

  /// Estimated CO2 avoided vs a comparable petrol two-wheeler.
  final double co2SavedKg;

  const RideAggregates({
    required this.rideCount,
    required this.totalDistanceKm,
    required this.totalDuration,
    required this.totalEnergyWh,
    required this.totalRegenWh,
    required this.totalElevationGain,
    required this.maxSpeedKmh,
    required this.longestRideKm,
    required this.avgEfficiencyWhPerKm,
    required this.firstRideDate,
    required this.co2SavedKg,
  });

  /// [co2PerKmGrams]: grams CO2/km a petrol scooter would emit (default ~90).
  factory RideAggregates.from(
    List<Ride> rides, {
    double co2PerKmGrams = 90,
  }) {
    if (rides.isEmpty) {
      return const RideAggregates(
        rideCount: 0,
        totalDistanceKm: 0,
        totalDuration: Duration.zero,
        totalEnergyWh: 0,
        totalRegenWh: 0,
        totalElevationGain: 0,
        maxSpeedKmh: 0,
        longestRideKm: 0,
        avgEfficiencyWhPerKm: null,
        firstRideDate: null,
        co2SavedKg: 0,
      );
    }

    var dist = 0.0,
        energy = 0.0,
        regen = 0.0,
        elev = 0.0,
        maxSpeed = 0.0,
        longest = 0.0;
    var dur = Duration.zero;
    DateTime? first;

    for (final r in rides) {
      dist += r.distanceKm;
      energy += r.energyWh;
      regen += r.regenWh;
      elev += r.elevationGain;
      dur += r.duration;
      if (r.maxSpeedKmh > maxSpeed) maxSpeed = r.maxSpeedKmh;
      if (r.distanceKm > longest) longest = r.distanceKm;
      if (first == null || r.startTime.isBefore(first)) first = r.startTime;
    }

    return RideAggregates(
      rideCount: rides.length,
      totalDistanceKm: dist,
      totalDuration: dur,
      totalEnergyWh: energy,
      totalRegenWh: regen,
      totalElevationGain: elev,
      maxSpeedKmh: maxSpeed,
      longestRideKm: longest,
      avgEfficiencyWhPerKm: (dist > 0 && energy > 0) ? energy / dist : null,
      firstRideDate: first,
      co2SavedKg: dist * co2PerKmGrams / 1000.0,
    );
  }
}
