import 'dart:convert';
import 'dart:io';

import '../models/lat_lng.dart';
import 'search_provider.dart';

/// Geocoding provider using [Photon](https://photon.komoot.io) —
/// a fast, self-hostable OpenStreetMap geocoder with no rate limit on
/// self-hosted instances.
///
/// The default endpoint uses Komoot's public server (fair-use policy applies).
/// Point [baseUrl] at your own instance for unlimited requests.
///
/// ```dart
/// // Drop-in replacement for NominatimSearchProvider
/// final search = PhotonSearchProvider();
/// final results = await search.search('Charminar', near: AnyLatLng(17.36, 78.47));
/// ```
class PhotonSearchProvider implements AnySearchProvider {
  /// Photon API base URL.
  final String baseUrl;

  @override
  String get name => 'Photon';

  PhotonSearchProvider({
    this.baseUrl = 'https://photon.komoot.io',
  });

  @override
  Future<List<AnyPlace>> search(
    String query, {
    AnyLatLng? near,
    double radiusKm = 50,
    int limit = 5,
  }) async {
    try {
      final params = <String, String>{
        'q': query,
        'limit': '$limit',
        'lang': 'en',
      };
      if (near != null) {
        params['lat'] = '${near.latitude}';
        params['lon'] = '${near.longitude}';
      }

      final uri = Uri.parse('$baseUrl/api').replace(queryParameters: params);
      final body = await _get(uri);
      final json = jsonDecode(body) as Map<String, dynamic>;
      final features = json['features'] as List? ?? [];

      return features.map((f) {
        final feat = f as Map<String, dynamic>;
        final props = feat['properties'] as Map<String, dynamic>;
        final geom = feat['geometry'] as Map<String, dynamic>;
        final coords = geom['coordinates'] as List;
        final lat = (coords[1] as num).toDouble();
        final lng = (coords[0] as num).toDouble();

        final nameParts = <String>[
          if (props['name'] != null) props['name'] as String,
          if (props['city'] != null) props['city'] as String,
          if (props['country'] != null) props['country'] as String,
        ];

        return AnyPlace(
          id: '${props['osm_type'] ?? 'N'}${props['osm_id'] ?? 0}',
          name: props['name'] as String? ?? nameParts.first,
          address: nameParts.join(', '),
          position: AnyLatLng(lat, lng),
          category: props['osm_key'] as String?,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<AnyPlace?> reverseGeocode(AnyLatLng position) async {
    try {
      final uri = Uri.parse('$baseUrl/reverse').replace(queryParameters: {
        'lat': '${position.latitude}',
        'lon': '${position.longitude}',
        'limit': '1',
      });
      final body = await _get(uri);
      final json = jsonDecode(body) as Map<String, dynamic>;
      final features = json['features'] as List? ?? [];
      if (features.isEmpty) return null;

      final feat = features.first as Map<String, dynamic>;
      final props = feat['properties'] as Map<String, dynamic>;
      final nameParts = <String>[
        if (props['name'] != null) props['name'] as String,
        if (props['city'] != null) props['city'] as String,
        if (props['country'] != null) props['country'] as String,
      ];

      return AnyPlace(
        id: '${props['osm_type'] ?? 'N'}${props['osm_id'] ?? 0}',
        name: props['name'] as String? ?? (nameParts.isNotEmpty ? nameParts.first : ''),
        address: nameParts.join(', '),
        position: position,
        category: props['osm_key'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  Future<String> _get(Uri uri) async {
    final client = HttpClient();
    final request = await client.getUrl(uri);
    request.headers.set('User-Agent', 'any_map_flutter/1.0');
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    client.close();
    return body;
  }
}
