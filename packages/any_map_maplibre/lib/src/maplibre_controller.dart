import 'dart:async';
import 'dart:math' show Point;
import 'dart:ui' as ui;

import 'package:any_map/any_map.dart';
import 'package:flutter/painting.dart' show EdgeInsets;
import 'package:maplibre_gl/maplibre_gl.dart' as ml;

/// AnyMapController implementation backed by MapLibre GL.
///
/// Exposes [nativeController] for advanced features like 3D building layers.
class MapLibreController implements AnyMapController {
  /// The underlying MapLibre map controller used for all map operations.
  final ml.MapLibreMapController controller;
  final Map<String, ml.Symbol> _symbolMap = {};
  final Map<String, ml.Line> _lineMap = {};
  final Map<String, ml.Fill> _fillMap = {};
  final Map<String, ml.Circle> _circleMap = {};

  final _cameraStreamController = StreamController<AnyCameraPosition>.broadcast();
  final _boundsStreamController = StreamController<AnyLatLngBounds>.broadcast();

  @override
  Stream<AnyCameraPosition> get cameraPositionStream => _cameraStreamController.stream;

  @override
  Stream<AnyLatLngBounds> get visibleBoundsStream => _boundsStreamController.stream;

  /// Called by the adapter's onCameraIdle to push camera updates into the streams.
  void notifyCameraChanged(AnyCameraPosition pos, AnyLatLngBounds bounds) {
    if (!_cameraStreamController.isClosed) _cameraStreamController.add(pos);
    if (!_boundsStreamController.isClosed) _boundsStreamController.add(bounds);
  }

  /// Access the underlying MapLibre controller for advanced operations
  /// like adding 3D extrusion layers, custom sources, etc.
  ml.MapLibreMapController get nativeController => controller;

  /// Creates a [MapLibreController] with the given native [controller] and optional initial overlays.
  MapLibreController({
    required this.controller,
    List<AnyMarker> markers = const [],
    List<AnyPolyline> polylines = const [],
    List<AnyPolygon> polygons = const [],
    List<AnyCircle> circles = const [],
  }) {
    _addInitialOverlays(markers, polylines, polygons, circles);
  }

  Future<void> _addInitialOverlays(
    List<AnyMarker> markers,
    List<AnyPolyline> polylines,
    List<AnyPolygon> polygons,
    List<AnyCircle> circles,
  ) async {
    try {
      if (markers.isNotEmpty) await addMarkers(markers);
      if (polylines.isNotEmpty) await addPolylines(polylines);
      if (polygons.isNotEmpty) await addPolygons(polygons);
      if (circles.isNotEmpty) await addCircles(circles);
    } catch (_) {
      // Style may have changed during initial overlay setup
    }
  }

  // ── Camera ──

  /// Animates the camera to the given [position] over [duration].
  @override
  Future<void> animateCamera(
    AnyCameraPosition position, {
    Duration duration = const Duration(milliseconds: 300),
  }) async {
    await controller.animateCamera(
      ml.CameraUpdate.newCameraPosition(
        ml.CameraPosition(
          target: _toMlLatLng(position.target),
          zoom: position.zoom,
          tilt: position.tilt,
          bearing: position.bearing,
        ),
      ),
    );
  }

  /// Moves the camera instantly to the given [position] without animation.
  @override
  Future<void> moveCamera(AnyCameraPosition position) async {
    await controller.moveCamera(
      ml.CameraUpdate.newCameraPosition(
        ml.CameraPosition(
          target: _toMlLatLng(position.target),
          zoom: position.zoom,
          tilt: position.tilt,
          bearing: position.bearing,
        ),
      ),
    );
  }

  /// Adjusts the camera to fit the given [bounds] with optional [padding].
  @override
  Future<void> fitBounds(
    AnyLatLngBounds bounds, {
    double padding = 48.0,
  }) async {
    await controller.animateCamera(
      ml.CameraUpdate.newLatLngBounds(
        ml.LatLngBounds(
          southwest: _toMlLatLng(bounds.southwest),
          northeast: _toMlLatLng(bounds.northeast),
        ),
        left: padding,
        right: padding,
        top: padding,
        bottom: padding,
      ),
    );
  }

  /// Returns the current camera position.
  @override
  Future<AnyCameraPosition> getCameraPosition() async {
    final pos = controller.cameraPosition;
    if (pos == null) {
      return const AnyCameraPosition(target: AnyLatLng(0, 0));
    }
    return AnyCameraPosition(
      target: _fromMlLatLng(pos.target),
      zoom: pos.zoom,
      tilt: pos.tilt,
      bearing: pos.bearing,
    );
  }

  /// Returns the currently visible geographic bounds.
  @override
  Future<AnyLatLngBounds> getVisibleBounds() async {
    final bounds = await controller.getVisibleRegion();
    return AnyLatLngBounds(
      southwest: _fromMlLatLng(bounds.southwest),
      northeast: _fromMlLatLng(bounds.northeast),
    );
  }

