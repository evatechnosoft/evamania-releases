import 'package:flutter/material.dart';

import '../models/ride.dart';

/// Lightweight speed + elevation profile over distance, drawn with a
/// CustomPainter so the module pulls in NO charting dependency.
class RideStatsChart extends StatelessWidget {
  final Ride ride;
  final double height;

  const RideStatsChart({super.key, required this.ride, this.height = 160});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: _ProfilePainter(
          ride: ride,
          speedColor: Colors.blueAccent,
          elevationColor: Colors.orange.withOpacity(0.5),
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _ProfilePainter extends CustomPainter {
  final Ride ride;
  final Color speedColor;
  final Color elevationColor;

  _ProfilePainter({
    required this.ride,
    required this.speedColor,
    required this.elevationColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final pts = ride.points;
    if (pts.length < 2) return;

    final maxSpeed =
        pts.map((p) => p.speedKmh).fold<double>(1, (m, v) => v > m ? v : m);
    final alts = pts.map((p) => p.altitude).toList();
    final minAlt = alts.reduce((a, b) => a < b ? a : b);
    final maxAlt = alts.reduce((a, b) => a > b ? a : b);
    final altRange = (maxAlt - minAlt).abs() < 1 ? 1 : (maxAlt - minAlt);

    double x(int i) => size.width * i / (pts.length - 1);
    double ySpeed(double kmh) => size.height * (1 - kmh / maxSpeed);
    double yAlt(double a) => size.height * (1 - (a - minAlt) / altRange);

    // Elevation as a filled area (background).
    final elevPath = Path()..moveTo(0, size.height);
    for (var i = 0; i < pts.length; i++) {
      elevPath.lineTo(x(i), yAlt(pts[i].altitude));
    }
    elevPath
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(elevPath, Paint()..color = elevationColor);

    // Speed as a line (foreground).
    final speedPath = Path()..moveTo(0, ySpeed(pts.first.speedKmh));
    for (var i = 1; i < pts.length; i++) {
      speedPath.lineTo(x(i), ySpeed(pts[i].speedKmh));
    }
    canvas.drawPath(
      speedPath,
      Paint()
        ..color = speedColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  @override
  bool shouldRepaint(covariant _ProfilePainter old) => old.ride != ride;
}
