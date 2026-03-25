import 'package:flutter/painting.dart';

import 'lat_lng.dart';

/// A polygon (closed shape) drawn on the map.
class AnyPolygon {
  /// Unique identifier for this polygon.
  final String id;

  /// The vertices that define the polygon's outline.
  final List<AnyLatLng> points;

  /// Optional list of holes cut out from the polygon interior.
  final List<List<AnyLatLng>>? holes;

  /// The fill color of the polygon interior.
  final Color fillColor;

  /// The color of the polygon's border stroke.
  final Color strokeColor;

  /// The width of the polygon's border stroke in logical pixels.
  final double strokeWidth;

  /// The opacity of the polygon, from 0.0 (transparent) to 1.0 (opaque).
  final double opacity;

  /// Whether this polygon is visible on the map.
  final bool visible;

  /// The z-index determining draw order relative to other overlays.
  final int zIndex;

  /// Optional metadata to associate arbitrary data with this polygon.
  final Map<String, dynamic>? metadata;

  /// Callback invoked when the polygon is tapped.
  final VoidCallback? onTap;

  const AnyPolygon({
    required this.id,
    required this.points,
    this.holes,
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
      identical(this, other) || other is AnyPolygon && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
