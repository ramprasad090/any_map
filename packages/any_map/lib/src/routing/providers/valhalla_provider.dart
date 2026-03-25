import 'dart:convert';
import 'dart:io';

import '../../models/models.dart';
import '../polyline_codec.dart';
import '../route.dart';
import '../routing_provider.dart';

/// Routing provider using the Valhalla routing engine.
///
/// Free and self-hostable. Supports driving, walking, cycling, and transit.
///
/// ```dart
/// final provider = ValhallaRoutingProvider(
///   baseUrl: 'https://valhalla.example.com',
/// );
/// ```
class ValhallaRoutingProvider implements AnyRoutingProvider {
  final String baseUrl;
  final String? apiKey;

  @override
  String get name => 'Valhalla';

  ValhallaRoutingProvider({
    required this.baseUrl,
    this.apiKey,
  });

  @override
  Future<AnyRouteResult> getRoute(AnyRouteRequest request) async {
    try {
      final costing = _costingFromMode(request.mode);
      final locations = [
        request.origin,
        ...request.waypoints,
        request.destination,
      ]
          .map((p) => {'lat': p.latitude, 'lon': p.longitude})
          .toList();

      final body = jsonEncode({
        'locations': locations,
        'costing': costing,
        'directions_options': {
          'units': 'kilometers',
          if (request.language != null) 'language': request.language,
        },
        if (request.alternatives) 'alternates': 3,
      });

      final queryParams = <String, String>{};
      if (apiKey != null) queryParams['api_key'] = apiKey!;

      final uri = Uri.parse('$baseUrl/route').replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final client = HttpClient();
      final httpRequest = await client.postUrl(uri);
      httpRequest.headers.set('Content-Type', 'application/json');
      httpRequest.write(body);
      final httpResponse = await httpRequest.close();
      final responseBody = await httpResponse.transform(utf8.decoder).join();
      client.close();

      final json = jsonDecode(responseBody) as Map<String, dynamic>;

      if (json.containsKey('error')) {
        return AnyRouteResult.failure(json['error'] as String);
      }

      final trip = json['trip'] as Map<String, dynamic>;
      final legs = trip['legs'] as List;

      final routes = <AnyRoute>[];
      routes.add(_parseTrip(trip, legs));

      // Parse alternates if present.
      if (json.containsKey('alternates')) {
        for (final alt in json['alternates'] as List) {
          final altTrip = (alt as Map<String, dynamic>)['trip'] as Map<String, dynamic>;
          final altLegs = altTrip['legs'] as List;
          routes.add(_parseTrip(altTrip, altLegs));
        }
      }

      return AnyRouteResult.success(
        route: routes.first,
        alternatives: routes.skip(1).toList(),
      );
    } catch (e) {
      return AnyRouteResult.failure('Valhalla request failed: $e');
    }
  }

  AnyRoute _parseTrip(Map<String, dynamic> trip, List<dynamic> legs) {
    final allGeometry = <AnyLatLng>[];
    final allSteps = <AnyRouteStep>[];

    for (final leg in legs) {
      final legMap = leg as Map<String, dynamic>;
      final shape = legMap['shape'] as String;
      allGeometry.addAll(PolylineCodec.decode6(shape));

      final maneuvers = legMap['maneuvers'] as List? ?? [];
      for (final m in maneuvers) {
        final maneuver = m as Map<String, dynamic>;
        allSteps.add(AnyRouteStep(
          instruction: maneuver['instruction'] as String? ?? '',
          distanceMeters: ((maneuver['length'] as num?) ?? 0).toDouble() * 1000,
          durationSeconds: ((maneuver['time'] as num?) ?? 0).toDouble(),
          maneuver: _maneuverType(maneuver['type'] as int?),
          startLocation: AnyLatLng(
            (maneuver['begin_shape_index'] as int? ?? 0).toDouble(),
            0, // Will be mapped from geometry
          ),
          geometry: const [],
        ));
      }
    }

    // Fix start locations from geometry indices.
    final fixedSteps = allSteps.map((step) {
      final idx = step.startLocation.latitude.toInt();
      if (idx < allGeometry.length) {
        return AnyRouteStep(
          instruction: step.instruction,
          distanceMeters: step.distanceMeters,
          durationSeconds: step.durationSeconds,
          maneuver: step.maneuver,
          startLocation: allGeometry[idx],
          geometry: step.geometry,
        );
      }
      return step;
    }).toList();

    final summary = trip['summary'] as Map<String, dynamic>;

    return AnyRoute(
      geometry: allGeometry,
      distanceMeters: ((summary['length'] as num?) ?? 0).toDouble() * 1000,
      durationSeconds: ((summary['time'] as num?) ?? 0).toDouble(),
      bounds: AnyLatLngBounds.fromPoints(allGeometry),
      steps: fixedSteps,
      rawResponse: trip,
    );
  }

  String _costingFromMode(AnyTravelMode mode) {
    switch (mode) {
      case AnyTravelMode.driving:
        return 'auto';
      case AnyTravelMode.walking:
        return 'pedestrian';
      case AnyTravelMode.cycling:
        return 'bicycle';
      case AnyTravelMode.transit:
        return 'multimodal';
    }
  }

  String? _maneuverType(int? type) {
    if (type == null) return null;
    const types = {
      0: 'none',
      1: 'start',
      2: 'start-right',
      3: 'start-left',
      4: 'destination',
      5: 'destination-right',
      6: 'destination-left',
      7: 'becomes',
      8: 'continue',
      9: 'turn-slight-right',
      10: 'turn-right',
      11: 'turn-sharp-right',
      12: 'uturn-right',
      13: 'uturn-left',
      14: 'turn-sharp-left',
      15: 'turn-left',
      16: 'turn-slight-left',
      17: 'ramp-straight',
      18: 'ramp-right',
      19: 'ramp-left',
      20: 'exit-right',
      21: 'exit-left',
      22: 'stay-straight',
      23: 'stay-right',
      24: 'stay-left',
      25: 'merge',
      26: 'roundabout-enter',
      27: 'roundabout-exit',
      28: 'ferry-enter',
      29: 'ferry-exit',
    };
    return types[type];
  }
}
