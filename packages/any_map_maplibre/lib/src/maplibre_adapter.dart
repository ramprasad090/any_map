import 'package:flutter/widgets.dart';
import 'package:any_map/any_map.dart';
import 'package:maplibre_gl/maplibre_gl.dart' as ml;

import 'maplibre_controller.dart';

/// MapLibre adapter for any_map — free, open-source map rendering.
class MapLibreAdapter implements AnyMapAdapter {
  /// The default MapLibre style URL used when no style is provided.
  final String styleUrl;

  /// Creates a MapLibre adapter with an optional [styleUrl].
  MapLibreAdapter({
    this.styleUrl = 'https://demotiles.maplibre.org/style.json',
  });

  /// Builds the MapLibre-backed map widget from the unified [config].
  @override
  Widget buildMapWidget(AnyMapWidget config) {
    return _MapLibreMapWidget(
      config: config,
      styleUrl: config.style?.styleUrl ?? styleUrl,
    );
  }
}

class _MapLibreMapWidget extends StatefulWidget {
  final AnyMapWidget config;
  final String styleUrl;

  const _MapLibreMapWidget({
    required this.config,
    required this.styleUrl,
  });

  @override
  State<_MapLibreMapWidget> createState() => _MapLibreMapWidgetState();
}

class _MapLibreMapWidgetState extends State<_MapLibreMapWidget> {
  ml.MapLibreMapController? _nativeController;
  MapLibreController? _anyController;
  bool _styleLoaded = false;
  bool _disposed = false;

  // Track what's currently on the map by ID sets
  Set<String> _markerIds = {};
  Set<String> _polylineIds = {};
  Set<String> _polygonIds = {};
  Set<String> _circleIds = {};

  @override
  Widget build(BuildContext context) {
    final config = widget.config;
    final camera = config.initialCamera;

    return ml.MapLibreMap(
      styleString: widget.styleUrl,
      initialCameraPosition: ml.CameraPosition(
        target: ml.LatLng(camera.target.latitude, camera.target.longitude),
        zoom: camera.zoom,
        tilt: camera.tilt,
        bearing: camera.bearing,
      ),
      myLocationEnabled: config.myLocationEnabled,
      myLocationTrackingMode: config.myLocationEnabled
          ? ml.MyLocationTrackingMode.tracking
          : ml.MyLocationTrackingMode.none,
      compassEnabled: config.compassEnabled,
      rotateGesturesEnabled: config.rotateGesturesEnabled,
      scrollGesturesEnabled: config.scrollGesturesEnabled,
      tiltGesturesEnabled: config.tiltGesturesEnabled,
      zoomGesturesEnabled: config.zoomGesturesEnabled,
      minMaxZoomPreference: ml.MinMaxZoomPreference(
        config.minZoom ?? 0,
        config.maxZoom ?? 22,
      ),
      onMapCreated: _onMapCreated,
      onStyleLoadedCallback: _onStyleLoaded,
      onMapClick: config.onTap != null
          ? (point, latLng) =>
              config.onTap!(AnyLatLng(latLng.latitude, latLng.longitude))
          : null,
      onMapLongClick: config.onLongPress != null
          ? (point, latLng) =>
              config.onLongPress!(AnyLatLng(latLng.latitude, latLng.longitude))
          : null,
      onCameraIdle: config.onCameraIdle,
      onCameraTrackingDismissed: config.onCameraMoveStarted,
    );
  }

  void _onMapCreated(ml.MapLibreMapController controller) {
    _nativeController = controller;
  }

  void _onStyleLoaded() {
    if (_nativeController == null || _disposed) return;
    _styleLoaded = true;

    final config = widget.config;
    _anyController = MapLibreController(
      controller: _nativeController!,
      markers: config.markers,
      polylines: config.polylines,
      polygons: config.polygons,
      circles: config.circles,
    );

    _markerIds = config.markers.map((m) => m.id).toSet();
    _polylineIds = config.polylines.map((p) => p.id).toSet();
    _polygonIds = config.polygons.map((p) => p.id).toSet();
    _circleIds = config.circles.map((c) => c.id).toSet();

    config.onMapCreated?.call(_anyController!);
  }

  @override
  void didUpdateWidget(_MapLibreMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_styleLoaded || _anyController == null || _disposed) return;

    final config = widget.config;
    final newMarkerIds = config.markers.map((m) => m.id).toSet();
    final newPolylineIds = config.polylines.map((p) => p.id).toSet();
    final newPolygonIds = config.polygons.map((p) => p.id).toSet();
    final newCircleIds = config.circles.map((c) => c.id).toSet();

    final markersChanged = !_setEquals(newMarkerIds, _markerIds);
    final polylinesChanged = !_setEquals(newPolylineIds, _polylineIds);
    final polygonsChanged = !_setEquals(newPolygonIds, _polygonIds);
    final circlesChanged = !_setEquals(newCircleIds, _circleIds);

    if (markersChanged || polylinesChanged || polygonsChanged || circlesChanged) {
      _syncOverlays(
        config,
        syncMarkers: markersChanged,
        syncPolylines: polylinesChanged,
        syncPolygons: polygonsChanged,
        syncCircles: circlesChanged,
      );
    }
  }

  Future<void> _syncOverlays(
    AnyMapWidget config, {
    bool syncMarkers = false,
    bool syncPolylines = false,
    bool syncPolygons = false,
    bool syncCircles = false,
  }) async {
    final ctrl = _anyController;
    if (ctrl == null || _disposed) return;

    try {
      if (syncPolylines && !_disposed) {
        if (_polylineIds.isNotEmpty) {
          await ctrl.removePolylines(_polylineIds.toList());
        }
        if (!_disposed && config.polylines.isNotEmpty) {
          await ctrl.addPolylines(config.polylines);
        }
        _polylineIds = config.polylines.map((p) => p.id).toSet();
      }

      if (syncMarkers && !_disposed) {
        if (_markerIds.isNotEmpty) {
          await ctrl.removeMarkers(_markerIds.toList());
        }
        if (!_disposed && config.markers.isNotEmpty) {
          await ctrl.addMarkers(config.markers);
        }
        _markerIds = config.markers.map((m) => m.id).toSet();
      }

      if (syncPolygons && !_disposed) {
        if (_polygonIds.isNotEmpty) {
          await ctrl.removePolygons(_polygonIds.toList());
        }
        if (!_disposed && config.polygons.isNotEmpty) {
          await ctrl.addPolygons(config.polygons);
        }
        _polygonIds = config.polygons.map((p) => p.id).toSet();
      }

      if (syncCircles && !_disposed) {
        if (_circleIds.isNotEmpty) {
          await ctrl.removeCircles(_circleIds.toList());
        }
        if (!_disposed && config.circles.isNotEmpty) {
          await ctrl.addCircles(config.circles);
        }
        _circleIds = config.circles.map((c) => c.id).toSet();
      }
    } catch (_) {
      // Silently handle errors from stale style/controller during transitions
    }
  }

  bool _setEquals(Set<String> a, Set<String> b) {
    if (a.length != b.length) return false;
    return a.containsAll(b);
  }

  @override
  void dispose() {
    _disposed = true;
    _nativeController = null;
    _anyController = null;
    _styleLoaded = false;
    super.dispose();
  }
}
