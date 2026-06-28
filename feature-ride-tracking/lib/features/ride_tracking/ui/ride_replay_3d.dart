import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/ride.dart';
import '../models/track_point.dart';

/// Full 3D animated replay of a recorded trip: the vehicle drives along the
/// route inside a perspective scene with a chase camera, plus playback controls
/// (play/pause, scrub, speed) and a live HUD synced to the recorded telemetry.
///
/// Self-contained: a pinhole camera + ground-plane projection rendered with a
/// CustomPainter — NO external 3D engine and NO map tiles/token required.
class Ride3DReplay extends StatefulWidget {
  final Ride ride;

  /// How long a 1x replay lasts at most (real trips are time-compressed to fit).
  final Duration maxReplayDuration;

  const Ride3DReplay({
    super.key,
    required this.ride,
    this.maxReplayDuration = const Duration(seconds: 45),
  });

  @override
  State<Ride3DReplay> createState() => _Ride3DReplayState();
}

class _Ride3DReplayState extends State<Ride3DReplay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<_P> _world; // route in local meters (x=east, y=north)
  double _speedMul = 1.0;

  @override
  void initState() {
    super.initState();
    _world = _project(widget.ride.points);
    _ctrl = AnimationController(vsync: this, duration: _replayDuration())
      ..addListener(() => setState(() {}));
    if (_world.length >= 2) _ctrl.forward();
  }

  Duration _replayDuration() {
    final base = widget.maxReplayDuration.inMilliseconds;
    return Duration(milliseconds: (base / _speedMul).round());
  }

  void _setSpeed(double m) {
    final pos = _ctrl.value;
    setState(() => _speedMul = m);
    _ctrl.duration = _replayDuration();
    _ctrl.value = pos;
    if (_ctrl.status != AnimationStatus.completed) _ctrl.forward();
  }

  void _toggle() {
    if (_ctrl.isAnimating) {
      _ctrl.stop();
    } else {
      if (_ctrl.value >= 1.0) _ctrl.value = 0;
      _ctrl.forward();
    }
    setState(() {});
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_world.length < 2) {
      return Scaffold(
        appBar: AppBar(title: const Text('3D Replay')),
        body: const Center(child: Text('Replay için yeterli rota verisi yok')),
      );
    }

    // Smooth fractional index along the route.
    final fIndex = _ctrl.value * (_world.length - 1);
    final i0 = fIndex.floor().clamp(0, _world.length - 1);
    final i1 = (i0 + 1).clamp(0, _world.length - 1);
    final frac = fIndex - i0;
    final tp = widget.ride.points[i0];

    return Scaffold(
      appBar: AppBar(title: Text(widget.ride.title ?? '3D Replay')),
      body: Column(
        children: [
          Expanded(
            child: CustomPaint(
              size: Size.infinite,
              painter: _ScenePainter(
                world: _world,
                i0: i0,
                i1: i1,
                frac: frac,
              ),
              child: const SizedBox.expand(),
            ),
          ),
          _hud(context, tp, fIndex),
          _controls(context),
        ],
      ),
    );
  }

  Widget _hud(BuildContext context, TrackPoint tp, double fIndex) {
    final progressKm = _distanceUpTo(fIndex);
    return Container(
      color: Colors.black87,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _hudItem('${tp.speedKmh.toStringAsFixed(0)}', 'km/s'),
          _hudItem(progressKm.toStringAsFixed(2), 'km'),
          if (tp.soc != null) _hudItem('${tp.soc!.toStringAsFixed(0)}', '% SOC'),
          if (tp.powerW != null)
            _hudItem((tp.powerW! / 1000).toStringAsFixed(1), 'kW'),
          if (tp.motorTempC != null)
            _hudItem('${tp.motorTempC!.toStringAsFixed(0)}', '°C'),
        ],
      ),
    );
  }

  Widget _hudItem(String v, String unit) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(v,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          Text(unit,
              style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      );

  Widget _controls(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: Icon(_ctrl.isAnimating
                ? Icons.pause_circle_filled
                : Icons.play_circle_filled),
            iconSize: 36,
            onPressed: _toggle,
          ),
          Expanded(
            child: Slider(
              value: _ctrl.value.clamp(0.0, 1.0),
              onChanged: (v) {
                _ctrl.stop();
                setState(() => _ctrl.value = v);
              },
            ),
          ),
          DropdownButton<double>(
            value: _speedMul,
            underline: const SizedBox(),
            items: const [1.0, 2.0, 4.0, 8.0]
                .map((m) => DropdownMenuItem(
                    value: m, child: Text('${m.toStringAsFixed(0)}x')))
                .toList(),
            onChanged: (m) => m == null ? null : _setSpeed(m),
          ),
        ],
      ),
    );
  }

  /// Distance (km) traveled up to a fractional index.
  double _distanceUpTo(double fIndex) {
    double m = 0;
    final whole = fIndex.floor();
    for (var i = 1; i <= whole && i < _world.length; i++) {
      m += _world[i].dist(_world[i - 1]);
    }
    if (whole + 1 < _world.length) {
      m += _world[whole + 1].dist(_world[whole]) * (fIndex - whole);
    }
    return m / 1000.0;
  }

  /// Equirectangular projection of lat/lng to local meters around the centroid.
  static List<_P> _project(List<TrackPoint> pts) {
    if (pts.isEmpty) return const [];
    final lat0 = pts.map((p) => p.lat).reduce((a, b) => a + b) / pts.length;
    final lng0 = pts.map((p) => p.lng).reduce((a, b) => a + b) / pts.length;
    const mPerDegLat = 111320.0;
    final mPerDegLng = 111320.0 * math.cos(lat0 * math.pi / 180.0);
    return pts
        .map((p) => _P(
              (p.lng - lng0) * mPerDegLng, // x east
              (p.lat - lat0) * mPerDegLat, // y north
            ))
        .toList();
  }
}

