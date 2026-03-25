import 'dart:math' as math;

/// A geographical coordinate with latitude and longitude.
class AnyLatLng {
  /// The latitude in degrees, ranging from -90 to 90.
  final double latitude;

  /// The longitude in degrees, ranging from -180 to 180.
  final double longitude;

  const AnyLatLng(this.latitude, this.longitude)
      : assert(latitude >= -90 && latitude <= 90),
        assert(longitude >= -180 && longitude <= 180);

  /// Distance in meters to another point using Haversine formula.
  double distanceTo(AnyLatLng other) {
    const earthRadius = 6371000.0; // meters
    final dLat = _toRadians(other.latitude - latitude);
    final dLng = _toRadians(other.longitude - longitude);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(latitude)) *
            math.cos(_toRadians(other.latitude)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  static double _toRadians(double degrees) => degrees * math.pi / 180;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnyLatLng &&
          other.latitude == latitude &&
          other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);

  @override
  String toString() => 'AnyLatLng($latitude, $longitude)';

  /// Serializes this coordinate to a JSON-compatible map.
  Map<String, double> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
      };

  /// Creates an [AnyLatLng] from a JSON map with `latitude` and `longitude` keys.
  factory AnyLatLng.fromJson(Map<String, dynamic> json) => AnyLatLng(
        (json['latitude'] as num).toDouble(),
        (json['longitude'] as num).toDouble(),
      );
}