  // ── Markers (as Symbols) ──

  /// Adds the given [markers] to the map as MapLibre symbols.
  @override
  Future<void> addMarkers(List<AnyMarker> markers) async {
    for (final marker in markers) {
      final symbol = await controller.addSymbol(
        ml.SymbolOptions(
          geometry: _toMlLatLng(marker.position),
          iconImage: marker.iconAsset ?? 'marker-15',
          iconSize: 1.0,
          iconRotate: marker.rotation,
          iconOpacity: marker.opacity,
          draggable: marker.draggable,
          textField: marker.title,
          textOffset: const ui.Offset(0, 1.5),
        ),
      );
      _symbolMap[marker.id] = symbol;
    }
  }

  /// Removes markers identified by [markerIds] from the map.
  @override
  Future<void> removeMarkers(List<String> markerIds) async {
    for (final id in markerIds) {
      final symbol = _symbolMap.remove(id);
      if (symbol != null) await controller.removeSymbol(symbol);
    }
  }

  /// Updates existing markers matched by their IDs.
  @override
  Future<void> updateMarkers(List<AnyMarker> markers) async {
    for (final marker in markers) {
      final symbol = _symbolMap[marker.id];
      if (symbol != null) {
        await controller.updateSymbol(
          symbol,
          ml.SymbolOptions(
            geometry: _toMlLatLng(marker.position),
            iconRotate: marker.rotation,
            iconOpacity: marker.opacity,
            textField: marker.title,
          ),
        );
      }
    }
  }

  /// Removes all markers from the map.
  @override
  Future<void> clearMarkers() async {
    for (final symbol in _symbolMap.values) {
      await controller.removeSymbol(symbol);
    }
    _symbolMap.clear();
  }

  // ── Polylines (as Lines) ──

  /// Adds the given [polylines] to the map as MapLibre lines.
  @override
  Future<void> addPolylines(List<AnyPolyline> polylines) async {
    for (final polyline in polylines) {
      final line = await controller.addLine(
        ml.LineOptions(
          geometry: polyline.points.map(_toMlLatLng).toList(),
          lineColor: _colorToHex(polyline.color),
          lineWidth: polyline.width,
          lineOpacity: polyline.opacity,
        ),
      );
      _lineMap[polyline.id] = line;
    }
  }

  /// Removes polylines identified by [polylineIds] from the map.
  @override
  Future<void> removePolylines(List<String> polylineIds) async {
    for (final id in polylineIds) {
      final line = _lineMap.remove(id);
      if (line != null) await controller.removeLine(line);
    }
  }

  /// Removes all polylines from the map.
  @override
  Future<void> clearPolylines() async {
    for (final line in _lineMap.values) {
      await controller.removeLine(line);
    }
    _lineMap.clear();
  }

  // ── Polygons (as Fills) ──

  /// Adds the given [polygons] to the map as MapLibre fills.
  @override
  Future<void> addPolygons(List<AnyPolygon> polygons) async {
    for (final polygon in polygons) {
      // Use the fill color's alpha channel as opacity if polygon.opacity is default
      final fillAlpha = ((polygon.fillColor.toARGB32() >> 24) & 0xFF) / 255.0;
      final effectiveOpacity = polygon.opacity < 1.0 ? polygon.opacity : fillAlpha;
      final fill = await controller.addFill(
        ml.FillOptions(
          geometry: [polygon.points.map(_toMlLatLng).toList()],
          fillColor: _colorToHex(polygon.fillColor),
          fillOpacity: effectiveOpacity,
          fillOutlineColor: _colorToHex(polygon.strokeColor),
        ),
      );
      _fillMap[polygon.id] = fill;
    }
  }

  /// Removes polygons identified by [polygonIds] from the map.
  @override
  Future<void> removePolygons(List<String> polygonIds) async {
    for (final id in polygonIds) {
      final fill = _fillMap.remove(id);
      if (fill != null) await controller.removeFill(fill);
    }
  }

  /// Removes all polygons from the map.
  @override
  Future<void> clearPolygons() async {
    for (final fill in _fillMap.values) {
      await controller.removeFill(fill);
    }
    _fillMap.clear();
  }

  // ── Circles ──

  /// Adds the given [circles] to the map as MapLibre circles.
  @override
  Future<void> addCircles(List<AnyCircle> circles) async {
    for (final circle in circles) {
      final fillAlpha = ((circle.fillColor.toARGB32() >> 24) & 0xFF) / 255.0;
      final effectiveOpacity = circle.opacity < 1.0 ? circle.opacity : fillAlpha;
      final mlCircle = await controller.addCircle(
        ml.CircleOptions(
          geometry: _toMlLatLng(circle.center),
          circleRadius: circle.radius / 10,
          circleColor: _colorToHex(circle.fillColor),
          circleOpacity: effectiveOpacity,
          circleStrokeColor: _colorToHex(circle.strokeColor),
          circleStrokeWidth: circle.strokeWidth,
        ),
      );
      _circleMap[circle.id] = mlCircle;
    }
  }

