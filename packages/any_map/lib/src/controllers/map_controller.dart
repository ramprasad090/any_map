import 'dart:async';
import 'dart:ui' as ui;

import '../models/models.dart';

/// Abstract controller for interacting with the map programmatically.
///
/// Each backend adapter implements this interface. You get an instance
/// via [AnyMapWidget.onMapCreated].
abstract class AnyMapController {
  // ── Camera ──

  /// Animate the camera to a new position.
  Future<void> animateCamera(
    AnyCameraPosition position, {
    Duration duration = const Duration(milliseconds: 300),
  });

  /// Move the camera instantly (no animation).
  Future<void> moveCamera(AnyCameraPosition position);

  /// Animate to show all the given bounds with optional padding.
  Future<void> fitBounds(
    AnyLatLngBounds bounds, {
    double padding = 48.0,
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
