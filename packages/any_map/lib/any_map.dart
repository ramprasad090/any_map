/// Unified map abstraction for Flutter.
///
/// One API — swap Google Maps, MapLibre, or OSM backends at config level.
/// Includes marker clustering, turn-by-turn routing, traffic, geofencing,
/// voice guidance, trip analytics, and more.
///
/// ```dart
/// import 'package:any_map/any_map.dart';
/// import 'package:any_map_maplibre/any_map_maplibre.dart';
///
/// AnyMapWidget(
///   adapter: MapLibreAdapter(styleUrl: 'https://demotiles.maplibre.org/style.json'),
///   initialCamera: AnyCameraPosition(
///     target: AnyLatLng(37.7749, -122.4194),
///     zoom: 12,
///   ),
///   markers: myMarkers,
///   onMapCreated: (controller) => _controller = controller,
///   onTap: (latLng) => print('Tapped $latLng'),
/// )
/// ```
library;

// Models
export 'src/models/camera_position.dart';
export 'src/models/circle.dart';
export 'src/models/lat_lng.dart';
export 'src/models/lat_lng_bounds.dart';
export 'src/models/map_style.dart';
export 'src/models/marker.dart';
export 'src/models/polygon.dart';
export 'src/models/polyline.dart';

// Controller
export 'src/controllers/map_controller.dart';

// Widget
export 'src/widgets/any_map_widget.dart';
export 'src/widgets/marker_popup.dart';
export 'src/widgets/places_search_field.dart';

// Clustering
export 'src/clustering/cluster.dart';
export 'src/clustering/cluster_engine.dart';
export 'src/clustering/cluster_layer.dart';

// Routing
export 'src/routing/polyline_codec.dart';
export 'src/routing/route.dart';
export 'src/routing/routing_provider.dart';
export 'src/routing/providers/osrm_provider.dart';
export 'src/routing/providers/valhalla_provider.dart';
export 'src/routing/providers/graphhopper_provider.dart';
export 'src/routing/distance_matrix.dart';
export 'src/routing/map_matcher.dart';
export 'src/routing/route_optimizer.dart';

// Search / Geocoding
export 'src/search/search_provider.dart';
export 'src/search/nominatim_provider.dart';
export 'src/search/photon_provider.dart';
export 'src/search/pelias_provider.dart';
export 'src/search/opencage_provider.dart';
export 'src/search/nearby_places.dart';
export 'src/search/place_details.dart';

// Traffic
export 'src/traffic/traffic_provider.dart';

// Location
export 'src/location/location_provider.dart';
export 'src/location/user_location_layer.dart';

// Geofencing
export 'src/geofence/geofence.dart';

// Layers
export 'src/layers/heatmap_layer.dart';
export 'src/layers/geojson_layer.dart';
export 'src/layers/animated_polyline.dart';

// Navigation
export 'src/navigation/voice_guidance.dart';
export 'src/navigation/rerouting.dart';

// Offline
export 'src/offline/offline_manager.dart';

// Isochrone
export 'src/isochrone/isochrone.dart';

// Analytics
export 'src/analytics/trip_analytics.dart';

// Social / Crowdsourced
export 'src/social/crowdsourced_reports.dart';

// Indoor Maps
export 'src/indoor/indoor_map.dart';

// Errors
export 'src/errors/map_error.dart';

// Offline / Tile caching
export 'src/offline/cached_tile_provider.dart';

// Testing
export 'src/testing/fake_adapter.dart';