  /// Removes circles identified by [circleIds] from the map.
  @override
  Future<void> removeCircles(List<String> circleIds) async {
    for (final id in circleIds) {
      final circle = _circleMap.remove(id);
      if (circle != null) await controller.removeCircle(circle);
    }
  }

  /// Removes all circles from the map.
  @override
  Future<void> clearCircles() async {
    for (final circle in _circleMap.values) {
      await controller.removeCircle(circle);
    }
    _circleMap.clear();
  }

  // ── Conversion ──

  /// Converts a screen [screenPoint] to a geographic coordinate.
  @override
  Future<AnyLatLng?> screenToLatLng(ui.Offset screenPoint) async {
    final latLng = await controller.toLatLng(
      Point<double>(screenPoint.dx, screenPoint.dy),
    );
    return _fromMlLatLng(latLng);
  }

  /// Converts a geographic [position] to a screen offset.
  @override
  Future<ui.Offset?> latLngToScreen(AnyLatLng position) async {
    final point = await controller.toScreenLocation(_toMlLatLng(position));
    return ui.Offset(point.x.toDouble(), point.y.toDouble());
  }

  // ── Polyline Animation ──

  /// Progressively draws [polyline] point-by-point over [duration].
  @override
  Future<void> animatePolyline(
    AnyPolyline polyline, {
    Duration duration = const Duration(seconds: 1),
  }) async {
    final pts = polyline.points;
    if (pts.length < 2) return;
    final stepMs = duration.inMilliseconds ~/ (pts.length - 1);
    for (var i = 2; i <= pts.length; i++) {
      final partial = AnyPolyline(
        id: polyline.id,
        points: pts.sublist(0, i),
        color: polyline.color,
        width: polyline.width,
      );
      await removePolylines([polyline.id]);
      await addPolylines([partial]);
      await Future<void>.delayed(Duration(milliseconds: stepMs));
    }
  }

  // ── Snapshot ──

  /// Captures the map as a [ui.Image]. Returns null if unavailable.
  @override
  Future<ui.Image?> takeSnapshot() async {
    // MapLibre GL does not expose a snapshot API in this Dart wrapper.
    return null;
  }

  // ── fitBoundsWithInsets ──

  /// Fits the camera to [bounds] with per-side [insets].
  @override
  Future<void> fitBoundsWithInsets(
    AnyLatLngBounds bounds, {
    EdgeInsets insets = const EdgeInsets.all(48),
  }) async {
    await controller.animateCamera(
      ml.CameraUpdate.newLatLngBounds(
        ml.LatLngBounds(
          southwest: _toMlLatLng(bounds.southwest),
          northeast: _toMlLatLng(bounds.northeast),
        ),
        left: insets.left,
        right: insets.right,
        top: insets.top,
        bottom: insets.bottom,
      ),
    );
  }

  // ── Style ──

  /// Changes the map style at runtime using the given [style].
  @override
  Future<void> setStyle(AnyMapStyle style) async {
    final styleString = style.styleUrl ?? style.jsonStyle;
    if (styleString != null) {
      await controller.setStyle(styleString);
    }
  }

  // ── 3D Buildings ──

  /// Enable 3D building extrusions. Requires a vector tile source with a
  /// `building` layer (e.g. OpenMapTiles / OpenFreeMap styles).
  ///
  /// [color] defaults to a soft blue. [opacity] defaults to 0.6.
  Future<void> enable3DBuildings({
    String color = '#aab7ef',
    double opacity = 0.6,
    double minZoom = 15,
  }) async {
    try {
      await controller.addLayer(
        'openmaptiles',
        '3d-buildings',
        ml.FillExtrusionLayerProperties(
          fillExtrusionColor: color,
          fillExtrusionHeight: [
            'interpolate',
            ['linear'],
            ['zoom'],
            15, 0,
            16, ['get', 'render_height'],
          ],
          fillExtrusionBase: ['get', 'render_min_height'],
          fillExtrusionOpacity: opacity,
        ),
        sourceLayer: 'building',
        minzoom: minZoom,
        filter: ['==', r'$type', 'Polygon'],
      );
    } catch (_) {
      // Layer may already exist or source not available in this style
    }
  }

  // ── Lifecycle ──

  /// Disposes of native resources; the MapLibre controller is disposed by the widget.
  @override
  void dispose() {
    _cameraStreamController.close();
    _boundsStreamController.close();
  }

  // ── Helpers ──

  ml.LatLng _toMlLatLng(AnyLatLng latLng) =>
      ml.LatLng(latLng.latitude, latLng.longitude);

  AnyLatLng _fromMlLatLng(ml.LatLng latLng) =>
      AnyLatLng(latLng.latitude, latLng.longitude);

  String _colorToHex(ui.Color color) {
    return '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
  }
}
