import 'package:flutter/widgets.dart';
import 'package:any_map/any_map.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;

import 'google_controller.dart';

/// Google Maps adapter for any_map.
///
/// Requires a Google Maps API key configured per-platform.
///
/// ```dart
/// AnyMapWidget(
///   adapter: GoogleMapsAdapter(),
///   initialCamera: AnyCameraPosition(target: AnyLatLng(37.7749, -122.4194), zoom: 12),
/// )
/// ```
class GoogleMapsAdapter implements AnyMapAdapter {
  GoogleMapsAdapter();

  @override
  Widget buildMapWidget(AnyMapWidget config) {
    return _GoogleMapWidget(config: config);
  }
}

class _GoogleMapWidget extends StatefulWidget {
  final AnyMapWidget config;

  const _GoogleMapWidget({required this.config});

  @override
  State<_GoogleMapWidget> createState() => _GoogleMapWidgetState();
}

class _GoogleMapWidgetState extends State<_GoogleMapWidget> {
  @override
  Widget build(BuildContext context) {
    final config = widget.config;
    final camera = config.initialCamera;

    return gm.GoogleMap(
      initialCameraPosition: gm.CameraPosition(
        target: gm.LatLng(camera.target.latitude, camera.target.longitude),
        zoom: camera.zoom,
        tilt: camera.tilt,
        bearing: camera.bearing,
      ),
      myLocationEnabled: config.myLocationEnabled,
      myLocationButtonEnabled: config.myLocationButtonEnabled,
      compassEnabled: config.compassEnabled,
      rotateGesturesEnabled: config.rotateGesturesEnabled,
      scrollGesturesEnabled: config.scrollGesturesEnabled,
      tiltGesturesEnabled: config.tiltGesturesEnabled,
      zoomGesturesEnabled: config.zoomGesturesEnabled,
      minMaxZoomPreference: gm.MinMaxZoomPreference(
        config.minZoom ?? 0,
        config.maxZoom ?? 21,
      ),
      markers: _buildMarkers(config.markers),
      polylines: _buildPolylines(config.polylines),
      polygons: _buildPolygons(config.polygons),
      circles: _buildCircles(config.circles),
      onMapCreated: (controller) {
        final anyController = GoogleMapController(
          controller: controller,
          style: config.style,
        );
        config.onMapCreated?.call(anyController);
      },
      onTap: config.onTap != null
          ? (latLng) =>
              config.onTap!(AnyLatLng(latLng.latitude, latLng.longitude))
          : null,
      onLongPress: config.onLongPress != null
          ? (latLng) =>
              config.onLongPress!(AnyLatLng(latLng.latitude, latLng.longitude))
          : null,
      onCameraMoveStarted: config.onCameraMoveStarted,
      onCameraMove: config.onCameraMove != null
          ? (pos) => config.onCameraMove!(AnyCameraPosition(
                target: AnyLatLng(pos.target.latitude, pos.target.longitude),
                zoom: pos.zoom,
                tilt: pos.tilt,
                bearing: pos.bearing,
              ))
          : null,
      onCameraIdle: config.onCameraIdle,
      style: config.style?.jsonStyle,
    );
  }

  Set<gm.Marker> _buildMarkers(List<AnyMarker> markers) {
    return markers.map((m) {
      return gm.Marker(
        markerId: gm.MarkerId(m.id),
        position: gm.LatLng(m.position.latitude, m.position.longitude),
        infoWindow: gm.InfoWindow(
          title: m.title,
          snippet: m.snippet,
        ),
        rotation: m.rotation,
        alpha: m.opacity,
        draggable: m.draggable,
        visible: m.visible,
        zIndex: m.zIndex.toDouble(),
        onTap: m.onTap,
        onDragEnd: m.onDragEnd != null
            ? (pos) => m.onDragEnd!(AnyLatLng(pos.latitude, pos.longitude))
            : null,
      );
    }).toSet();
  }

  Set<gm.Polyline> _buildPolylines(List<AnyPolyline> polylines) {
    return polylines.map((p) {
      return gm.Polyline(
        polylineId: gm.PolylineId(p.id),
        points: p.points
            .map((pt) => gm.LatLng(pt.latitude, pt.longitude))
            .toList(),
        color: p.color,
        width: p.width.round(),
        geodesic: p.geodesic,
        visible: p.visible,
        zIndex: p.zIndex,
        onTap: p.onTap,
      );
    }).toSet();
  }

  Set<gm.Polygon> _buildPolygons(List<AnyPolygon> polygons) {
    return polygons.map((p) {
      return gm.Polygon(
        polygonId: gm.PolygonId(p.id),
        points: p.points
            .map((pt) => gm.LatLng(pt.latitude, pt.longitude))
            .toList(),
        holes: p.holes
                ?.map((hole) => hole
                    .map((pt) => gm.LatLng(pt.latitude, pt.longitude))
                    .toList())
                .toList() ??
            [],
        fillColor: p.fillColor,
        strokeColor: p.strokeColor,
        strokeWidth: p.strokeWidth.round(),
        visible: p.visible,
        zIndex: p.zIndex,
        onTap: p.onTap,
      );
    }).toSet();
  }

  Set<gm.Circle> _buildCircles(List<AnyCircle> circles) {
    return circles.map((c) {
      return gm.Circle(
        circleId: gm.CircleId(c.id),
        center: gm.LatLng(c.center.latitude, c.center.longitude),
        radius: c.radius,
        fillColor: c.fillColor,
        strokeColor: c.strokeColor,
        strokeWidth: c.strokeWidth.round(),
        visible: c.visible,
        zIndex: c.zIndex,
        onTap: c.onTap,
      );
    }).toSet();
  }
}
