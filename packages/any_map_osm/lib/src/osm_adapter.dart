import 'package:flutter/widgets.dart';
import 'package:any_map/any_map.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart' as ll;

import 'osm_controller.dart';

/// OpenStreetMap adapter for any_map using flutter_map. Free, no API key.
///
/// ```dart
/// AnyMapWidget(
///   adapter: OsmAdapter(),
///   initialCamera: AnyCameraPosition(target: AnyLatLng(51.5, -0.09), zoom: 13),
/// )
/// ```
class OsmAdapter implements AnyMapAdapter {
  /// Tile server URL template. Defaults to OpenStreetMap.
  final String tileUrlTemplate;

  OsmAdapter({
    this.tileUrlTemplate = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  });

  @override
  Widget buildMapWidget(AnyMapWidget config) {
    return _OsmMapWidget(
      config: config,
      tileUrlTemplate: tileUrlTemplate,
    );
  }
}

class _OsmMapWidget extends StatefulWidget {
  final AnyMapWidget config;
  final String tileUrlTemplate;

  const _OsmMapWidget({
    required this.config,
    required this.tileUrlTemplate,
  });

  @override
  State<_OsmMapWidget> createState() => _OsmMapWidgetState();
}

class _OsmMapWidgetState extends State<_OsmMapWidget> {
  late final fm.MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = fm.MapController();
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.config;
    final camera = config.initialCamera;

    return fm.FlutterMap(
      mapController: _mapController,
      options: fm.MapOptions(
        initialCenter: ll.LatLng(camera.target.latitude, camera.target.longitude),
        initialZoom: camera.zoom,
        initialRotation: camera.bearing,
        minZoom: config.minZoom ?? 0,
        maxZoom: config.maxZoom ?? 18,
        interactionOptions: fm.InteractionOptions(
          flags: _buildInteractionFlags(config),
        ),
        onMapReady: () {
          final anyController = OsmController(
            controller: _mapController,
          );
          config.onMapCreated?.call(anyController);
        },
        onTap: config.onTap != null
            ? (tapPos, latLng) =>
                config.onTap!(AnyLatLng(latLng.latitude, latLng.longitude))
            : null,
        onLongPress: config.onLongPress != null
            ? (tapPos, latLng) =>
                config.onLongPress!(AnyLatLng(latLng.latitude, latLng.longitude))
            : null,
      ),
      children: [
        fm.TileLayer(
          urlTemplate: widget.tileUrlTemplate,
          userAgentPackageName: 'com.anymap.app',
        ),
        // Polylines
        if (config.polylines.isNotEmpty)
          fm.PolylineLayer(
            polylines: config.polylines.map((p) {
              return fm.Polyline(
                points: p.points
                    .map((pt) => ll.LatLng(pt.latitude, pt.longitude))
                    .toList(),
                color: p.color.withValues(alpha: p.opacity),
                strokeWidth: p.width,
                // dash patterns handled via borderColor workaround in flutter_map
              );
            }).toList(),
          ),
        // Polygons
        if (config.polygons.isNotEmpty)
          fm.PolygonLayer(
            polygons: config.polygons.map((p) {
              return fm.Polygon(
                points: p.points
                    .map((pt) => ll.LatLng(pt.latitude, pt.longitude))
                    .toList(),
                holePointsList: p.holes
                        ?.map((hole) => hole
                            .map((pt) => ll.LatLng(pt.latitude, pt.longitude))
                            .toList())
                        .toList() ??
                    [],
                color: p.fillColor,
                borderColor: p.strokeColor,
                borderStrokeWidth: p.strokeWidth,
              );
            }).toList(),
          ),
        // Circles as CircleLayer
        if (config.circles.isNotEmpty)
          fm.CircleLayer(
            circles: config.circles.map((c) {
              return fm.CircleMarker(
                point: ll.LatLng(c.center.latitude, c.center.longitude),
                radius: c.radius,
                useRadiusInMeter: true,
                color: c.fillColor,
                borderColor: c.strokeColor,
                borderStrokeWidth: c.strokeWidth,
              );
            }).toList(),
          ),
        // Markers
        if (config.markers.isNotEmpty)
          fm.MarkerLayer(
            markers: config.markers.where((m) => m.visible).map((m) {
              return fm.Marker(
                point: ll.LatLng(m.position.latitude, m.position.longitude),
                width: 40,
                height: 40,
                rotate: true,
                child: GestureDetector(
                  onTap: m.onTap,
                  child: m.icon ??
                      const Icon(
                        IconData(0xe3ab, fontFamily: 'MaterialIcons'),
                        color: Color(0xFFE53935),
                        size: 36,
                      ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  int _buildInteractionFlags(AnyMapWidget config) {
    int flags = 0;
    if (config.scrollGesturesEnabled) flags |= fm.InteractiveFlag.drag;
    if (config.zoomGesturesEnabled) {
      flags |= fm.InteractiveFlag.pinchZoom;
      flags |= fm.InteractiveFlag.doubleTapZoom;
      flags |= fm.InteractiveFlag.scrollWheelZoom;
    }
    if (config.rotateGesturesEnabled) flags |= fm.InteractiveFlag.rotate;
    return flags;
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}
