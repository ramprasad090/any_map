import '../models/models.dart';

/// A cluster of markers that are close together at the current zoom level.
class AnyCluster {
  /// Geographic center of all markers in this cluster.
  final AnyLatLng position;

  /// The markers contained in this cluster.
  final List<AnyMarker> markers;

  /// Number of markers in this cluster.
  int get count => markers.length;

  /// Whether this is a single marker (not clustered).
  bool get isSingle => markers.length == 1;

  const AnyCluster({
    required this.position,
    required this.markers,
  });
}
