import 'dart:ui' show Color;
import '../models/lat_lng.dart';
import '../models/polyline.dart';

/// A gradient stop for a gradient polyline.
class AnyGradientStop {
  /// Position along the polyline (0.0 to 1.0).
  final double offset;

  /// Color at this position.
  final Color color;

  const AnyGradientStop({required this.offset, required this.color});
}

/// Configuration for an animated polyline that can draw itself progressively.
class AnyAnimatedPolyline {
  /// Unique ID.
  final String id;

  /// Full set of points.
  final List<AnyLatLng> points;

  /// Line width.
  final double width;

  /// Solid color (if not using gradient).
  final Color color;

  /// Gradient stops (if set, overrides [color]).
  final List<AnyGradientStop>? gradient;

  /// Duration of the draw animation.
  final Duration animationDuration;

  const AnyAnimatedPolyline({
    required this.id,
    required this.points,
    this.width = 5.0,
    this.color = const Color(0xFF4285F4),
    this.gradient,
    this.animationDuration = const Duration(seconds: 3),
  });

  /// Get a subset of points for the given animation progress (0.0 to 1.0).
  List<AnyLatLng> pointsAtProgress(double progress) {
    if (progress >= 1.0) return points;
    if (progress <= 0.0 || points.isEmpty) return [];

    final count = (points.length * progress).ceil().clamp(1, points.length);
    return points.sublist(0, count);
  }

  /// Convert to a static polyline at the given animation progress.
  AnyPolyline toPolylineAt(double progress) {
    return AnyPolyline(
      id: id,
      points: pointsAtProgress(progress),
      color: color,
      width: width,
    );
  }

  /// Convert gradient to traffic-style colored segments.
  List<AnyPolyline> toGradientPolylines() {
    if (gradient == null || gradient!.isEmpty || points.length < 2) {
      return [
        AnyPolyline(id: id, points: points, color: color, width: width)
      ];
    }

    final polylines = <AnyPolyline>[];
    for (int i = 0; i < points.length - 1; i++) {
      final ratio = i / (points.length - 1);
      final segColor = _interpolateGradient(ratio);
      polylines.add(AnyPolyline(
        id: '${id}_$i',
        points: [points[i], points[i + 1]],
        color: segColor,
        width: width,
      ));
    }
    return polylines;
  }

  Color _interpolateGradient(double ratio) {
    final stops = gradient!..sort((a, b) => a.offset.compareTo(b.offset));

    if (ratio <= stops.first.offset) return stops.first.color;
    if (ratio >= stops.last.offset) return stops.last.color;

    for (int i = 0; i < stops.length - 1; i++) {
      if (ratio >= stops[i].offset && ratio <= stops[i + 1].offset) {
        final t = (ratio - stops[i].offset) /
            (stops[i + 1].offset - stops[i].offset);
        return Color.lerp(stops[i].color, stops[i + 1].color, t) ??
            stops[i].color;
      }
    }
    return color;
  }
}
