import 'package:flutter/painting.dart';

import 'lat_lng.dart';

/// A circle drawn on the map.
class AnyCircle {
  /// Unique identifier for this circle.
  final String id;

  /// The geographical center point of the circle.
  final AnyLatLng center;

  /// Radius in meters.
  final double radius;

  /// The fill color of the circle interior.
  final Color fillColor;

  /// The color of the circle's border stroke.
  final Color strokeColor;

  /// The width of the circle's border stroke in logical pixels.
  final double strokeWidth;

  /// The opacity of the circle, from 0.0 (transparent) to 1.0 (opaque).
  final double opacity;

  /// Whether this circle is visible on the map.
  final bool visible;

  /// The z-index determining draw order relative to other overlays.
  final int zIndex;

  /// Optional metadata to associate arbitrary data with this circle.
  final Map<String, dynamic>? metadata;

  /// Callback invoked when the circle is tapped.
  final VoidCallback? onTap;

  const AnyCircle({
    required this.id,
    required this.center,
    required this.radius,
    this.fillColor = const Color(0x334285F4),
    this.strokeColor = const Color(0xFF4285F4),
    this.strokeWidth = 2.0,
    this.opacity = 1.0,
    this.visible = true,
    this.zIndex = 0,
    this.metadata,
    this.onTap,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AnyCircle && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
