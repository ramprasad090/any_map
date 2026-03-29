import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart' show EdgeInsets;
import 'package:any_map/any_map.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;

/// AnyMapController implementation backed by Google Maps.
class GoogleMapController implements AnyMapController {
  final gm.GoogleMapController controller;
  final AnyMapStyle? _initialStyle;

  final _cameraStreamController = StreamController<AnyCameraPosition>.broadcast();
  final _boundsStreamController = StreamController<AnyLatLngBounds>.broadcast();

  @override
  Stream<AnyCameraPosition> get cameraPositionStream => _cameraStreamController.stream;

  @override
  Stream<AnyLatLngBounds> get visibleBoundsStream => _boundsStreamController.stream;

  /// Push a camera update into the reactive streams (call from onCameraMove).
  void notifyCameraChanged(AnyCameraPosition pos) {
    if (!_cameraStreamController.isClosed) _cameraStreamController.add(pos);
  }

  GoogleMapController({
    required this.controller,
    AnyMapStyle? style,
  }) : _initialStyle = style {
    if (_initialStyle?.jsonStyle != null) {
      controller.setMapStyle(_initialStyle!.jsonStyle);
    }
  }

  @override
  Future<void> animateCamera(
    AnyCameraPosition position, {
    Duration duration = const Duration(milliseconds: 300),
  }) async {
    await controller.animateCamera(
      gm.CameraUpdate.newCameraPosition(
        gm.CameraPosition(
          target: gm.LatLng(position.target.latitude, position.target.longitude),
          zoom: position.zoom,
          tilt: position.tilt,
          bearing: position.bearing,
        ),
      ),
    );
  }

  @override
  Future<void> moveCamera(AnyCameraPosition position) async {
    await controller.moveCamera(
      gm.CameraUpdate.newCameraPosition(
        gm.CameraPosition(
          target: gm.LatLng(position.target.latitude, position.target.longitude),
          zoom: position.zoom,
          tilt: position.tilt,
          bearing: position.bearing,
        ),
      ),
    );
  }

  @override
  Future<void> fitBounds(
    AnyLatLngBounds bounds, {
    double padding = 48.0,
  }) async {
    await controller.animateCamera(
      gm.CameraUpdate.newLatLngBounds(
        gm.LatLngBounds(
          southwest: gm.LatLng(bounds.southwest.latitude, bounds.southwest.longitude),
          northeast: gm.LatLng(bounds.northeast.latitude, bounds.northeast.longitude),
        ),
        padding,
      ),
    );
  }

  @override
  Future<AnyCameraPosition> getCameraPosition() async {
    // Google Maps doesn't expose this directly; return a default.
    // In practice, track via onCameraMove callback.
    return const AnyCameraPosition(target: AnyLatLng(0, 0));
  }

  @override
  Future<AnyLatLngBounds> getVisibleBounds() async {
    final bounds = await controller.getVisibleRegion();
    return AnyLatLngBounds(
      southwest: AnyLatLng(bounds.southwest.latitude, bounds.southwest.longitude),
      northeast: AnyLatLng(bounds.northeast.latitude, bounds.northeast.longitude),
    );
  }

  // ── Markers ── (handled declaratively via GoogleMap widget, stubs here)

  @override
  Future<void> addMarkers(List<AnyMarker> markers) async {}

  @override
  Future<void> removeMarkers(List<String> markerIds) async {}

  @override
  Future<void> updateMarkers(List<AnyMarker> markers) async {}

  @override
  Future<void> clearMarkers() async {}

  // ── Polylines ──

  @override
  Future<void> addPolylines(List<AnyPolyline> polylines) async {}

  @override
  Future<void> removePolylines(List<String> polylineIds) async {}

  @override
  Future<void> clearPolylines() async {}

  // ── Polygons ──

  @override
  Future<void> addPolygons(List<AnyPolygon> polygons) async {}

  @override
  Future<void> removePolygons(List<String> polygonIds) async {}

  @override
  Future<void> clearPolygons() async {}

  // ── Circles ──

  @override
  Future<void> addCircles(List<AnyCircle> circles) async {}

  @override
  Future<void> removeCircles(List<String> circleIds) async {}

  @override
  Future<void> clearCircles() async {}

  // ── Conversion ──

  @override
  Future<AnyLatLng?> screenToLatLng(ui.Offset screenPoint) async {
    final latLng = await controller.getLatLng(
      gm.ScreenCoordinate(
        x: screenPoint.dx.round(),
        y: screenPoint.dy.round(),
      ),
    );
    return AnyLatLng(latLng.latitude, latLng.longitude);
  }

  @override
  Future<ui.Offset?> latLngToScreen(AnyLatLng position) async {
    final coord = await controller.getScreenCoordinate(
      gm.LatLng(position.latitude, position.longitude),
    );
    return ui.Offset(coord.x.toDouble(), coord.y.toDouble());
  }

  // ── fitBoundsWithInsets ──

  @override
  Future<void> fitBoundsWithInsets(
    AnyLatLngBounds bounds, {
    EdgeInsets insets = const EdgeInsets.all(48),
  }) async {
    // Google Maps only supports a single uniform padding value.
    final padding = (insets.left + insets.right + insets.top + insets.bottom) / 4;
    await controller.animateCamera(
      gm.CameraUpdate.newLatLngBounds(
        gm.LatLngBounds(
          southwest: gm.LatLng(bounds.southwest.latitude, bounds.southwest.longitude),
          northeast: gm.LatLng(bounds.northeast.latitude, bounds.northeast.longitude),
        ),
        padding,
      ),
    );
  }

  // ── Polyline Animation ──

  @override
  Future<void> animatePolyline(
    AnyPolyline polyline, {
    Duration duration = const Duration(seconds: 1),
  }) async {
    // Google overlays are declarative; animation is handled at the widget level.
  }

  // ── Snapshot ──

  @override
  Future<ui.Image?> takeSnapshot() async {
    // google_maps_flutter does not expose a snapshot API in this version.
    return null;
  }

  // ── Style ──

  @override
  Future<void> setStyle(AnyMapStyle style) async {
    if (style.jsonStyle != null) {
      await controller.setMapStyle(style.jsonStyle);
    }
  }

  @override
  void dispose() {
    _cameraStreamController.close();
    _boundsStreamController.close();
    controller.dispose();
  }
}
