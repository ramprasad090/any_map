import 'dart:math' as math;

import '../models/models.dart';
import 'cluster.dart';

/// Configuration for the clustering algorithm.
class ClusterConfig {
  /// The radius (in pixels at zoom 0) within which markers are merged.
  final double radius;

  /// Minimum zoom level to start clustering.
  final double minZoom;

  /// Maximum zoom level to cluster at (above this, all markers are shown).
  final double maxZoom;

  /// Tile extent used for coordinate projection (default 256).
  final int extent;

  const ClusterConfig({
    this.radius = 80.0,
    this.minZoom = 0,
    this.maxZoom = 18,
    this.extent = 256,
  });
}

/// A fast, grid-based clustering engine inspired by Supercluster.
///
/// Usage:
/// ```dart
/// final engine = AnyClusterEngine(config: ClusterConfig(radius: 80));
/// engine.load(markers);
/// final clusters = engine.getClusters(bounds, zoom: 12);
/// ```
class AnyClusterEngine {
  final ClusterConfig config;
  final List<AnyMarker> _markers = [];

  AnyClusterEngine({this.config = const ClusterConfig()});

  /// Load markers into the engine. Call this when your marker set changes.
  void load(List<AnyMarker> markers) {
    _markers
      ..clear()
      ..addAll(markers);
  }

  /// Get clusters for the given viewport bounds and zoom level.
  List<AnyCluster> getClusters(AnyLatLngBounds bounds, {required double zoom}) {
    final clusterZoom = zoom.floor().clamp(config.minZoom.floor(), config.maxZoom.floor());

    // Filter markers within bounds (with a small buffer).
    final bufferedBounds = _bufferBounds(bounds, zoom);
    final visible = _markers
        .where((m) => m.visible && bufferedBounds.contains(m.position))
        .toList();

    if (clusterZoom >= config.maxZoom) {
      // Above max zoom: every marker is its own cluster.
      return visible
          .map((m) => AnyCluster(position: m.position, markers: [m]))
          .toList();
    }

    // Grid-based clustering.
    final cellSize = config.radius / (config.extent * math.pow(2, clusterZoom));
    final Map<String, List<AnyMarker>> grid = {};

    for (final marker in visible) {
      final x = _lngToX(marker.position.longitude);
      final y = _latToY(marker.position.latitude);
      final cellKey = '${(x / cellSize).floor()}_${(y / cellSize).floor()}';
      grid.putIfAbsent(cellKey, () => []).add(marker);
    }

    return grid.values.map((group) {
      if (group.length == 1) {
        return AnyCluster(position: group.first.position, markers: group);
      }
      // Weighted center.
      double sumLat = 0, sumLng = 0;
      for (final m in group) {
        sumLat += m.position.latitude;
        sumLng += m.position.longitude;
      }
      return AnyCluster(
        position: AnyLatLng(sumLat / group.length, sumLng / group.length),
        markers: group,
      );
    }).toList();
  }

  /// Add a buffer around bounds so edge markers don't pop in/out.
  AnyLatLngBounds _bufferBounds(AnyLatLngBounds bounds, double zoom) {
    final latBuffer = (bounds.northeast.latitude - bounds.southwest.latitude) * 0.1;
    final lngBuffer = (bounds.northeast.longitude - bounds.southwest.longitude) * 0.1;
    return AnyLatLngBounds(
      southwest: AnyLatLng(
        (bounds.southwest.latitude - latBuffer).clamp(-90, 90),
        (bounds.southwest.longitude - lngBuffer).clamp(-180, 180),
      ),
      northeast: AnyLatLng(
        (bounds.northeast.latitude + latBuffer).clamp(-90, 90),
        (bounds.northeast.longitude + lngBuffer).clamp(-180, 180),
      ),
    );
  }

  /// Mercator projection: longitude to x [0, 1].
  double _lngToX(double lng) => lng / 360.0 + 0.5;

  /// Mercator projection: latitude to y [0, 1].
  double _latToY(double lat) {
    final sinLat = math.sin(lat * math.pi / 180);
    final y = 0.5 - 0.25 * math.log((1 + sinLat) / (1 - sinLat)) / math.pi;
    return y.clamp(0.0, 1.0);
  }
}
