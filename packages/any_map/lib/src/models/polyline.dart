import 'package:flutter/painting.dart';

import 'lat_lng.dart';

/// Join style for polyline segments.
enum AnyStrokeJoin { miter, round, bevel }

/// Cap style for polyline endpoints.
enum AnyStrokeCap { butt, round, square }

/// A polyline (series of connected line segments) drawn on the map.
///
/// ```dart
/// AnyPolyline(
///   id: 'route',
///   points: [AnyLatLng(17.36, 78.47), AnyLatLng(17.44, 78.38)],
///   color: Color(0xFF4285F4),
///   width: 6.0,
/// )
/// ```
class AnyPolyline {
  /// Unique identifier for this polyline.
  final String id;

  /// Ordered list of geographic coordinates forming the line.
  final List<AnyLatLng> points;

  /// Line color. Defaults to Google blue.
  final Color color;

  /// Line width in logical pixels.
  final double width;

  /// Opacity from 0.0 (invisible) to 1.0 (fully opaque).
  final double opacity;

  /// Dash pattern as alternating dash/gap lengths. Null for solid line.
  final List<double>? dashPattern;

  /// How line segments are joined at vertices.
  final AnyStrokeJoin strokeJoin;

  /// How line endpoints are rendered.
  final AnyStrokeCap strokeCap;

  /// Whether the line follows the Earth's curvature (great-circle arc).
  final bool geodesic;

  /// Whether this polyline is visible.
  final bool visible;

  /// Z-index for draw order.
  final int zIndex;

  /// Arbitrary data attached to this polyline.
  final Map<String, dynamic>? metadata;

  /// Callback when this polyline is tapped.
  final VoidCallback? onTap;

  const AnyPolyline({
    required this.id,
    required this.points,
    this.color = const Color(0xFF4285F4),
    this.width = 4.0,
    this.opacity = 1.0,
    this.dashPattern,
    this.strokeJoin = AnyStrokeJoin.round,
    this.strokeCap = AnyStrokeCap.round,
    this.geodesic = false,
    this.visible = true,
    this.zIndex = 0,
    this.metadata,
    this.onTap,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AnyPolyline && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
