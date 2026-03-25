import '../models/lat_lng.dart';
import '../models/lat_lng_bounds.dart';

/// A floor in an indoor map.
class AnyIndoorFloor {
  /// Floor number (0 = ground, -1 = basement, 1 = first floor, etc.).
  final int level;

  /// Display label (e.g. "Ground Floor", "L1", "B1").
  final String label;

  /// Whether this is the default floor to show.
  final bool isDefault;

  /// GeoJSON or style layer for this floor's layout.
  final String? geoJson;

  /// Image overlay URL for floor plan.
  final String? floorPlanUrl;

  /// Bounds for the floor plan image overlay.
  final AnyLatLngBounds? floorPlanBounds;

  const AnyIndoorFloor({
    required this.level,
    required this.label,
    this.isDefault = false,
    this.geoJson,
    this.floorPlanUrl,
    this.floorPlanBounds,
  });
}

/// An indoor point of interest.
class AnyIndoorPOI {
  /// Unique identifier for this POI.
  final String id;

  /// Display name of the POI.
  final String name;

  /// Geographic position of the POI.
  final AnyLatLng position;

  /// Floor level where the POI is located.
  final int floorLevel;

  /// Category of the POI (e.g. "store", "restaurant", "restroom", "elevator").
  final String? category;

  /// Optional description text for the POI.
  final String? description;

  const AnyIndoorPOI({
    required this.id,
    required this.name,
    required this.position,
    required this.floorLevel,
    this.category,
    this.description,
  });
}

/// An indoor venue (mall, airport, hospital, etc.).
class AnyIndoorVenue {
  /// Unique venue ID.
  final String id;

  /// Venue name.
  final String name;

  /// Venue category ("mall", "airport", "hospital", "museum", etc.).
  final String category;

  /// Center coordinate.
  final AnyLatLng center;

  /// Bounds of the venue.
  final AnyLatLngBounds bounds;

  /// Available floors.
  final List<AnyIndoorFloor> floors;

  /// Points of interest within the venue.
  final List<AnyIndoorPOI> pois;

  /// Default floor level to show.
  int get defaultFloorLevel =>
      floors.firstWhere((f) => f.isDefault, orElse: () => floors.first).level;

  const AnyIndoorVenue({
    required this.id,
    required this.name,
    required this.category,
    required this.center,
    required this.bounds,
    required this.floors,
    this.pois = const [],
  });

  /// Get a specific floor by level.
  AnyIndoorFloor? getFloor(int level) {
    for (final f in floors) {
      if (f.level == level) return f;
    }
    return null;
  }
}

/// Abstract provider for indoor map data.
abstract class AnyIndoorMapProvider {
  /// Display name of this indoor map provider.
  String get name;

  /// Fetch venue data by ID.
  Future<AnyIndoorVenue?> getVenue(String venueId);

  /// Search for indoor venues near a location.
  Future<List<AnyIndoorVenue>> searchVenues(
    AnyLatLng near, {
    double radiusKm = 1.0,
    String? category,
  });
}
