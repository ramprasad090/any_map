import 'dart:ui' show Color;
import '../models/lat_lng.dart';

/// A data point for a heatmap.
class AnyHeatmapPoint {
  /// Geographic location.
  final AnyLatLng position;

  /// Intensity / weight (0.0 to 1.0). Defaults to 1.0.
  final double intensity;

  const AnyHeatmapPoint({
    required this.position,
    this.intensity = 1.0,
  });
}

/// A gradient color stop for heatmap rendering.
class HeatmapGradientStop {
  /// Position (0.0 to 1.0).
  final double offset;

  /// Color at this position.
  final Color color;

  const HeatmapGradientStop(this.offset, this.color);

  /// Default gradient from blue (low) to red (high).
  static final List<HeatmapGradientStop> defaultGradient = [
    const HeatmapGradientStop(0.0, Color(0xFF0000FF)),
    const HeatmapGradientStop(0.4, Color(0xFF00FF00)),
    const HeatmapGradientStop(0.6, Color(0xFFFFFF00)),
    const HeatmapGradientStop(0.8, Color(0xFFFF8C00)),
    const HeatmapGradientStop(1.0, Color(0xFFFF0000)),
  ];
}

/// Configuration for a heatmap layer.
class AnyHeatmapLayer {
  /// Unique layer ID.
  final String id;

  /// Data points to render.
  final List<AnyHeatmapPoint> points;

  /// Blur radius in pixels.
  final double radius;

  /// Maximum intensity for color mapping.
  final double maxIntensity;

  /// Opacity (0.0 to 1.0).
  final double opacity;

  /// Gradient color stops.
  final List<HeatmapGradientStop> gradient;

  /// Minimum zoom to display the heatmap.
  final double minZoom;

  /// Maximum zoom to display the heatmap.
  final double maxZoom;

  /// Creates a heatmap layer with the given points and configuration.
  AnyHeatmapLayer({
    required this.id,
    required this.points,
    this.radius = 20.0,
    this.maxIntensity = 1.0,
    this.opacity = 0.7,
    List<HeatmapGradientStop>? gradient,
    this.minZoom = 0,
    this.maxZoom = 22,
  }) : gradient = gradient ?? HeatmapGradientStop.defaultGradient;
}