/// A 2D point in local meters (ground plane, z = 0).
class _P {
  final double x;
  final double y;
  const _P(this.x, this.y);
  double dist(_P o) => math.sqrt((x - o.x) * (x - o.x) + (y - o.y) * (y - o.y));
}

class _ScenePainter extends CustomPainter {
  final List<_P> world;
  final int i0;
  final int i1;
  final double frac;

  // Chase-camera parameters (meters).
  static const _back = 14.0;
  static const _height = 6.5;
  static const _lookAhead = 10.0;
  static const _roadHalfWidth = 2.4;

  _ScenePainter({
    required this.world,
    required this.i0,
    required this.i1,
    required this.frac,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Sky + ground backdrop.
    final horizon = size.height * 0.42;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, horizon),
      Paint()..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0D1B3E), Color(0xFF24407A)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, horizon)),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, horizon, size.width, size.height - horizon),
      Paint()..color = const Color(0xFF1B2A1B),
    );

    // Current vehicle position + heading (interpolated).
    final a = world[i0], b = world[i1];
    final px = a.x + (b.x - a.x) * frac;
    final py = a.y + (b.y - a.y) * frac;
    final bear = math.atan2(b.x - a.x, b.y - a.y); // from north, x=east
    final dir = _P(math.sin(bear), math.cos(bear)); // unit heading
    final rightDir = _P(dir.y, -dir.x); // perpendicular (right)

    // Camera basis (full 3D pinhole).
    final cam = _V3(
      px - dir.x * _back,
      py - dir.y * _back,
      _height,
    );
    final look = _V3(px + dir.x * _lookAhead, py + dir.y * _lookAhead, 0.6);
    final fwd = (look - cam).normalized();
    final worldUp = const _V3(0, 0, 1);
    final right = fwd.cross(worldUp).normalized();
    final up = right.cross(fwd).normalized();
    final f = size.width * 0.95; // focal length, px
    final cx = size.width / 2, cy = size.height / 2;

    Offset? project(_V3 p) {
      final v = p - cam;
      final c = v.dot(fwd);
      if (c <= 0.2) return null; // behind camera / too close
      final sx = cx + f * v.dot(right) / c;
      final sy = cy - f * v.dot(up) / c;
      return Offset(sx, sy);
    }

    // Draw the road as a ribbon: left/right edges offset from the centerline.
    // Only a window around the current index for depth + performance.
    final lo = math.max(0, i0 - 4);
    final hi = math.min(world.length - 1, i0 + 60);

    final road = Path();
    final leftPts = <Offset>[];
    final rightPts = <Offset>[];
    for (var i = lo; i <= hi; i++) {
      // Local direction at i for perpendicular offset.
      final j = i < world.length - 1 ? i + 1 : i;
      final k = i > 0 ? i - 1 : i;
      final dx = world[j].x - world[k].x, dy = world[j].y - world[k].y;
      final len = math.sqrt(dx * dx + dy * dy);
      final ndx = len == 0 ? rightDir.x : dy / len; // right normal
      final ndy = len == 0 ? rightDir.y : -dx / len;
      final l = project(
          _V3(world[i].x - ndx * _roadHalfWidth, world[i].y - ndy * _roadHalfWidth, 0));
      final r = project(
          _V3(world[i].x + ndx * _roadHalfWidth, world[i].y + ndy * _roadHalfWidth, 0));
      if (l != null) leftPts.add(l);
      if (r != null) rightPts.add(r);
    }
    if (leftPts.length >= 2 && rightPts.length >= 2) {
      road.moveTo(leftPts.first.dx, leftPts.first.dy);
      for (final p in leftPts) road.lineTo(p.dx, p.dy);
      for (final p in rightPts.reversed) road.lineTo(p.dx, p.dy);
      road.close();
      canvas.drawPath(road, Paint()..color = const Color(0xFF3A3A40));
      // Center dashed line.
      final centerPaint = Paint()
        ..color = Colors.yellow.withOpacity(0.7)
        ..strokeWidth = 2;
      for (var i = lo; i < hi; i += 2) {
        final p1 = project(_V3(world[i].x, world[i].y, 0.02));
        final p2 = project(_V3(world[i + 1].x, world[i + 1].y, 0.02));
        if (p1 != null && p2 != null) canvas.drawLine(p1, p2, centerPaint);
      }
    }

    // Traveled trail behind the vehicle (green), to show progress.
    final trail = Paint()
      ..color = Colors.greenAccent.withOpacity(0.8)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final trailPath = Path();
    var started = false;
    for (var i = math.max(0, i0 - 30); i <= i0; i++) {
      final p = project(_V3(world[i].x, world[i].y, 0.05));
      if (p == null) continue;
      if (!started) {
        trailPath.moveTo(p.dx, p.dy);
        started = true;
      } else {
        trailPath.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(trailPath, trail);

    // The vehicle: a simple 3D chevron/box pointing along heading.
    _drawVehicle(canvas, project, px, py, dir, rightDir);
  }

  void _drawVehicle(Canvas canvas, Offset? Function(_V3) project, double px,
      double py, _P dir, _P rightDir) {
    const half = 1.0; // m
    const long = 2.0; // m
    const h = 1.2; // m
    final nose = _V3(px + dir.x * long, py + dir.y * long, 0.3);
    final tailL = _V3(
        px - dir.x * long - rightDir.x * half,
        py - dir.y * long - rightDir.y * half,
        0.3);
    final tailR = _V3(
        px - dir.x * long + rightDir.x * half,
        py - dir.y * long + rightDir.y * half,
        0.3);
    final top = _V3(px, py, h);

    final pn = project(nose), pl = project(tailL), pr = project(tailR);
    final pt = project(top);
    if (pn == null || pl == null || pr == null) return;

    final body = Path()
      ..moveTo(pn.dx, pn.dy)
      ..lineTo(pl.dx, pl.dy)
      ..lineTo(pr.dx, pr.dy)
      ..close();
    canvas.drawPath(body, Paint()..color = Colors.redAccent);
    canvas.drawPath(
        body,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
    if (pt != null) {
      canvas.drawLine(pn, pt, Paint()
        ..color = Colors.white70
        ..strokeWidth = 2);
    }
  }

  @override
  bool shouldRepaint(covariant _ScenePainter old) =>
      old.i0 != i0 || old.frac != frac || old.i1 != i1;
}

/// Minimal 3D vector for the pinhole camera math.
class _V3 {
  final double x, y, z;
  const _V3(this.x, this.y, this.z);
  _V3 operator -(_V3 o) => _V3(x - o.x, y - o.y, z - o.z);
  double dot(_V3 o) => x * o.x + y * o.y + z * o.z;
  _V3 cross(_V3 o) =>
      _V3(y * o.z - z * o.y, z * o.x - x * o.z, x * o.y - y * o.x);
  double get length => math.sqrt(x * x + y * y + z * z);
  _V3 normalized() {
    final l = length;
    return l == 0 ? this : _V3(x / l, y / l, z / l);
  }
}
