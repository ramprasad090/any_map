import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../controllers/map_controller.dart';
import '../models/models.dart';
import '../widgets/any_map_widget.dart';

/// A no-op map adapter for widget tests.
///
/// Renders a plain [ColoredBox] (no native map) and provides a fully
/// functional [AnyMapFakeController] that records method calls for assertions.
///
/// ```dart
/// testWidgets('shows popup after tap', (tester) async {
///   final adapter = AnyMapFakeAdapter();
///
///   await tester.pumpWidget(MaterialApp(
///     home: AnyMapWidget(
///       adapter: adapter,
///       initialCamera: AnyCameraPosition(target: AnyLatLng(0, 0), zoom: 10),
///       onMapCreated: (c) => controller = c as AnyMapFakeController,
///     ),
///   ));
///
///   expect(controller.addedMarkers, isEmpty);
/// });
/// ```
class AnyMapFakeAdapter extends AnyMapAdapter {
  /// The controller created when [buildMapWidget] is called.
  AnyMapFakeController? controller;

  /// Background color of the placeholder widget.
  final Color color;

  AnyMapFakeAdapter({this.color = const Color(0xFFE8EAF6)});

  @override
  Widget buildMapWidget(AnyMapWidget config) {
    final ctrl = AnyMapFakeController(config: config);
    controller = ctrl;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      config.onMapCreated?.call(ctrl);
    });
    return ColoredBox(
      color: color,
      child: const Center(child: Text('FakeMap', style: TextStyle(color: Color(0xFF9E9E9E)))),
    );
  }
}

/// Fake [AnyMapController] that records calls for use in tests.
class AnyMapFakeController implements AnyMapController {
  final AnyMapWidget config;

  AnyMapFakeController({required this.config});

  // ── Call recording ──

  /// All [addMarkers] calls, in order.
  final List<List<AnyMarker>> addedMarkers = [];

  /// All [removeMarkers] calls (list of ID lists).
  final List<List<String>> removedMarkerIds = [];

  /// All [addPolylines] calls, in order.
  final List<List<AnyPolyline>> addedPolylines = [];

  /// All [removePolylines] calls (list of ID lists).
  final List<List<String>> removedPolylineIds = [];

  /// All [addPolygons] calls, in order.
  final List<List<AnyPolygon>> addedPolygons = [];

  /// All [addCircles] calls, in order.
  final List<List<AnyCircle>> addedCircles = [];

  /// All [animateCamera] calls, in order.
  final List<AnyCameraPosition> animateCameraCalls = [];

  /// All [moveCamera] calls, in order.
  final List<AnyCameraPosition> moveCameraCalls = [];

  /// All [fitBounds] calls, in order.
  final List<AnyLatLngBounds> fitBoundsCalls = [];

  /// Number of times [clearMarkers] was called.
  int clearMarkersCount = 0;

  /// Number of times [clearPolylines] was called.
  int clearPolylinesCount = 0;

  AnyCameraPosition _camera = const AnyCameraPosition(
    target: AnyLatLng(0, 0),
    zoom: 1,
  );

  final _cameraController = StreamController<AnyCameraPosition>.broadcast();
  final _boundsController = StreamController<AnyLatLngBounds>.broadcast();

  @override
  Stream<AnyCameraPosition> get cameraPositionStream => _cameraController.stream;

  @override
  Stream<AnyLatLngBounds> get visibleBoundsStream => _boundsController.stream;

  @override
  Future<void> animateCamera(AnyCameraPosition position, {Duration duration = const Duration(milliseconds: 300)}) async {
    animateCameraCalls.add(position);
    _camera = position;
    _cameraController.add(_camera);
  }

  @override
  Future<void> moveCamera(AnyCameraPosition position) async {
    moveCameraCalls.add(position);
    _camera = position;
    _cameraController.add(_camera);
  }

  @override
  Future<void> fitBounds(AnyLatLngBounds bounds, {double padding = 48.0}) async {
    fitBoundsCalls.add(bounds);
  }

  @override
  Future<void> fitBoundsWithInsets(AnyLatLngBounds bounds, {EdgeInsets insets = const EdgeInsets.all(48)}) async {
    fitBoundsCalls.add(bounds);
  }

  @override
  Future<AnyCameraPosition> getCameraPosition() async => _camera;

  @override
  Future<AnyLatLngBounds> getVisibleBounds() async => AnyLatLngBounds(
        southwest: AnyLatLng(_camera.target.latitude - 0.1, _camera.target.longitude - 0.1),
        northeast: AnyLatLng(_camera.target.latitude + 0.1, _camera.target.longitude + 0.1),
      );

  @override
  Future<void> addMarkers(List<AnyMarker> markers) async => addedMarkers.add(markers);

  @override
  Future<void> removeMarkers(List<String> markerIds) async => removedMarkerIds.add(markerIds);

  @override
  Future<void> updateMarkers(List<AnyMarker> markers) async {}

  @override
  Future<void> clearMarkers() async => clearMarkersCount++;

  @override
  Future<void> addPolylines(List<AnyPolyline> polylines) async => addedPolylines.add(polylines);

  @override
  Future<void> removePolylines(List<String> polylineIds) async => removedPolylineIds.add(polylineIds);

  @override
  Future<void> clearPolylines() async => clearPolylinesCount++;

  @override
  Future<void> addPolygons(List<AnyPolygon> polygons) async => addedPolygons.add(polygons);

  @override
  Future<void> removePolygons(List<String> polygonIds) async {}

  @override
  Future<void> clearPolygons() async {}

  @override
  Future<void> addCircles(List<AnyCircle> circles) async => addedCircles.add(circles);

  @override
  Future<void> removeCircles(List<String> circleIds) async {}

  @override
  Future<void> clearCircles() async {}

  @override
  Future<void> animatePolyline(AnyPolyline polyline, {Duration duration = const Duration(seconds: 1)}) async {}

  @override
  Future<ui.Image?> takeSnapshot() async => null;

  @override
  Future<AnyLatLng?> screenToLatLng(ui.Offset screenPoint) async => null;

  @override
  Future<ui.Offset?> latLngToScreen(AnyLatLng position) async => Offset.zero;

  @override
  Future<void> setStyle(AnyMapStyle style) async {}

  @override
  void dispose() {
    _cameraController.close();
    _boundsController.close();
  }
}
