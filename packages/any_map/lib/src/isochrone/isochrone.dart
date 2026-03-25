import 'dart:convert';
import 'dart:io';
import '../models/lat_lng.dart';
import '../models/polygon.dart';
import 'dart:ui' show Color;

/// A single isochrone contour (reachability boundary).
class AnyIsochrone {
  /// Center point.
  final AnyLatLng center;

  /// Time in minutes this contour represents.
  final double minutes;

  /// Boundary coordinates forming the contour polygon.
  final List<AnyLatLng> boundary;

  const AnyIsochrone({
    required this.center,
    required this.minutes,
    required this.boundary,
  });

  /// Convert to a polygon for rendering.
  AnyPolygon toPolygon({
    String? id,
    Color? fillColor,
    Color? strokeColor,
  }) {
    return AnyPolygon(
      id: id ?? 'isochrone_${minutes.round()}',
      points: boundary,
      fillColor: fillColor ?? const Color(0x334285F4),
      strokeColor: strokeColor ?? const Color(0xFF4285F4),
      strokeWidth: 2.0,
    );
  }
}

/// Request for isochrone calculation.
class AnyIsochroneRequest {
  /// Center point.
  final AnyLatLng center;

  /// Time contours in minutes (e.g. [5, 10, 15, 30]).
  final List<double> contourMinutes;

  /// Travel mode.
  final String profile; // "driving", "walking", "cycling"

  const AnyIsochroneRequest({
    required this.center,
    required this.contourMinutes,
    this.profile = 'driving',
  });
}

/// Abstract isochrone provider.
abstract class AnyIsochroneProvider {
  /// Display name of this isochrone provider.
  String get name;

  /// Calculate isochrone contours.
  Future<List<AnyIsochrone>> getIsochrones(AnyIsochroneRequest request);
}

/// Valhalla-based isochrone provider (free, self-hostable).
class ValhallaIsochroneProvider implements AnyIsochroneProvider {
  /// Base URL of the Valhalla routing server.
  final String baseUrl;

  @override
  String get name => 'Valhalla';

  /// Creates a Valhalla isochrone provider pointed at the given server URL.
  ValhallaIsochroneProvider({required this.baseUrl});

  @override
  Future<List<AnyIsochrone>> getIsochrones(AnyIsochroneRequest request) async {
    try {
      final costing = switch (request.profile) {
        'walking' => 'pedestrian',
        'cycling' => 'bicycle',
        _ => 'auto',
      };

      final body = jsonEncode({
        'locations': [
          {
            'lat': request.center.latitude,
            'lon': request.center.longitude,
          }
        ],
        'costing': costing,
        'contours': request.contourMinutes
            .map((m) => {'time': m})
            .toList(),
        'polygons': true,
      });

      final client = HttpClient();
      final httpRequest = await client.postUrl(
        Uri.parse('$baseUrl/isochrone'),
      );
      httpRequest.headers.set('Content-Type', 'application/json');
      httpRequest.write(body);
      final response = await httpRequest.close();
      final responseBody = await response.transform(utf8.decoder).join();
      client.close();

      final json = jsonDecode(responseBody) as Map<String, dynamic>;
      final features = json['features'] as List?;
      if (features == null) return [];

      return features.map((f) {
        final feature = f as Map<String, dynamic>;
        final props = feature['properties'] as Map<String, dynamic>;
        final geometry = feature['geometry'] as Map<String, dynamic>;
        final coords = (geometry['coordinates'] as List).first as List;

        return AnyIsochrone(
          center: request.center,
          minutes: (props['contour'] as num).toDouble(),
          boundary: coords
              .map((c) => AnyLatLng(
                    (c[1] as num).toDouble(),
                    (c[0] as num).toDouble(),
                  ))
              .toList(),
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }
}
