import 'dart:convert';
import 'dart:io';

import '../../models/models.dart';
import '../polyline_codec.dart';
import '../route.dart';
import '../routing_provider.dart';

/// Routing provider using the OSRM (Open Source Routing Machine) API.
///
/// Free and self-hostable. Default endpoint uses the public demo server.
///
/// Supports:
/// - Turn-by-turn navigation with maneuver types
/// - Speed limit annotations
/// - Road class annotations (bridge, tunnel, toll, motorway)
/// - Lane guidance
/// - Congestion estimation from speed data
/// - Avoid tolls/highways/ferries (via exclude parameter)
///
/// ```dart
/// final provider = OsrmRoutingProvider();
/// final result = await provider.getRoute(AnyRouteRequest(
///   origin: AnyLatLng(17.3616, 78.4747),
///   destination: AnyLatLng(17.4435, 78.3772),
///   includeSpeedLimits: true,
///   includeAnnotations: true,
/// ));
/// ```
class OsrmRoutingProvider implements AnyRoutingProvider {
  final String baseUrl;

  @override
  String get name => 'OSRM';

  OsrmRoutingProvider({
    this.baseUrl = 'https://router.project-osrm.org',
  });

  @override
  Future<AnyRouteResult> getRoute(AnyRouteRequest request) async {
    try {
      final profile = _profileFromMode(request.mode);
      final coordinates = [
        request.origin,
        ...request.waypoints,
        request.destination,
      ].map((p) => '${p.longitude},${p.latitude}').join(';');

      // Build query parameters
      final params = <String, String>{
        'overview': 'full',
        'geometries': 'polyline',
        'steps': 'true',
        'alternatives': '${request.alternatives}',
      };

      // Request annotations for speed/congestion data
      // Only use annotations supported by the public OSRM demo server
      if (request.includeAnnotations || request.includeSpeedLimits) {
        params['annotations'] = 'speed,duration,distance';
      }

      final uri = Uri.parse(
        '$baseUrl/route/v1/$profile/$coordinates',
      ).replace(queryParameters: params);

      final client = HttpClient();
      final httpRequest = await client.getUrl(uri);
      final httpResponse = await httpRequest.close();
      final body = await httpResponse.transform(utf8.decoder).join();
      client.close();

      final json = jsonDecode(body) as Map<String, dynamic>;

      if (json['code'] != 'Ok') {
        return AnyRouteResult.failure(
          json['message'] as String? ?? 'OSRM error: ${json['code']}',
        );
      }

      final routes = (json['routes'] as List)
          .map((r) => _parseRoute(r as Map<String, dynamic>, request))
          .toList();

      if (routes.isEmpty) {
        return const AnyRouteResult.failure('No route found');
      }

      return AnyRouteResult.success(
        route: routes.first,
        alternatives: routes.skip(1).toList(),
      );
    } catch (e) {
      return AnyRouteResult.failure('OSRM request failed: $e');
    }
  }

