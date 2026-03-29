import 'dart:convert';
import 'dart:ui' show Color;

import 'package:flutter/services.dart' show rootBundle;

import '../models/lat_lng.dart';
import '../models/polyline.dart';
import '../models/polygon.dart';
import '../models/marker.dart';

/// A parsed GeoJSON feature.
class AnyGeoJsonFeature {
  /// Feature ID.
  final String? id;

  /// Geometry type ("Point", "LineString", "Polygon", "MultiPoint", etc.).
  final String geometryType;

  /// Coordinates (parsed from GeoJSON).
  final dynamic coordinates;

  /// Feature properties.
  final Map<String, dynamic> properties;

  const AnyGeoJsonFeature({
    this.id,
    required this.geometryType,
    required this.coordinates,
    this.properties = const {},
  });
}

/// A GeoJSON layer that can be rendered on any map backend.
class AnyGeoJsonLayer {
  /// Unique layer ID.
  final String id;

  /// Raw GeoJSON string or parsed map.
  final String geoJson;

  /// Default styling for points.
  final Color pointColor;

  /// Default styling for lines.
  final Color lineColor;
  /// Default line width for line geometries.
  final double lineWidth;

  /// Default styling for polygons.
  final Color fillColor;

  /// Default stroke color for polygon outlines.
  final Color strokeColor;

  /// Default stroke width for polygon outlines.
  final double strokeWidth;

  const AnyGeoJsonLayer({
    required this.id,
    required this.geoJson,
    this.pointColor = const Color(0xFFFF5722),
    this.lineColor = const Color(0xFF4285F4),
    this.lineWidth = 3.0,
    this.fillColor = const Color(0x334285F4),
    this.strokeColor = const Color(0xFF4285F4),
    this.strokeWidth = 2.0,
  });

  /// Create a layer from a raw GeoJSON string.
  ///
  /// ```dart
  /// final layer = AnyGeoJsonLayer.fromString(
  ///   id: 'my_layer',
  ///   geoJson: '{"type":"FeatureCollection","features":[...]}',
  /// );
  /// ```
  factory AnyGeoJsonLayer.fromString({
    required String id,
    required String geoJson,
    Color pointColor = const Color(0xFFFF5722),
    Color lineColor = const Color(0xFF4285F4),
    double lineWidth = 3.0,
    Color fillColor = const Color(0x334285F4),
    Color strokeColor = const Color(0xFF4285F4),
    double strokeWidth = 2.0,
  }) =>
      AnyGeoJsonLayer(
        id: id,
        geoJson: geoJson,
        pointColor: pointColor,
        lineColor: lineColor,
        lineWidth: lineWidth,
        fillColor: fillColor,
        strokeColor: strokeColor,
        strokeWidth: strokeWidth,
      );

  /// Create a layer by loading GeoJSON from a Flutter asset.
  ///
  /// The asset must be declared in `pubspec.yaml` under `flutter: assets:`.
  ///
  /// ```dart
  /// final layer = await AnyGeoJsonLayer.fromAsset(
  ///   id: 'borders',
  ///   assetPath: 'assets/geojson/borders.geojson',
  /// );
  /// ```
  static Future<AnyGeoJsonLayer> fromAsset({
    required String id,
    required String assetPath,
    Color pointColor = const Color(0xFFFF5722),
    Color lineColor = const Color(0xFF4285F4),
    double lineWidth = 3.0,
    Color fillColor = const Color(0x334285F4),
    Color strokeColor = const Color(0xFF4285F4),
    double strokeWidth = 2.0,
  }) async {
    final geoJson = await rootBundle.loadString(assetPath);
    return AnyGeoJsonLayer(
      id: id,
      geoJson: geoJson,
      pointColor: pointColor,
      lineColor: lineColor,
      lineWidth: lineWidth,
      fillColor: fillColor,
      strokeColor: strokeColor,
      strokeWidth: strokeWidth,
    );
  }

  /// Parse the GeoJSON and return typed features.
  List<AnyGeoJsonFeature> parseFeatures() {
    final data = jsonDecode(geoJson) as Map<String, dynamic>;
    final features = <AnyGeoJsonFeature>[];

    if (data['type'] == 'FeatureCollection') {
      for (final f in data['features'] as List) {
        final feature = f as Map<String, dynamic>;
        final geometry = feature['geometry'] as Map<String, dynamic>;
        features.add(AnyGeoJsonFeature(
          id: feature['id']?.toString(),
          geometryType: geometry['type'] as String,
          coordinates: geometry['coordinates'],
          properties: (feature['properties'] as Map<String, dynamic>?) ?? {},
        ));
      }
    } else if (data['type'] == 'Feature') {
      final geometry = data['geometry'] as Map<String, dynamic>;
      features.add(AnyGeoJsonFeature(
        id: data['id']?.toString(),
        geometryType: geometry['type'] as String,
        coordinates: geometry['coordinates'],
        properties: (data['properties'] as Map<String, dynamic>?) ?? {},
      ));
    }

    return features;
  }

  /// Convert GeoJSON features to markers (for Point geometries).
  List<AnyMarker> toMarkers() {
    final features = parseFeatures();
    final markers = <AnyMarker>[];
    int idx = 0;

    for (final f in features) {
      if (f.geometryType == 'Point') {
        final coords = f.coordinates as List;
        markers.add(AnyMarker(
          id: f.id ?? '${id}_point_$idx',
          position: AnyLatLng(
            (coords[1] as num).toDouble(),
            (coords[0] as num).toDouble(),
          ),
          title: f.properties['name'] as String?,
        ));
        idx++;
      }
    }
    return markers;
  }

  /// Convert GeoJSON features to polylines (for LineString geometries).
  List<AnyPolyline> toPolylines() {
    final features = parseFeatures();
    final lines = <AnyPolyline>[];
    int idx = 0;

    for (final f in features) {
      if (f.geometryType == 'LineString') {
        final coords = f.coordinates as List;
        lines.add(AnyPolyline(
          id: f.id ?? '${id}_line_$idx',
          points: coords
              .map((c) => AnyLatLng(
                    (c[1] as num).toDouble(),
                    (c[0] as num).toDouble(),
                  ))
              .toList(),
          color: lineColor,
          width: lineWidth,
        ));
        idx++;
      }
    }
    return lines;
  }

  /// Convert GeoJSON features to polygons (for Polygon geometries).
  List<AnyPolygon> toPolygons() {
    final features = parseFeatures();
    final polys = <AnyPolygon>[];
    int idx = 0;

    for (final f in features) {
      if (f.geometryType == 'Polygon') {
        final rings = f.coordinates as List;
        if (rings.isNotEmpty) {
          final outerRing = rings[0] as List;
          polys.add(AnyPolygon(
            id: f.id ?? '${id}_poly_$idx',
            points: outerRing
                .map((c) => AnyLatLng(
                      (c[1] as num).toDouble(),
                      (c[0] as num).toDouble(),
                    ))
                .toList(),
            holes: rings.length > 1
                ? rings.skip(1).map((ring) {
                    return (ring as List)
                        .map((c) => AnyLatLng(
                              (c[1] as num).toDouble(),
                              (c[0] as num).toDouble(),
                            ))
                        .toList();
                  }).toList()
                : null,
            fillColor: fillColor,
            strokeColor: strokeColor,
            strokeWidth: strokeWidth,
          ));
          idx++;
        }
      }
    }
    return polys;
  }
}
