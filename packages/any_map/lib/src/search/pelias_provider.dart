import 'dart:convert';
import 'dart:io';

import '../models/lat_lng.dart';
import 'search_provider.dart';

/// Geocoding provider using [Pelias](https://pelias.io) —
/// a modular, open-source geocoder with structured, high-quality output.
///
/// ## Cost
/// - **Self-hosted = completely free** (no API key, no rate limit).
///   Run your own instance: https://github.com/pelias/docker
/// - `geocode.earth` is a paid managed service — omit [apiKey] and use your
///   own [baseUrl] to avoid any cost.
///
/// ## Usage (self-hosted, free)
/// ```dart
/// final search = PeliasSearchProvider(
///   baseUrl: 'http://localhost:4000/v1', // your own Docker instance
/// );
/// final results = await search.search('HITEC City');
/// ```
class PeliasSearchProvider implements AnySearchProvider {
  /// Pelias API base URL.
  final String baseUrl;

  /// Optional API key (required for hosted services like geocode.earth).
  final String? apiKey;

  @override
  String get name => 'Pelias';

  PeliasSearchProvider({
    this.baseUrl = 'https://api.geocode.earth/v1',
    this.apiKey,
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
        'text': query,
        'size': '$limit',
      };
      if (apiKey != null) params['api_key'] = apiKey!;
      if (near != null) {
        params['focus.point.lat'] = '${near.latitude}';
        params['focus.point.lon'] = '${near.longitude}';
      }

      final uri = Uri.parse('$baseUrl/search').replace(queryParameters: params);
      final body = await _get(uri);
      return _parseFeatures(body);
    } catch (_) {
      return [];
    }
  }

  @override
  Future<AnyPlace?> reverseGeocode(AnyLatLng position) async {
    try {
      final params = <String, String>{
        'point.lat': '${position.latitude}',
        'point.lon': '${position.longitude}',
        'size': '1',
      };
      if (apiKey != null) params['api_key'] = apiKey!;

      final uri = Uri.parse('$baseUrl/reverse').replace(queryParameters: params);
      final body = await _get(uri);
      final places = _parseFeatures(body);
      return places.isEmpty ? null : places.first;
    } catch (_) {
      return null;
    }
  }

  List<AnyPlace> _parseFeatures(String body) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    final features = json['features'] as List? ?? [];
    return features.map((f) {
      final feat = f as Map<String, dynamic>;
      final props = feat['properties'] as Map<String, dynamic>;
      final geom = feat['geometry'] as Map<String, dynamic>;
      final coords = geom['coordinates'] as List;

      return AnyPlace(
        id: props['id'] as String? ?? props['gid'] as String? ?? '',
        name: props['name'] as String? ?? props['label'] as String? ?? '',
        address: props['label'] as String? ?? '',
        position: AnyLatLng(
          (coords[1] as num).toDouble(),
          (coords[0] as num).toDouble(),
        ),
        category: props['layer'] as String?,
      );
    }).toList();
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
