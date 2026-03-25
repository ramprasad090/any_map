import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import '../models/lat_lng.dart';
import 'search_provider.dart';

/// Places search provider using Nominatim (free OpenStreetMap geocoding).
///
/// ```dart
/// final search = NominatimSearchProvider();
/// final results = await search.search('Charminar', near: AnyLatLng(17.3616, 78.4747));
/// ```
class NominatimSearchProvider implements AnySearchProvider {
  /// Base URL for the Nominatim API.
  final String baseUrl;

  @override
  String get name => 'Nominatim';

  NominatimSearchProvider({
    this.baseUrl = 'https://nominatim.openstreetmap.org',
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
        'format': 'jsonv2',
        'limit': '$limit',
        'addressdetails': '1',
      };

      if (near != null) {
        final dLat = radiusKm / 111.0;
        final dLon =
            radiusKm / (111.0 * math.cos(near.latitude * math.pi / 180));
        params['viewbox'] =
            '${near.longitude - dLon},${near.latitude + dLat},'
            '${near.longitude + dLon},${near.latitude - dLat}';
        params['bounded'] = '0';
      }

      final uri = Uri.parse('$baseUrl/search').replace(queryParameters: params);
      final body = await _get(uri);
      final list = jsonDecode(body) as List;

      return list.map((item) {
        final j = item as Map<String, dynamic>;
        return AnyPlace(
          id: j['place_id'].toString(),
          name: j['name'] as String? ?? j['display_name'] as String,
          address: j['display_name'] as String,
          position: AnyLatLng(
            double.parse(j['lat'] as String),
            double.parse(j['lon'] as String),
          ),
          category: j['category'] as String?,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<AnyPlace?> reverseGeocode(AnyLatLng position) async {
    try {
      final uri = Uri.parse('$baseUrl/reverse').replace(queryParameters: {
        'lat': '${position.latitude}',
        'lon': '${position.longitude}',
        'format': 'jsonv2',
      });

      final body = await _get(uri);
      final j = jsonDecode(body) as Map<String, dynamic>;

      if (j.containsKey('error')) return null;

      return AnyPlace(
        id: j['place_id'].toString(),
        name: j['name'] as String? ?? j['display_name'] as String,
        address: j['display_name'] as String,
        position: AnyLatLng(
          double.parse(j['lat'] as String),
          double.parse(j['lon'] as String),
        ),
        category: j['category'] as String?,
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
