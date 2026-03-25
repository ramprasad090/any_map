import '../models/lat_lng.dart';

/// A place result returned by a search provider.
class AnyPlace {
  /// Unique identifier from the provider.
  final String id;

  /// Display name of the place.
  final String name;

  /// Full address or display string.
  final String address;

  /// Geographic location.
  final AnyLatLng position;

  /// Place category (e.g., "restaurant", "city", "road").
  final String? category;

  const AnyPlace({
    required this.id,
    required this.name,
    required this.address,
    required this.position,
    this.category,
  });

  @override
  String toString() => 'AnyPlace($name, $address)';
}

/// Abstract interface for places/geocoding search.
abstract class AnySearchProvider {
  /// Human-readable name of the provider.
  String get name;

  /// Search for places matching [query].
  ///
  /// Optionally bias results towards [near] location within [radiusKm].
  Future<List<AnyPlace>> search(
    String query, {
    AnyLatLng? near,
    double radiusKm = 50,
    int limit = 5,
  });

  /// Reverse geocode a coordinate to a place.
  Future<AnyPlace?> reverseGeocode(AnyLatLng position);
}
