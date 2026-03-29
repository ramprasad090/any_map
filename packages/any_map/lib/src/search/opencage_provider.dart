import 'dart:convert';
import 'dart:io';

import '../models/lat_lng.dart';
import 'search_provider.dart';

/// Geocoding provider using [OpenCage](https://opencagedata.com).
///
/// ## Cost
/// - **Free tier**: 2,500 requests/day (no credit card required to start).
/// - Paid plans for higher volume.
/// - If you need unlimited free geocoding, use [PhotonSearchProvider] (self-hostable,
///   no rate limit) or [PeliasSearchProvider] (self-hostable Docker instance).
///
/// Requires a free API key from https://opencagedata.com/api.
///
/// ```dart
/// final search = OpenCageSearchProvider(apiKey: 'YOUR_FREE_API_KEY');
/// final results = await search.search('Golconda Fort');
/// ```
class OpenCageSearchProvider implements AnySearchProvider {
  /// OpenCage API key. Get a free key at https://opencagedata.com/api.
  final String apiKey;

  /// OpenCage API base URL.
  final String baseUrl;

  @override
  String get name => 'OpenCage';

  OpenCageSearchProvider({
    required this.apiKey,
    this.baseUrl = 'https://api.opencagedata.com/geocode/v1',
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
        'key': apiKey,
        'limit': '$limit',
        'no_annotations': '1',
        'language': 'en',
      };
      if (near != null) {
        // proximity biases results toward this location
        params['proximity'] = '${near.latitude},${near.longitude}';
      }

      final uri =
          Uri.parse('$baseUrl/json').replace(queryParameters: params);
      final body = await _get(uri);
      final json = jsonDecode(body) as Map<String, dynamic>;

      if ((json['status'] as Map?)?['code'] != 200) {
        return [];
      }

      final results = json['results'] as List? ?? [];
      return results.map((r) {
        final result = r as Map<String, dynamic>;
        final geom = result['geometry'] as Map<String, dynamic>;
        final components = result['components'] as Map<String, dynamic>? ?? {};
        final formatted = result['formatted'] as String? ?? '';

        final name = components['_normalized_city'] as String? ??
            components['city'] as String? ??
            components['town'] as String? ??
            components['road'] as String? ??
            formatted.split(',').first.trim();

        return AnyPlace(
          id: result['annotations']?['OSM']?['url'] as String? ??
              '${geom['lat']},${geom['lng']}',
          name: name,
          address: formatted,
          position: AnyLatLng(
            (geom['lat'] as num).toDouble(),
            (geom['lng'] as num).toDouble(),
          ),
          category: components['_type'] as String?,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<AnyPlace?> reverseGeocode(AnyLatLng position) async {
    try {
      final params = <String, String>{
        'q': '${position.latitude}+${position.longitude}',
        'key': apiKey,
        'limit': '1',
        'no_annotations': '1',
        'language': 'en',
      };

      final uri =
          Uri.parse('$baseUrl/json').replace(queryParameters: params);
      final body = await _get(uri);
      final json = jsonDecode(body) as Map<String, dynamic>;
      final results = json['results'] as List? ?? [];
      if (results.isEmpty) return null;

      final r = results.first as Map<String, dynamic>;
      final formatted = r['formatted'] as String? ?? '';
      final components = r['components'] as Map<String, dynamic>? ?? {};

      final name = components['road'] as String? ??
          components['city'] as String? ??
          formatted.split(',').first.trim();

      return AnyPlace(
        id: '${position.latitude},${position.longitude}',
        name: name,
        address: formatted,
        position: position,
        category: components['_type'] as String?,
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