  AnyRoute _parseRoute(
      Map<String, dynamic> json, AnyRouteRequest request) {
    final geometry = PolylineCodec.decode(json['geometry'] as String);
    final legs = json['legs'] as List;

    final steps = <AnyRouteStep>[];
    final segments = <AnyRouteSegment>[];

    for (final leg in legs) {
      final legMap = leg as Map<String, dynamic>;

      // Parse steps with lane guidance and annotations
      for (final step in legMap['steps'] as List) {
        final s = step as Map<String, dynamic>;
        final maneuver = s['maneuver'] as Map<String, dynamic>;
        final location = maneuver['location'] as List;
        final stepGeometry = s['geometry'] as String?;

        // Parse lane guidance (intersections → lanes)
        final lanes = <AnyLaneInfo>[];
        final intersections = s['intersections'] as List?;
        if (intersections != null && intersections.isNotEmpty) {
          final firstIntersection =
              intersections.first as Map<String, dynamic>;
          final laneData = firstIntersection['lanes'] as List?;
          if (laneData != null) {
            for (final lane in laneData) {
              final l = lane as Map<String, dynamic>;
              lanes.add(AnyLaneInfo(
                isActive: l['valid'] as bool? ?? false,
                directions: (l['indications'] as List?)
                        ?.map((d) => d.toString())
                        .toList() ??
                    [],
              ));
            }
          }
        }

        // Parse road class from intersections
        final roadClasses = s['intersections'] != null
            ? _parseRoadClassFromStep(s)
            : AnyRoadClass.other;

        // Parse speed limit from step's max_speed annotation
        AnySpeedLimit? speedLimit;
        final maxSpeed = s['max_speed'] as Map<String, dynamic>?;
        if (maxSpeed != null && maxSpeed['speed'] != null) {
          speedLimit = AnySpeedLimit(
            speedKmh: (maxSpeed['speed'] as num).toDouble(),
            isExplicit: maxSpeed['unknown'] != true,
          );
        }

        // Detect bridge/tunnel from step mode/classes
        final classes = (s['classes'] as List?)
                ?.map((c) => c.toString())
                .toSet() ??
            {};
        final isBridge = classes.contains('bridge');
        final isTunnel = classes.contains('tunnel');
        final isToll = classes.contains('toll');
        final isFerry = classes.contains('ferry');
        final isMotorway = classes.contains('motorway');

        final annotation = (isBridge || isTunnel || isToll || isFerry || isMotorway || speedLimit != null)
            ? AnyRouteAnnotation(
                isBridge: isBridge,
                isTunnel: isTunnel,
                isToll: isToll,
                isFerry: isFerry,
                isMotorway: isMotorway,
                speedLimit: speedLimit,
                roadName: s['name'] as String?,
                roadClass: roadClasses,
              )
            : null;

        steps.add(AnyRouteStep(
          instruction: _buildInstruction(maneuver, s['name'] as String? ?? '',
              isBridge: isBridge, isTunnel: isTunnel, isToll: isToll),
          distanceMeters: (s['distance'] as num).toDouble(),
          durationSeconds: (s['duration'] as num).toDouble(),
          maneuver: maneuver['type'] as String?,
          startLocation: AnyLatLng(
            (location[1] as num).toDouble(),
            (location[0] as num).toDouble(),
          ),
          geometry: stepGeometry != null
              ? PolylineCodec.decode(stepGeometry)
              : const [],
          lanes: lanes,
          speedLimit: speedLimit,
          annotation: annotation,
          roadName: s['name'] as String?,
          roadRef: s['ref'] as String?,
        ));
      }

      // Parse per-segment annotations (speed/congestion)
      final annotationData =
          legMap['annotation'] as Map<String, dynamic>?;
      if (annotationData != null && geometry.length > 1) {
        final speeds = annotationData['speed'] as List?;
        final durations = annotationData['duration'] as List?;
        final maxSpeeds = annotationData['maxspeed'] as List?;

        // Segments are between consecutive geometry points
        final segCount =
            speeds?.length ?? (geometry.length > 1 ? geometry.length - 1 : 0);
        for (int i = 0; i < segCount && i < geometry.length - 1; i++) {
          final speed =
              speeds != null && i < speeds.length
                  ? (speeds[i] as num).toDouble()
                  : null;
          final dur =
              durations != null && i < durations.length
                  ? (durations[i] as num).toDouble()
                  : null;

          AnySpeedLimit? segSpeedLimit;
          if (maxSpeeds != null && i < maxSpeeds.length) {
            final ms = maxSpeeds[i];
            if (ms is Map<String, dynamic> && ms['speed'] != null) {
              segSpeedLimit = AnySpeedLimit(
                speedKmh: (ms['speed'] as num).toDouble(),
                isExplicit: ms['unknown'] != true,
              );
            }
          }

          segments.add(AnyRouteSegment(
            start: geometry[i],
            end: geometry[i + 1],
            speed: speed,
            duration: dur,
            congestion: _estimateCongestion(speed, segSpeedLimit),
            annotation: segSpeedLimit != null
                ? AnyRouteAnnotation(speedLimit: segSpeedLimit)
                : null,
          ));
        }
      }
    }

    return AnyRoute(
      geometry: geometry,
      distanceMeters: (json['distance'] as num).toDouble(),
      durationSeconds: (json['duration'] as num).toDouble(),
      bounds: AnyLatLngBounds.fromPoints(geometry),
      steps: steps,
      segments: segments,
      rawResponse: json,
    );
  }

  AnyCongestionLevel _estimateCongestion(
      double? speed, AnySpeedLimit? limit) {
    if (speed == null) return AnyCongestionLevel.unknown;
    if (limit != null && limit.speedKmh > 0) {
      final speedKmh = speed * 3.6; // m/s to km/h
      final ratio = speedKmh / limit.speedKmh;
      if (ratio > 0.8) return AnyCongestionLevel.freeFlow;
      if (ratio > 0.5) return AnyCongestionLevel.slow;
      if (ratio > 0.2) return AnyCongestionLevel.congested;
      return AnyCongestionLevel.blocked;
    }
    // Estimate from absolute speed for driving
    final speedKmh = speed * 3.6;
    if (speedKmh > 50) return AnyCongestionLevel.freeFlow;
    if (speedKmh > 25) return AnyCongestionLevel.slow;
    if (speedKmh > 5) return AnyCongestionLevel.congested;
    return AnyCongestionLevel.blocked;
  }

  AnyRoadClass _parseRoadClassFromStep(Map<String, dynamic> step) {
    final classes = (step['classes'] as List?)
            ?.map((c) => c.toString())
            .toSet() ??
        {};
    if (classes.contains('motorway')) return AnyRoadClass.motorway;
    if (classes.contains('trunk')) return AnyRoadClass.trunk;
    if (classes.contains('primary')) return AnyRoadClass.primary;
    if (classes.contains('secondary')) return AnyRoadClass.secondary;
    if (classes.contains('tertiary')) return AnyRoadClass.tertiary;
    return AnyRoadClass.other;
  }

  String _buildInstruction(
    Map<String, dynamic> maneuver,
    String name, {
    bool isBridge = false,
    bool isTunnel = false,
    bool isToll = false,
  }) {
    final type = maneuver['type'] as String? ?? '';
    final modifier = maneuver['modifier'] as String? ?? '';

    String prefix = '';
    if (isBridge) prefix = 'Take flyover, ';
    if (isTunnel) prefix = 'Enter tunnel, ';
    if (isToll) prefix = 'Toll road, ';

    if (type == 'arrive') return '${prefix}Arrive at your destination';
    if (type == 'depart') {
      return name.isNotEmpty ? '${prefix}Head on $name' : '${prefix}Depart';
    }

    final direction = modifier.isNotEmpty ? modifier.replaceAll('-', ' ') : '';
    if (name.isNotEmpty) {
      return '${prefix}Turn $direction onto $name'.trim();
    }
    return '${prefix}Turn $direction'.trim();
  }

  String _profileFromMode(AnyTravelMode mode) {
    switch (mode) {
      case AnyTravelMode.driving:
        return 'driving';
      case AnyTravelMode.walking:
        return 'foot';
      case AnyTravelMode.cycling:
        return 'bike';
      case AnyTravelMode.transit:
        return 'driving'; // OSRM doesn't support transit
    }
  }
}
