import 'dart:convert';
import 'dart:io';

import '../../models/models.dart';
import '../polyline_codec.dart';
import '../route.dart';
import '../routing_provider.dart';

/// Routing provider using the GraphHopper Directions API.
///
/// Requires an API key from graphhopper.com (free tier available).
///
/// ```dart
/// final provider = GraphHopperRoutingProvider(apiKey: 'YOUR_KEY');
/// ```
class GraphHopperRoutingProvider implements AnyRoutingProvider {
  final String apiKey;
  final String baseUrl;

  @override
  String get name => 'GraphHopper';

  GraphHopperRoutingProvider({
    required this.apiKey,
    this.baseUrl = 'https://graphhopper.com/api/1',
  });

  @override
  Future<AnyRouteResult> getRoute(AnyRouteRequest request) async {
    try {
      final vehicle = _vehicleFromMode(request.mode);
      final points = [
        request.origin,
        ...request.waypoints,
        request.destination,
      ];

      final queryParams = {
        'key': apiKey,
        'vehicle': vehicle,
        'locale': request.language ?? 'en',
        'instructions': 'true',
        'calc_points': 'true',
        'points_encoded': 'true',
        if (request.alternatives) 'algorithm': 'alternative_route',
      };

      // Add points as repeated params.
      final pointParams = points
          .map((p) => 'point=${p.latitude},${p.longitude}')
          .join('&');

      final uri = Uri.parse(
        '$baseUrl/route?$pointParams&${Uri(queryParameters: queryParams).query}',
      );

      final client = HttpClient();
      final httpRequest = await client.getUrl(uri);
      final httpResponse = await httpRequest.close();
      final body = await httpResponse.transform(utf8.decoder).join();
      client.close();

      final json = jsonDecode(body) as Map<String, dynamic>;

      if (json.containsKey('message')) {
        return AnyRouteResult.failure(json['message'] as String);
      }

      final paths = json['paths'] as List;
      if (paths.isEmpty) {
        return const AnyRouteResult.failure('No route found');
      }

      final routes = paths
          .map((p) => _parsePath(p as Map<String, dynamic>))
          .toList();

      return AnyRouteResult.success(
        route: routes.first,
        alternatives: routes.skip(1).toList(),
      );
    } catch (e) {
      return AnyRouteResult.failure('GraphHopper request failed: $e');
    }
  }

  AnyRoute _parsePath(Map<String, dynamic> path) {
    final pointsEncoded = path['points'] as String;
    final geometry = PolylineCodec.decode(pointsEncoded);

    final steps = <AnyRouteStep>[];
    final instructions = path['instructions'] as List? ?? [];
    for (final instr in instructions) {
      final i = instr as Map<String, dynamic>;
      final interval = (i['interval'] as List?) ?? [];
      final startIdx = interval.isNotEmpty ? (interval[0] as int) : 0;
      final endIdx = interval.length > 1 ? (interval[1] as int) : startIdx;

      steps.add(AnyRouteStep(
        instruction: i['text'] as String? ?? '',
        distanceMeters: (i['distance'] as num).toDouble(),
        durationSeconds: (i['time'] as num).toDouble() / 1000,
        maneuver: _signToManeuver(i['sign'] as int?),
        startLocation: startIdx < geometry.length
            ? geometry[startIdx]
            : geometry.first,
        geometry: (startIdx < geometry.length && endIdx <= geometry.length)
            ? geometry.sublist(startIdx, endIdx)
            : const [],
      ));
    }

    return AnyRoute(
      geometry: geometry,
      distanceMeters: (path['distance'] as num).toDouble(),
      durationSeconds: (path['time'] as num).toDouble() / 1000,
      bounds: AnyLatLngBounds.fromPoints(geometry),
      steps: steps,
      rawResponse: path,
    );
  }

  String _vehicleFromMode(AnyTravelMode mode) {
    switch (mode) {
      case AnyTravelMode.driving:
        return 'car';
      case AnyTravelMode.walking:
        return 'foot';
      case AnyTravelMode.cycling:
        return 'bike';
      case AnyTravelMode.transit:
        return 'car'; // GraphHopper doesn't support transit in basic API
    }
  }

  String? _signToManeuver(int? sign) {
    if (sign == null) return null;
    const signs = {
      -98: 'u-turn',
      -8: 'u-turn-left',
      -7: 'keep-left',
      -3: 'turn-sharp-left',
      -2: 'turn-left',
      -1: 'turn-slight-left',
      0: 'continue',
      1: 'turn-slight-right',
      2: 'turn-right',
      3: 'turn-sharp-right',
      4: 'arrive',
      5: 'reached-via',
      6: 'roundabout',
      7: 'keep-right',
      8: 'u-turn-right',
    };
    return signs[sign];
  }
}
