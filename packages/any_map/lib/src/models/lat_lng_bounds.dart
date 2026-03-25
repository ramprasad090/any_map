import 'lat_lng.dart';

/// A rectangular geographical area defined by its southwest and northeast corners.
class AnyLatLngBounds {
  /// The southwest corner of the bounding rectangle.
  final AnyLatLng southwest;

  /// The northeast corner of the bounding rectangle.
  final AnyLatLng northeast;

  const AnyLatLngBounds({
    required this.southwest,
    required this.northeast,
  });

  /// Creates bounds that contain all the given points.
  factory AnyLatLngBounds.fromPoints(List<AnyLatLng> points) {
    assert(points.isNotEmpty, 'Points list must not be empty');
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;
    for (final point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }
    return AnyLatLngBounds(
      southwest: AnyLatLng(minLat, minLng),
      northeast: AnyLatLng(maxLat, maxLng),
    );
  }

  /// Center point of the bounds.
  AnyLatLng get center => AnyLatLng(
        (southwest.latitude + northeast.latitude) / 2,
        (southwest.longitude + northeast.longitude) / 2,
      );

  /// Whether the given point is within these bounds.
  bool contains(AnyLatLng point) =>
      point.latitude >= southwest.latitude &&
      point.latitude <= northeast.latitude &&
      point.longitude >= southwest.longitude &&
      point.longitude <= northeast.longitude;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnyLatLngBounds &&
          other.southwest == southwest &&
          other.northeast == northeast;

  @override
  int get hashCode => Object.hash(southwest, northeast);
}
