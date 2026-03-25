import 'lat_lng.dart';

/// Describes the camera viewpoint on the map.
class AnyCameraPosition {
  /// The geographical location the camera is pointing at.
  final AnyLatLng target;

  /// The zoom level of the camera.
  final double zoom;

  /// Tilt in degrees from the nadir (directly facing the Earth).
  final double tilt;

  /// Bearing in degrees clockwise from north.
  final double bearing;

  const AnyCameraPosition({
    required this.target,
    this.zoom = 14.0,
    this.tilt = 0.0,
    this.bearing = 0.0,
  });

  /// Returns a copy of this position with the given fields replaced.
  AnyCameraPosition copyWith({
    AnyLatLng? target,
    double? zoom,
    double? tilt,
    double? bearing,
  }) {
    return AnyCameraPosition(
      target: target ?? this.target,
      zoom: zoom ?? this.zoom,
      tilt: tilt ?? this.tilt,
      bearing: bearing ?? this.bearing,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnyCameraPosition &&
          other.target == target &&
          other.zoom == zoom &&
          other.tilt == tilt &&
          other.bearing == bearing;

  @override
  int get hashCode => Object.hash(target, zoom, tilt, bearing);

  @override
  String toString() =>
      'AnyCameraPosition(target: $target, zoom: $zoom, tilt: $tilt, bearing: $bearing)';
}
