import 'dart:convert';
import 'dart:io';

import '../models/lat_lng.dart';
import '../models/polyline.dart';
import '../models/lat_lng_bounds.dart';
import 'polyline_codec.dart';
import 'package:flutter/painting.dart' show Color;

/// The result of a multi-stop route optimization.
class AnyOptimizedRoute {
  /// Whether the request succeeded.
  final bool isSuccess;

  /// Error message if [isSuccess] is false.
  final String? error;

  /// The optimized stop order (indices into the original [stops] list).
  ///
  /// Example: if you pass stops [A, B, C, D] and the optimal order is
  /// A→C→B→D, this list will be [0, 2, 1, 3].
  final List<int> waypointOrder;

  /// Geometry of the full optimized route (all legs combined).
  final List<AnyLatLng> geometry;

  /// Total trip distance in metres.
  final double distanceMeters;

  /// Total trip duration in seconds.
  final double durationSeconds;

  /// Bounding box of the entire route.
  final AnyLatLngBounds? bounds;

  const AnyOptimizedRoute({
    required this.isSuccess,
    this.error,
    this.waypointOrder = const [],
    this.geometry = const [],
    this.distanceMeters = 0,
    this.durationSeconds = 0,
    this.bounds,
  });

  factory AnyOptimizedRoute.failure(String error) =>
      AnyOptimizedRoute(isSuccess: false, error: error);

  /// Distance formatted as a human-readable string.
  String get distanceText {
    if (distanceMeters < 1000) return '${distanceMeters.round()} m';
    return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
  }

  /// Duration formatted as a human-readable string.
  String get durationText {
    final m = (durationSeconds / 60).round();
    if (m < 60) return '$m min';
    return '${m ~/ 60}h ${m % 60}m';
  }

  /// Convert the geometry to an [AnyPolyline] for display.
  AnyPolyline toPolyline({
    String id = 'optimized_route',
    Color color = const Color(0xFF9C27B0),
    double width = 5.0,
  }) =>
      AnyPolyline(id: id, points: geometry, color: color, width: width);
}

/// Optimizes the order of multiple stops to minimize total travel time,
/// using the OSRM Trip API (which solves a Travelling Salesman Problem).
///
/// The API uses a fast heuristic (Christofides / farthest-insertion) so
/// results are near-optimal but not guaranteed optimal for large inputs.
///
/// ```dart
/// final optimizer = AnyRouteOptimizer();
/// final result = await optimizer.optimize(stops: [a, b, c, d]);
///
/// if (result.isSuccess) {
///   print('Best order: ${result.waypointOrder}');
///   print('Total: ${result.durationText} • ${result.distanceText}');
///   controller.addPolylines([result.toPolyline()]);
///   controller.fitBounds(result.bounds!);
/// }
/// ```
class AnyRouteOptimizer {
  /// OSRM base URL.
  final String baseUrl;

  /// Routing profile.
  final String profile;

  /// Whether the trip should start and end at the same point (round trip).
  final bool roundTrip;

  AnyRouteOptimizer({
    this.baseUrl = 'https://router.project-osrm.org',
    this.profile = 'driving',
    this.roundTrip = false,
  });

  /// Optimize the order of [stops] to minimize total travel time.
  ///
  /// [stops] must contain at least 2 locations. The first stop is always
  /// treated as the fixed starting point.
  Future<AnyOptimizedRoute> optimize({required List<AnyLatLng> stops}) async {
    if (stops.length < 2) {
      return AnyOptimizedRoute.failure('At least 2 stops are required');
    }

    try {
      final coordStr =
          stops.map((p) => '${p.longitude},${p.latitude}').join(';');

      final params = <String, String>{
        'overview': 'full',
        'geometries': 'polyline',
        'annotations': 'false',
        'steps': 'false',
        'source': 'first',
        if (!roundTrip) 'destination': 'last',
        'roundtrip': '$roundTrip',
      };

      final uri = Uri.parse('$baseUrl/trip/v1/$profile/$coordStr')
          .replace(queryParameters: params);

      final client = HttpClient();
      final request = await client.getUrl(uri);
      request.headers.set('User-Agent', 'any_map_flutter/1.0');
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      client.close();

      final json = jsonDecode(body) as Map<String, dynamic>;
      if (json['code'] != 'Ok') {
        return AnyOptimizedRoute.failure(
          json['message'] as String? ?? 'OSRM trip API error',
        );
      }

      // Build the optimized order: waypointOrder[tripPosition] = originalInputIndex
      // OSRM returns waypoints in original input order; each has a waypoint_index
      // telling you which position in the trip it occupies.
      final waypoints = json['waypoints'] as List? ?? [];
      // order[tripPosition] = originalInputIndex
      final order = List<int>.filled(waypoints.length, 0);
      for (var inputIdx = 0; inputIdx < waypoints.length; inputIdx++) {
        final w = waypoints[inputIdx] as Map<String, dynamic>;
        final tripPos = w['waypoint_index'] as int;
        order[tripPos] = inputIdx;
      }

      // Combine all trip legs into one geometry
      final trips = json['trips'] as List? ?? [];
      final allPoints = <AnyLatLng>[];
      double totalDist = 0;
      double totalDur = 0;

      for (final trip in trips) {
        final t = trip as Map<String, dynamic>;
        totalDist += (t['distance'] as num?)?.toDouble() ?? 0;
        totalDur += (t['duration'] as num?)?.toDouble() ?? 0;
        final encoded = t['geometry'] as String?;
        if (encoded != null) {
          allPoints.addAll(PolylineCodec.decode(encoded));
        }
      }

      final bounds =
          allPoints.isNotEmpty ? AnyLatLngBounds.fromPoints(allPoints) : null;

      return AnyOptimizedRoute(
        isSuccess: true,
        waypointOrder: order,
        geometry: allPoints,
        distanceMeters: totalDist,
        durationSeconds: totalDur,
        bounds: bounds,
      );
    } catch (e) {
      return AnyOptimizedRoute.failure(e.toString());
    }
  }
}
