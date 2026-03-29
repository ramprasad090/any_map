import 'dart:convert';
import 'dart:io';

import '../models/lat_lng.dart';
import '../models/polyline.dart';
import 'package:flutter/painting.dart' show Color;

/// A single GPS trace point with optional timestamp and accuracy.
class AnyGpsPoint {
  /// Geographic coordinate.
  final AnyLatLng position;

  /// UNIX timestamp in seconds. Used by OSRM to improve matching quality.
  final int? timestamp;

  /// GPS accuracy radius in metres. Used as OSRM radius hint.
  final double? accuracy;

  const AnyGpsPoint({
    required this.position,
    this.timestamp,
    this.accuracy,
  });
}

/// The result of a GPS→road snapping operation.
class AnyMapMatchResult {
  /// Whether the request succeeded.
  final bool isSuccess;

  /// Error message if [isSuccess] is false.
  final String? error;

  /// The road-snapped trace as an ordered list of coordinates.
  final List<AnyLatLng> snappedPoints;

  /// Confidence score (0.0–1.0). Higher is better. Null if not provided.
  final double? confidence;

  /// Overall distance of the matched route in metres.
  final double? distanceMeters;

  /// Overall duration of the matched route in seconds.
  final double? durationSeconds;

  const AnyMapMatchResult({
    required this.isSuccess,
    this.error,
    this.snappedPoints = const [],
    this.confidence,
    this.distanceMeters,
    this.durationSeconds,
  });

  factory AnyMapMatchResult.failure(String error) =>
      AnyMapMatchResult(isSuccess: false, error: error);

  /// Convert the snapped trace to an [AnyPolyline] for display.
  AnyPolyline toPolyline({
    String id = 'matched_trace',
    Color color = const Color(0xFF4CAF50),
    double width = 4.0,
  }) =>
      AnyPolyline(id: id, points: snappedPoints, color: color, width: width);
}

/// Snaps a noisy GPS trace to the underlying road network using the
/// OSRM Map Matching API.
///
/// Useful for:
/// - Post-trip route replay in delivery/logistics apps
/// - Correcting raw GPS logs before display
/// - Measuring accurate driven distance
///
/// ```dart
/// final matcher = AnyMapMatcher();
/// final result = await matcher.match([
///   AnyGpsPoint(position: AnyLatLng(17.361, 78.474), timestamp: 1700000000),
///   AnyGpsPoint(position: AnyLatLng(17.363, 78.476), timestamp: 1700000010),
///   AnyGpsPoint(position: AnyLatLng(17.365, 78.478), timestamp: 1700000020),
/// ]);
///
/// if (result.isSuccess) {
///   controller.addPolylines([result.toPolyline()]);
/// }
/// ```
class AnyMapMatcher {
  /// OSRM base URL.
  final String baseUrl;

  /// Routing profile.
  final String profile;

  /// Default GPS accuracy radius hint in metres (used when [AnyGpsPoint.accuracy] is null).
  final double defaultRadius;

  AnyMapMatcher({
    this.baseUrl = 'https://router.project-osrm.org',
    this.profile = 'driving',
    this.defaultRadius = 25.0,
  });

  /// Match [points] to the road network and return a snapped trace.
  ///
  /// At least 2 points are required.
  Future<AnyMapMatchResult> match(List<AnyGpsPoint> points) async {
    if (points.length < 2) {
      return AnyMapMatchResult.failure('At least 2 GPS points are required');
    }

    try {
      final coordStr =
          points.map((p) => '${p.position.longitude},${p.position.latitude}').join(';');

      final params = <String, String>{
        'geometries': 'geojson',
        'annotations': 'false',
        'overview': 'full',
        'gaps': 'ignore',
        'radiuses': points.map((p) => (p.accuracy ?? defaultRadius).toStringAsFixed(0)).join(';'),
      };

      // Only include timestamps if ALL points have them (OSRM requires monotonically
      // increasing values with no gaps; mixing nulls with 0 causes rejection)
      if (points.every((p) => p.timestamp != null)) {
        params['timestamps'] =
            points.map((p) => '${p.timestamp}').join(';');
      }

      final uri = Uri.parse('$baseUrl/match/v1/$profile/$coordStr')
          .replace(queryParameters: params);

      final client = HttpClient();
      final request = await client.getUrl(uri);
      request.headers.set('User-Agent', 'any_map_flutter/1.0');
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      client.close();

      final json = jsonDecode(body) as Map<String, dynamic>;

      if (json['code'] != 'Ok') {
        return AnyMapMatchResult.failure(
          json['message'] as String? ?? 'OSRM match API error',
        );
      }

      final matchings = json['matchings'] as List?;
      if (matchings == null || matchings.isEmpty) {
        return AnyMapMatchResult.failure('No matchings returned');
      }

      // Combine all matched sub-traces into one polyline
      final allPoints = <AnyLatLng>[];
      double totalDist = 0;
      double totalDur = 0;
      double totalConf = 0;
      var confCount = 0;

      for (final m in matchings) {
        final matching = m as Map<String, dynamic>;
        totalDist += (matching['distance'] as num?)?.toDouble() ?? 0;
        totalDur += (matching['duration'] as num?)?.toDouble() ?? 0;
        final conf = (matching['confidence'] as num?)?.toDouble();
        if (conf != null) { totalConf += conf; confCount++; }

        final geom = matching['geometry'] as Map<String, dynamic>?;
        final coords = geom?['coordinates'] as List?;
        if (coords != null) {
          for (final c in coords) {
            final pair = c as List;
            allPoints.add(AnyLatLng(
              (pair[1] as num).toDouble(),
              (pair[0] as num).toDouble(),
            ));
          }
        }
      }

      return AnyMapMatchResult(
        isSuccess: true,
        snappedPoints: allPoints,
        distanceMeters: totalDist > 0 ? totalDist : null,
        durationSeconds: totalDur > 0 ? totalDur : null,
        confidence: confCount > 0 ? totalConf / confCount : null,
      );
    } catch (e) {
      return AnyMapMatchResult.failure(e.toString());
    }
  }
}
