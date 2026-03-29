import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import '../models/lat_lng.dart';
import 'search_provider.dart';

/// Predefined place-type categories for nearby search.
///
/// Maps to Overpass API `amenity`, `shop`, `tourism`, `healthcare` tags.
enum AnyPlaceType {
  /// Restaurants, cafes, fast food.
  restaurant('amenity', ['restaurant', 'cafe', 'fast_food']),

  /// Hospitals, clinics, doctors.
  hospital('amenity', ['hospital', 'clinic', 'doctors']),

  /// ATMs and banks.
  atm('amenity', ['atm', 'bank']),

  /// Petrol / fuel stations.
  fuelStation('amenity', ['fuel']),

  /// Pharmacies.
  pharmacy('amenity', ['pharmacy']),

  /// Supermarkets and convenience stores.
  supermarket('shop', ['supermarket', 'convenience']),

  /// Hotels, motels, hostels.
  hotel('tourism', ['hotel', 'motel', 'hostel', 'guest_house']),

  /// Car parks.
  parking('amenity', ['parking']),

  /// Tourist attractions.
  attraction('tourism', ['attraction', 'museum', 'viewpoint', 'artwork']),

  /// Airports.
  airport('aeroway', ['aerodrome']),

  /// Bus stops and transit stations.
  transitStop('public_transport', ['stop_position', 'station']);

  final String _osmKey;
  final List<String> _osmValues;
  const AnyPlaceType(this._osmKey, this._osmValues);

  /// Build an Overpass union filter for this type.
  String get _overpassUnion => _osmValues
      .map((v) => 'node["$_osmKey"="$v"](around:RADIUS,LAT,LNG);')
      .join('\n');
}

/// A nearby place result enriched with opening hours and phone (when available).
class AnyNearbyPlace extends AnyPlace {
  /// Distance from the search origin in metres.
  final double? distanceMeters;

  /// Opening hours string (e.g. "Mo-Fr 09:00-18:00").
  final String? openingHours;

  /// Phone number.
  final String? phone;

  /// Website URL.
  final String? website;

  const AnyNearbyPlace({
    required super.id,
    required super.name,
    required super.address,
    required super.position,
    super.category,
    this.distanceMeters,
    this.openingHours,
    this.phone,
    this.website,
  });

  /// Distance formatted as a human-readable string.
  String? get distanceText {
    if (distanceMeters == null) return null;
    if (distanceMeters! < 1000) return '${distanceMeters!.round()} m';
    return '${(distanceMeters! / 1000).toStringAsFixed(1)} km';
  }
}

/// Search for nearby places of interest via the Overpass API.
///
/// Free and open — no API key required. Uses the public Overpass instance
/// by default.
///
/// ```dart
/// final results = await AnyPlaces.nearby(
///   location: AnyLatLng(17.3850, 78.4867),
///   radius: 500,
///   type: AnyPlaceType.hospital,
/// );
///
/// for (final place in results) {
///   print('${place.name} — ${place.distanceText}');
/// }
/// ```
class AnyPlaces {
  /// Overpass API endpoint.
  final String baseUrl;

  AnyPlaces({
    this.baseUrl = 'https://overpass-api.de/api/interpreter',
  });

  /// Search for places of [type] within [radius] metres of [location].
  ///
  /// Results are sorted by distance. [limit] caps the returned count.
  Future<List<AnyNearbyPlace>> nearby({
    required AnyLatLng location,
    required AnyPlaceType type,
    double radius = 500,
    int limit = 20,
  }) async {
    final query = _buildQuery(location, type, radius);
    try {
      final uri = Uri.parse(baseUrl);
      final client = HttpClient();
      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType('application', 'x-www-form-urlencoded');
      request.headers.set('User-Agent', 'any_map_flutter/1.0');
      final encoded = Uri.encodeComponent(query);
      request.write('data=$encoded');
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      client.close();

      final json = jsonDecode(body) as Map<String, dynamic>;
      final elements = json['elements'] as List? ?? [];

      final places = <AnyNearbyPlace>[];
      for (final el in elements) {
        final e = el as Map<String, dynamic>;
        if (e['type'] != 'node') continue;
        final lat = (e['lat'] as num).toDouble();
        final lng = (e['lon'] as num).toDouble();
        final tags = e['tags'] as Map<String, dynamic>? ?? {};
        final name = tags['name'] as String?;
        if (name == null || name.isEmpty) continue;

        final dist = _haversine(location, AnyLatLng(lat, lng));
        places.add(AnyNearbyPlace(
          id: e['id'].toString(),
          name: name,
          address: _buildAddress(tags),
          position: AnyLatLng(lat, lng),
          category: type.name,
          distanceMeters: dist,
          openingHours: tags['opening_hours'] as String?,
          phone: tags['phone'] as String?,
          website: tags['website'] as String?,
        ));
      }

      places.sort((a, b) => (a.distanceMeters ?? 0).compareTo(b.distanceMeters ?? 0));
      return places.take(limit).toList();
    } catch (_) {
      return [];
    }
  }

  String _buildQuery(AnyLatLng loc, AnyPlaceType type, double radius) {
    final filters = type._overpassUnion
        .replaceAll('RADIUS', radius.toStringAsFixed(0))
        .replaceAll('LAT', loc.latitude.toString())
        .replaceAll('LNG', loc.longitude.toString());
    return '[out:json][timeout:15];\n(\n$filters\n);\nout body;';
  }

  String _buildAddress(Map<String, dynamic> tags) {
    final parts = <String>[];
    if (tags['addr:housenumber'] != null) parts.add(tags['addr:housenumber'] as String);
    if (tags['addr:street'] != null) parts.add(tags['addr:street'] as String);
    if (tags['addr:city'] != null) parts.add(tags['addr:city'] as String);
    if (parts.isEmpty && tags['description'] != null) parts.add(tags['description'] as String);
    return parts.join(', ');
  }

  double _haversine(AnyLatLng a, AnyLatLng b) {
    const r = 6371000.0;
    final dLat = (b.latitude - a.latitude) * math.pi / 180;
    final dLng = (b.longitude - a.longitude) * math.pi / 180;
    final sinDLat = math.sin(dLat / 2);
    final sinDLng = math.sin(dLng / 2);
    final h = sinDLat * sinDLat +
        math.cos(a.latitude * math.pi / 180) *
            math.cos(b.latitude * math.pi / 180) *
            sinDLng *
            sinDLng;
    return 2 * r * math.asin(math.sqrt(h));
  }
}
