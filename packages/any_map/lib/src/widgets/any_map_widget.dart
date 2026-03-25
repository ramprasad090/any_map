import 'package:flutter/widgets.dart';

import '../controllers/map_controller.dart';
import '../models/models.dart';

/// Callback when the map is created and ready.
typedef AnyMapCreatedCallback = void Function(AnyMapController controller);

/// The unified map widget. Wraps any backend via [AnyMapAdapter].
///
/// ```dart
/// AnyMapWidget(
///   adapter: MapLibreAdapter(styleUrl: '...'),
///   initialCamera: AnyCameraPosition(
///     target: AnyLatLng(37.7749, -122.4194),
///     zoom: 12,
///   ),
///   markers: myMarkers,
///   onMapCreated: (controller) => _controller = controller,
///   onTap: (latLng) => print('Tapped $latLng'),
/// )
/// ```
class AnyMapWidget extends StatelessWidget {
  /// The backend adapter that provides the actual map implementation.
  final AnyMapAdapter adapter;

  /// Initial camera position.
  final AnyCameraPosition initialCamera;

  /// Map style configuration.
  final AnyMapStyle? style;

  /// Markers to display on the map.
  final List<AnyMarker> markers;

  /// Polylines to display.
  final List<AnyPolyline> polylines;

  /// Polygons to display.
  final List<AnyPolygon> polygons;

  /// Circles to display.
  final List<AnyCircle> circles;

  /// Called when the map is created.
  final AnyMapCreatedCallback? onMapCreated;

  /// Called when the map is tapped.
  final ValueChanged<AnyLatLng>? onTap;

  /// Called when the map is long-pressed.
  final ValueChanged<AnyLatLng>? onLongPress;

  /// Called when the camera starts moving.
  final VoidCallback? onCameraMoveStarted;

  /// Called continuously as the camera moves.
  final ValueChanged<AnyCameraPosition>? onCameraMove;

  /// Called when the camera stops moving.
  final VoidCallback? onCameraIdle;

  /// Whether to show the user's location.
  final bool myLocationEnabled;

  /// Whether to show the my-location button.
  final bool myLocationButtonEnabled;

  /// Whether to show the compass.
  final bool compassEnabled;

  /// Whether zoom gestures are enabled.
  final bool zoomGesturesEnabled;

  /// Whether scroll/pan gestures are enabled.
  final bool scrollGesturesEnabled;

  /// Whether tilt gestures are enabled.
  final bool tiltGesturesEnabled;

  /// Whether rotate gestures are enabled.
  final bool rotateGesturesEnabled;

  /// Minimum zoom level.
  final double? minZoom;

  /// Maximum zoom level.
  final double? maxZoom;

  const AnyMapWidget({
    super.key,
    required this.adapter,
    required this.initialCamera,
    this.style,
    this.markers = const [],
    this.polylines = const [],
    this.polygons = const [],
    this.circles = const [],
    this.onMapCreated,
    this.onTap,
    this.onLongPress,
    this.onCameraMoveStarted,
    this.onCameraMove,
    this.onCameraIdle,
    this.myLocationEnabled = false,
    this.myLocationButtonEnabled = false,
    this.compassEnabled = true,
    this.zoomGesturesEnabled = true,
    this.scrollGesturesEnabled = true,
    this.tiltGesturesEnabled = true,
    this.rotateGesturesEnabled = true,
    this.minZoom,
    this.maxZoom,
  });

  @override
  Widget build(BuildContext context) {
    return adapter.buildMapWidget(this);
  }
}

/// Interface that each backend adapter must implement.
///
/// Adapters live in separate packages (e.g. `any_map_maplibre`,
/// `any_map_google`) and provide the actual map rendering.
abstract class AnyMapAdapter {
  /// Build the platform-specific map widget from the unified config.
  Widget buildMapWidget(AnyMapWidget config);
}
