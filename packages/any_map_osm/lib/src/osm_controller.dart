import 'dart:ui' as ui;

import 'package:flutter/widgets.dart' show EdgeInsets;
import 'package:any_map/any_map.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart' as ll;

/// AnyMapController implementation backed by flutter_map (OSM).
class OsmController implements AnyMapController {
  final fm.MapController controller;

  OsmController({required this.controller});

  @override
  Future<void> animateCamera(
    AnyCameraPosition position, {
    Duration duration = const Duration(milliseconds: 300),
  }) async {
    controller.move(
      ll.LatLng(position.target.latitude, position.target.longitude),
      position.zoom,
    );
  }

  @override
  Future<void> moveCamera(AnyCameraPosition position) async {
    controller.move(
      ll.LatLng(position.target.latitude, position.target.longitude),
      position.zoom,
    );
  }

  @override
  Future<void> fitBounds(
    AnyLatLngBounds bounds, {
    double padding = 48.0,
  }) async {
    controller.fitCamera(
      fm.CameraFit.bounds(
        bounds: fm.LatLngBounds(
          ll.LatLng(bounds.southwest.latitude, bounds.southwest.longitude),
          ll.LatLng(bounds.northeast.latitude, bounds.northeast.longitude),
        ),
        padding: EdgeInsets.all(padding),
      ),
    );
  }

  @override
  Future<AnyCameraPosition> getCameraPosition() async {
    final cam = controller.camera;
    return AnyCameraPosition(
      target: AnyLatLng(cam.center.latitude, cam.center.longitude),
      zoom: cam.zoom,
      bearing: cam.rotation,
    );
  }

  @override
  Future<AnyLatLngBounds> getVisibleBounds() async {
    final bounds = controller.camera.visibleBounds;
    return AnyLatLngBounds(
      southwest: AnyLatLng(bounds.southWest.latitude, bounds.southWest.longitude),
      northeast: AnyLatLng(bounds.northEast.latitude, bounds.northEast.longitude),
    );
  }

  // ── Overlays are handled declaratively by the widget. ──
  // These methods are stubs for the imperative API.

  @override
  Future<void> addMarkers(List<AnyMarker> markers) async {}

  @override
  Future<void> removeMarkers(List<String> markerIds) async {}

  @override
  Future<void> updateMarkers(List<AnyMarker> markers) async {}

  @override
  Future<void> clearMarkers() async {}

  @override
  Future<void> addPolylines(List<AnyPolyline> polylines) async {}

  @override
  Future<void> removePolylines(List<String> polylineIds) async {}

  @override
  Future<void> clearPolylines() async {}

  @override
  Future<void> addPolygons(List<AnyPolygon> polygons) async {}

  @override
  Future<void> removePolygons(List<String> polygonIds) async {}

  @override
  Future<void> clearPolygons() async {}

  @override
  Future<void> addCircles(List<AnyCircle> circles) async {}

  @override
  Future<void> removeCircles(List<String> circleIds) async {}

  @override
  Future<void> clearCircles() async {}

  @override
  Future<AnyLatLng?> screenToLatLng(ui.Offset screenPoint) async {
    // flutter_map doesn't expose direct screen-to-latlng in controller.
    return null;
  }

  @override
  Future<ui.Offset?> latLngToScreen(AnyLatLng position) async {
    // flutter_map doesn't expose direct latlng-to-screen in controller.
    return null;
  }

  @override
  Future<void> setStyle(AnyMapStyle style) async {
    // OSM tiles don't support style changes — swap tile URL instead.
  }

  @override
  void dispose() {
    controller.dispose();
  }
}
