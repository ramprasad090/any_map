import 'dart:convert';
import 'dart:io';

import '../models/lat_lng.dart';

/// A single cell in a distance matrix result.
class AnyMatrixCell {
  /// Duration in seconds from origin to destination.
  final double? durationSeconds;

  /// Distance in metres from origin to destination.
  final double? distanceMeters;

  const AnyMatrixCell({this.durationSeconds, this.distanceMeters});

  /// Duration formatted as a human-readable string (e.g. "12 min").
  String? get durationText {
    if (durationSeconds == null) return null;
    final m = (durationSeconds! / 60).round();
    if (m < 60) return '$m min';
    return '${m ~/ 60}h ${m % 60}m';
  }

  /// Distance formatted as a human-readable string (e.g. "3.2 km").
  String? get distanceText {
    if (distanceMeters == null) return null;
    if (distanceMeters! < 1000) return '${distanceMeters!.round()} m';
    return '${(distanceMeters! / 1000).toStringAsFixed(1)} km';
  }
}

/// The result of a distance matrix calculation.
class AnyDistanceMatrixResult {
  /// Whether the request succeeded.
  final bool isSuccess;

  /// Error message if [isSuccess] is false.
  final String? error;

  /// The matrix of cells, indexed as `[originIndex][destinationIndex]`.
  final List<List<AnyMatrixCell>> matrix;

  /// The origin coordinates in the order returned by the API.
  final List<AnyLatLng> origins;

  /// The destination coordinates in the order returned by the API.
  final List<AnyLatLng> destinations;

  const AnyDistanceMatrixResult({
    required this.isSuccess,
    this.error,
    this.matrix = const [],
    this.origins = const [],
    this.destinations = const [],
  });

  factory AnyDistanceMatrixResult.failure(String error) =>
      AnyDistanceMatrixResult(isSuccess: false, error: error);
}

/// Computes travel times and distances for multiple origin→destination pairs
/// in a single API call using the OSRM Table service.
///
/// ```dart
/// final result = await AnyDistanceMatrix.calculate(
///   origins: [charminAr, hitecCity],
///   destinations: [hussainSagar, golconda],
/// );
///
/// final cell = result.matrix[0][1]; // Charminar → Golconda
/// print(cell.durationText); // "22 min"
/// print(cell.distanceText); // "9.4 km"
/// ```
class AnyDistanceMatrix {
  /// OSRM base URL (defaults to the public demo server).
  final String baseUrl;

  /// Profile: "driving" | "walking" | "cycling"
  final String profile;

  /// Whether to include distances (in addition to durations).
  final bool includeDistances;

  AnyDistanceMatrix({
    this.baseUrl = 'https://router.project-osrm.org',
    this.profile = 'driving',
    this.includeDistances = true,
  });

  /// Calculate the matrix for [origins] × [destinations].
  ///
  /// If [destinations] is omitted, a square matrix of all [origins] × [origins]
  /// is computed.
  Future<AnyDistanceMatrixResult> calculate({
    required List<AnyLatLng> origins,
    List<AnyLatLng>? destinations,
  }) async {
    final dests = destinations ?? origins;
    if (origins.isEmpty || dests.isEmpty) {
      return AnyDistanceMatrixResult.failure('Origins and destinations must not be empty');
    }

    try {
      final isSquare = destinations == null;

      String coordStr;
      String? sourceParam;
      String? destParam;

      if (isSquare) {
        // Square matrix: pass all coords once, omit sources/destinations
        // OSRM returns a full N×N matrix by default
        coordStr = origins.map((p) => '${p.longitude},${p.latitude}').join(';');
      } else {
        // Rectangular: origins first, then destinations; use index ranges
        final allCoords = [...origins, ...dests];
        coordStr = allCoords.map((p) => '${p.longitude},${p.latitude}').join(';');
        sourceParam = List.generate(origins.length, (i) => i).join(';');
        destParam = List.generate(dests.length, (i) => origins.length + i).join(';');
      }

      final annotations = includeDistances ? 'duration,distance' : 'duration';

      final queryParams = <String, String>{'annotations': annotations};
      if (sourceParam != null) queryParams['sources'] = sourceParam;
      if (destParam != null) queryParams['destinations'] = destParam;

      final uri = Uri.parse('$baseUrl/table/v1/$profile/$coordStr')
          .replace(queryParameters: queryParams);

      final client = HttpClient();
      final request = await client.getUrl(uri);
      request.headers.set('User-Agent', 'any_map_flutter/1.0');
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      client.close();

      final json = jsonDecode(body) as Map<String, dynamic>;

      if (json['code'] != 'Ok') {
        return AnyDistanceMatrixResult.failure(
          json['message'] as String? ?? 'OSRM table API error',
        );
      }

      final durationsRaw = json['durations'] as List?;
      final distancesRaw = json['distances'] as List?;

      final matrix = <List<AnyMatrixCell>>[];
      for (var i = 0; i < origins.length; i++) {
        final row = <AnyMatrixCell>[];
        final durRow = durationsRaw != null ? durationsRaw[i] as List : null;
        final distRow = distancesRaw != null ? distancesRaw[i] as List : null;
        for (var j = 0; j < dests.length; j++) {
          row.add(AnyMatrixCell(
            durationSeconds: durRow != null ? (durRow[j] as num?)?.toDouble() : null,
            distanceMeters: distRow != null ? (distRow[j] as num?)?.toDouble() : null,
          ));
        }
        matrix.add(row);
      }

      // Parse snapped origin/destination waypoints
      final srcWaypoints = (json['sources'] as List?)
              ?.map((w) {
                final loc = (w as Map)['location'] as List;
                return AnyLatLng((loc[1] as num).toDouble(), (loc[0] as num).toDouble());
              })
              .toList() ??
          origins;
      final dstWaypoints = (json['destinations'] as List?)
              ?.map((w) {
                final loc = (w as Map)['location'] as List;
                return AnyLatLng((loc[1] as num).toDouble(), (loc[0] as num).toDouble());
              })
              .toList() ??
          dests;

      return AnyDistanceMatrixResult(
        isSuccess: true,
        matrix: matrix,
        origins: srcWaypoints,
        destinations: dstWaypoints,
      );
    } catch (e) {
      return AnyDistanceMatrixResult.failure(e.toString());
    }
  }
}
