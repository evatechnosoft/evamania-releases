import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

/// Interactive 3D vehicle hero, shown at the top of a ride summary
/// (the same trick Karluna uses with its `karluna.glb` model).
///
/// Drop a `.glb` into `assets/models/` and reference it in pubspec.yaml.
/// Keep models lean (< a few MB) to avoid jank on low-end devices.
class Vehicle3DView extends StatelessWidget {
  /// Asset path, e.g. 'assets/models/vehicle.glb'.
  final String modelAsset;
  final double height;
  final bool autoRotate;

  const Vehicle3DView({
    super.key,
    required this.modelAsset,
    this.height = 220,
    this.autoRotate = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ModelViewer(
        src: modelAsset,
        alt: 'EvaMania vehicle',
        autoRotate: autoRotate,
        cameraControls: true,
        disableZoom: false,
        backgroundColor: Colors.transparent,
      ),
    );
  }
}
