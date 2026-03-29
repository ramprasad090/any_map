import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart' show EdgeInsets;

import '../models/models.dart';

/// Abstract controller for interacting with the map programmatically.
///
/// Each backend adapter implements this interface. You get an instance
/// via [AnyMapWidget.onMapCreated].
abstract class AnyMapController {
  // ── Reactive Streams ──

  /// Stream that emits the current [AnyCameraPosition] whenever the camera moves.
  ///
  /// Backed by the adapter's native camera-move callback. Useful for reacting
  /// to user panning/zooming without polling [getCameraPosition].
  ///
  /// ```dart
  /// _controller.cameraPositionStream.listen((pos) {
  ///   print('zoom: ${pos.zoom}');
  /// });
  /// ```
  Stream<AnyCameraPosition> get cameraPositionStream;

  /// Stream that emits the current visible [AnyLatLngBounds] whenever the camera
  /// moves or the viewport changes.
  ///
  /// Emits in sync with [cameraPositionStream]. Use this to load data for the
  /// current viewport without polling [getVisibleBounds].
  Stream<AnyLatLngBounds> get visibleBoundsStream;

  // ── Camera ──

  /// Animate the camera to a new position.
  Future<void> animateCamera(
    AnyCameraPosition position, {
    Duration duration = const Duration(milliseconds: 300),
  });

  /// Move the camera instantly (no animation).
  Future<void> moveCamera(AnyCameraPosition position);

  /// Animate to show all the given bounds with optional padding.
  ///
  /// [padding] accepts either a uniform [double] (via the legacy overload) or
  /// a per-side [EdgeInsets] so you can account for overlaying UI panels.
  ///
  /// ```dart
  /// controller.fitBoundsWithInsets(
  ///   bounds,
  ///   insets: EdgeInsets.only(bottom: 250), // leave room for bottom sheet
  /// );
  /// ```
  Future<void> fitBounds(
    AnyLatLngBounds bounds, {
    double padding = 48.0,
  });

  /// Animate to show all the given bounds, honouring per-side [EdgeInsets].
  ///
  /// Defaults to [EdgeInsets.all(48)].
  Future<void> fitBoundsWithInsets(
    AnyLatLngBounds bounds, {
    EdgeInsets insets = const EdgeInsets.all(48),
  });

  /// Get the current camera position.
  Future<AnyCameraPosition> getCameraPosition();

  /// Get the current visible bounds.
  Future<AnyLatLngBounds> getVisibleBounds();

  // ── Markers ──

  /// Add markers to the map.
  Future<void> addMarkers(List<AnyMarker> markers);

  /// Remove markers by their IDs.
  Future<void> removeMarkers(List<String> markerIds);

  /// Update existing markers (matched by ID).
  Future<void> updateMarkers(List<AnyMarker> markers);

  /// Remove all markers from the map.
  Future<void> clearMarkers();

  // ── Polylines ──

  /// Add polylines to the map.
  Future<void> addPolylines(List<AnyPolyline> polylines);

  /// Remove polylines by their IDs.
  Future<void> removePolylines(List<String> polylineIds);

  /// Remove all polylines from the map.
  Future<void> clearPolylines();

  // ── Polygons ──

  /// Add polygons to the map.
  Future<void> addPolygons(List<AnyPolygon> polygons);

  /// Remove polygons by their IDs.
  Future<void> removePolygons(List<String> polygonIds);

  /// Remove all polygons from the map.
  Future<void> clearPolygons();

  // ── Circles ──

  /// Add circles to the map.
  Future<void> addCircles(List<AnyCircle> circles);

  /// Remove circles by their IDs.
  Future<void> removeCircles(List<String> circleIds);

  /// Remove all circles from the map.
  Future<void> clearCircles();

  // ── Polyline Animation ──

  /// Animate drawing a polyline from start to end over [duration].
  ///
  /// Progressively reveals [polyline] point-by-point, giving the impression of
  /// a route being drawn in real time. The polyline is added to the map at the
  /// start and updated on each tick via [addPolylines]/[removePolylines].
  ///
  /// ```dart
  /// await controller.animatePolyline(
  ///   route,
  ///   duration: Duration(seconds: 2),
  /// );
  /// ```
  Future<void> animatePolyline(
    AnyPolyline polyline, {
    Duration duration = const Duration(seconds: 1),
  });

  // ── Snapshot ──

  /// Capture the current map viewport as a PNG [Uint8List].
  ///
  /// Returns `null` if the backend does not support snapshots or the map is
  /// not yet initialised.
  ///
  /// ```dart
  /// final bytes = await controller.takeSnapshot();
  /// if (bytes != null) {
  ///   // display in Image.memory or save to file
  /// }
  /// ```
  Future<ui.Image?> takeSnapshot();

  // ── Conversion ──

  /// Convert a screen point to a geographic coordinate.
  Future<AnyLatLng?> screenToLatLng(ui.Offset screenPoint);

  /// Convert a geographic coordinate to a screen point.
  Future<ui.Offset?> latLngToScreen(AnyLatLng position);

  // ── Style ──

  /// Change the map style at runtime.
  Future<void> setStyle(AnyMapStyle style);

  // ── Lifecycle ──

  /// Dispose of native resources.
  void dispose();
}
