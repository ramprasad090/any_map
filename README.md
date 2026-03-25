# any_map

**Unified map abstraction for Flutter.** One API — swap Google Maps, MapLibre, or OpenStreetMap backends at config level.

Built for production navigation apps with 30+ features: turn-by-turn routing, traffic visualization, 3D buildings, geofencing, voice guidance, trip analytics, heatmaps, GeoJSON, indoor maps, and more — all backend-agnostic and fully customizable.

---

## Table of Contents

- [Quick Start](#quick-start)
- [Backends & Platform Support](#backends--platform-support)
- [Map Display & Styling](#map-display--styling)
- [Markers](#markers)
- [Polylines](#polylines)
- [Polygons & Circles](#polygons--circles)
- [Marker Clustering](#marker-clustering)
- [Routing & Navigation](#routing--navigation)
- [Traffic-Colored Routes](#traffic-colored-routes)
- [Lane Guidance](#lane-guidance)
- [Speed Limits & Road Annotations](#speed-limits--road-annotations)
- [Route Options](#route-options)
- [Automatic Rerouting](#automatic-rerouting)
- [Places Search & Geocoding](#places-search--geocoding)
- [Place Details](#place-details)
- [Geofencing](#geofencing)
- [Heatmap Layer](#heatmap-layer)
- [GeoJSON Layer](#geojson-layer)
- [Animated & Gradient Polylines](#animated--gradient-polylines)
- [Voice Guidance](#voice-guidance)
- [Trip Analytics](#trip-analytics)
- [Location Tracking](#location-tracking)
- [Offline Maps](#offline-maps)
- [Isochrone / Reachability](#isochrone--reachability)
- [Crowdsourced Reports](#crowdsourced-reports)
- [Indoor Maps](#indoor-maps)
- [EV & Truck Routing](#ev--truck-routing)
- [Customization](#customization)
- [Architecture](#architecture)

---

## Quick Start

```dart
import 'package:any_map/any_map.dart';
import 'package:any_map_maplibre/any_map_maplibre.dart';

AnyMapWidget(
  adapter: MapLibreAdapter(
    styleUrl: 'https://tiles.openfreemap.org/styles/liberty',
  ),
  initialCamera: AnyCameraPosition(
    target: AnyLatLng(17.3850, 78.4867), // Hyderabad
    zoom: 12,
    tilt: 45, // 3D view
    bearing: 30,
  ),
  markers: [
    AnyMarker(id: 'charminar', position: AnyLatLng(17.3616, 78.4747), title: 'Charminar'),
  ],
  onMapCreated: (controller) {
    // Enable 3D buildings (MapLibre only)
    if (controller is MapLibreController) {
      controller.enable3DBuildings(color: '#aab7ef', opacity: 0.6);
    }
  },
  onTap: (latLng) => print('Tapped: $latLng'),
  onLongPress: (latLng) => print('Long pressed: $latLng'),
  myLocationEnabled: true,
  compassEnabled: true,
  tiltGesturesEnabled: true,
  rotateGesturesEnabled: true,
)
```

---

## Backends & Platform Support

| Package | Backend | Free | API Key | Install |
|---------|---------|------|---------|---------|
| `any_map_maplibre` | MapLibre GL | Yes | No | `any_map_maplibre: ^0.1.0` |
| `any_map_osm` | flutter_map (OSM) | Yes | No | `any_map_osm: ^0.1.0` |
| `any_map_google` | Google Maps | No | Required | `any_map_google: ^0.1.0` |

| Platform | MapLibre | OSM | Google Maps |
|----------|----------|-----|-------------|
| Android | Yes | Yes | Yes |
| iOS | Yes | Yes | Yes |
| Web | Yes | Yes | No |
| macOS | Yes | Yes | No |
| Windows | Yes | Yes | No |
| Linux | Yes | Yes | No |

| Feature | MapLibre | OSM | Google Maps |
|---------|----------|-----|-------------|
| 3D tilt / bearing | Yes | No | Yes |
| 3D building extrusions | Yes | No | Yes |
| Custom vector styles | Yes | No | JSON only |
| Screen-to-LatLng conversion | Yes | No | Yes |
| Widget-based markers | No | Yes | Limited |

---

## Map Display & Styling

### Switch styles at runtime

```dart
// Predefined styles
enum MapStyle {
  streets('https://tiles.openfreemap.org/styles/liberty'),
  dark('https://tiles.openfreemap.org/styles/dark'),
  satellite('https://tiles.openfreemap.org/styles/positron'),
  bright('https://tiles.openfreemap.org/styles/bright');
}

// Apply style via adapter
MapLibreAdapter(styleUrl: MapStyle.dark.url)

// Or change at runtime via controller
controller.setStyle(AnyMapStyle.fromUrl('https://tiles.openfreemap.org/styles/dark'));

// Custom JSON style (Google Maps format)
controller.setStyle(AnyMapStyle.fromJson('[{"featureType":"water","stylers":[{"color":"#0e171d"}]}]'));
```

### 3D Buildings

```dart
// MapLibre only — call after onMapCreated
if (controller is MapLibreController) {
  controller.enable3DBuildings(
    color: '#aab7ef',    // building color
    opacity: 0.6,        // transparency
    minZoom: 15,         // only show at close zoom
  );
}
```

### Camera Control

```dart
// Animate to position
controller.animateCamera(AnyCameraPosition(
  target: AnyLatLng(17.3616, 78.4747),
  zoom: 16,
  tilt: 60,      // 3D perspective (0-85 degrees)
  bearing: 45,   // rotation from north
));

// Instant move (no animation)
controller.moveCamera(AnyCameraPosition(target: AnyLatLng(17.3616, 78.4747), zoom: 14));

// Fit bounds with padding
controller.fitBounds(
  AnyLatLngBounds(
    southwest: AnyLatLng(17.35, 78.40),
    northeast: AnyLatLng(17.45, 78.55),
  ),
  padding: 64,
);

// Get current position
final pos = await controller.getCameraPosition();
print('Zoom: ${pos.zoom}, Tilt: ${pos.tilt}');
```

---

## Markers

```dart
AnyMarker(
  id: 'my-marker',
  position: AnyLatLng(17.3616, 78.4747),
  title: 'Charminar',
  snippet: 'Historic monument',
  iconAsset: 'assets/pin.png',    // custom icon
  rotation: 45.0,                  // rotate marker
  opacity: 0.8,                    // transparency
  draggable: true,                 // user can drag
  visible: true,
  zIndex: 10,
  metadata: {'category': 'tourism'},
  onTap: () => print('Marker tapped!'),
  onDragEnd: (newPos) => print('Dragged to: $newPos'),
)

// Add/remove/update programmatically
await controller.addMarkers([marker1, marker2]);
await controller.updateMarkers([updatedMarker]);
await controller.removeMarkers(['marker-id-1']);
await controller.clearMarkers();
```

---

## Polylines

```dart
AnyPolyline(
  id: 'route',
  points: [AnyLatLng(17.36, 78.47), AnyLatLng(17.44, 78.38)],
  color: Color(0xFF4285F4),      // any color
  width: 6.0,                     // line width
  opacity: 0.9,
  dashPattern: [10, 5],           // dashed line
  strokeJoin: AnyStrokeJoin.round,
  strokeCap: AnyStrokeCap.round,
  geodesic: true,                 // follows Earth curvature
  visible: true,
  zIndex: 5,
  onTap: () => print('Polyline tapped!'),
)

await controller.addPolylines([polyline]);
await controller.removePolylines(['route']);
await controller.clearPolylines();
```

---

## Polygons & Circles

```dart
// Polygon with holes
AnyPolygon(
  id: 'area',
  points: [AnyLatLng(17.36, 78.47), AnyLatLng(17.44, 78.38), AnyLatLng(17.40, 78.50)],
  holes: [[AnyLatLng(17.39, 78.44), AnyLatLng(17.41, 78.43), AnyLatLng(17.40, 78.46)]],
  fillColor: Color(0x334285F4),
  strokeColor: Color(0xFF4285F4),
  strokeWidth: 2.0,
  opacity: 0.8,
)

// Circle
AnyCircle(
  id: 'radius',
  center: AnyLatLng(17.3616, 78.4747),
  radius: 500,                    // meters
  fillColor: Color(0x3300FF00),
  strokeColor: Color(0xFF00FF00),
  strokeWidth: 2.0,
)
```

---

## Marker Clustering

```dart
// Configure clustering
final engine = AnyClusterEngine(config: ClusterConfig(
  radius: 80,       // cluster radius in pixels
  minZoom: 0,
  maxZoom: 18,
));

// Load markers
engine.load(allMarkers);

// Get clusters for current viewport
final clusters = engine.getClusters(visibleBounds, zoom: currentZoom);

for (final cluster in clusters) {
  if (cluster.isSingle) {
    // Single marker — render normally
    print(cluster.markers.first.title);
  } else {
    // Cluster — render count badge
    print('${cluster.count} markers at ${cluster.position}');
  }
}

// Or use the built-in widget layer
AnyClusterLayer(
  controller: mapController,
  markers: allMarkers,
  config: ClusterConfig(radius: 80),
  builder: (cluster) => Container(
    decoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
    child: Center(child: Text('${cluster.count}')),
  ),
  onClusterTap: (cluster) => controller.fitBounds(
    AnyLatLngBounds.fromPoints(cluster.markers.map((m) => m.position).toList()),
  ),
)
```

---

## Routing & Navigation

### Basic routing (OSRM — free, no API key)

```dart
final provider = OsrmRoutingProvider();
// Or self-hosted: OsrmRoutingProvider(baseUrl: 'https://my-osrm.example.com')

final result = await provider.getRoute(AnyRouteRequest(
  origin: AnyLatLng(17.3616, 78.4747),      // Charminar
  destination: AnyLatLng(17.4435, 78.3772),  // HITEC City
  mode: AnyTravelMode.driving,               // driving, walking, cycling, transit
  alternatives: true,                         // request alternative routes
  language: 'en',                            // instruction language
  includeAnnotations: true,                  // bridge/tunnel/toll detection
  includeSpeedLimits: true,                  // speed limit data
));

if (result.isSuccess) {
  final route = result.route!;
  print('${route.durationText} — ${route.distanceText}');
  print('Steps: ${route.steps.length}');
  print('Has bridges: ${route.hasBridges}');
  print('Has tunnels: ${route.hasTunnels}');
  print('Has tolls: ${route.hasTolls}');

  // Draw on map
  await controller.addPolylines([route.toPolyline(id: 'route', width: 6.0)]);

  // Fit camera to route
  controller.fitBounds(route.bounds, padding: 80);

  // Alternative routes
  for (final alt in result.alternatives) {
    print('Alternative: ${alt.durationText}');
  }
}
```

### Other routing providers

```dart
// Valhalla (free, self-hostable, supports all travel modes including transit)
final valhalla = ValhallaRoutingProvider(baseUrl: 'https://my-valhalla.example.com');

// GraphHopper (free tier available, API key required)
final graphhopper = GraphHopperRoutingProvider(apiKey: 'YOUR_KEY');
```

### Turn-by-turn steps

```dart
for (final step in route.steps) {
  print(step.instruction);                     // "Turn left onto NH 44"
  print(step.maneuver);                        // "turn-left"
  print(step.roadName);                        // "NH 44"
  print(step.roadRef);                         // "NH 44"
  print('${step.distanceMeters}m in ${step.durationSeconds}s');
  print('Start: ${step.startLocation}');
  print('Geometry points: ${step.geometry.length}');
}
```

---

## Traffic-Colored Routes

```dart
// Automatically color route segments by congestion (green/yellow/red)
final trafficPolylines = route.toTrafficPolylines(
  idPrefix: 'traffic',
  width: 6.0,
);
await controller.addPolylines(trafficPolylines);

// Access per-segment congestion data
for (final segment in route.segments) {
  print('${segment.start} → ${segment.end}');
  print('Congestion: ${segment.congestion}');  // freeFlow, slow, congested, blocked
  print('Speed: ${segment.speed} m/s');
}

// Congestion colors:
// - AnyCongestionLevel.freeFlow  → green
// - AnyCongestionLevel.slow      → yellow
// - AnyCongestionLevel.congested → orange/red
// - AnyCongestionLevel.blocked   → dark red
// - AnyCongestionLevel.unknown   → blue
```

### Traffic incidents & flow (provider interface)

```dart
// Implement AnyTrafficProvider for your data source (TomTom, HERE, etc.)
abstract class AnyTrafficProvider {
  Future<List<AnyTrafficIncident>> getIncidents(AnyLatLngBounds bounds);
  Future<List<AnyTrafficFlow>> getFlow(AnyLatLngBounds bounds);
}

// Incident types: jam, accident, roadwork, closure, hazard, weather
// Flow data: currentSpeedKmh, freeFlowSpeedKmh, congestionLevel
```

---

## Lane Guidance

```dart
for (final step in route.steps) {
  if (step.lanes.isNotEmpty) {
    for (final lane in step.lanes) {
      print('Lane directions: ${lane.directions}');  // ["left", "straight"]
      print('Recommended: ${lane.isActive}');        // true = use this lane
    }
  }
}
```

---

## Speed Limits & Road Annotations

```dart
for (final step in route.steps) {
  // Speed limit
  if (step.speedLimit != null) {
    print('Speed limit: ${step.speedLimit!.speedKmh} km/h');
    print('Speed limit: ${step.speedLimit!.speedMph} mph');
    print('Explicit sign: ${step.speedLimit!.isExplicit}');
  }

  // Road annotations
  if (step.annotation != null) {
    final ann = step.annotation!;
    if (ann.isBridge) print('FLYOVER / BRIDGE');
    if (ann.isTunnel) print('TUNNEL');
    if (ann.isToll) print('TOLL ROAD');
    if (ann.isFerry) print('FERRY');
    if (ann.isMotorway) print('MOTORWAY');
    print('Road class: ${ann.roadClass}');  // motorway, trunk, primary, secondary, etc.
    print('Road name: ${ann.roadName}');
  }
}
```

---

## Route Options

```dart
AnyRouteRequest(
  origin: origin,
  destination: destination,
  mode: AnyTravelMode.driving,
  avoidTolls: true,        // skip toll roads
  avoidHighways: true,     // skip motorways
  avoidFerries: true,      // skip ferries
  departureTime: DateTime.now().add(Duration(hours: 1)),  // time-aware routing
  language: 'hi',          // Hindi instructions
)
```

---

## Automatic Rerouting

```dart
final rerouter = AnyRerouteEngine(
  provider: OsrmRoutingProvider(),
  config: AnyRerouteConfig(
    deviationThreshold: 50,   // meters off-route before rerouting
    cooldown: Duration(seconds: 15),
    maxAttempts: 3,
  ),
);

// Set the active route
rerouter.setRoute(route, request);

// Listen for reroute events
rerouter.events.listen((event) {
  print('Rerouted: ${event.reason}');
  print('New route: ${event.newRoute.durationText}');
  // Update map with event.newRoute
});

// Feed location updates (call on each GPS fix)
await rerouter.updateLocation(currentPosition);
```

---

## Places Search & Geocoding

```dart
final search = NominatimSearchProvider();  // free, no API key

// Search with location bias
final results = await search.search(
  'Charminar',
  near: AnyLatLng(17.3850, 78.4867),  // bias towards Hyderabad
  radiusKm: 50,
  limit: 8,
);

for (final place in results) {
  print('${place.name} — ${place.address}');
  print('Position: ${place.position}');
  print('Category: ${place.category}');  // tourism, amenity, shop, etc.
}

// Reverse geocoding (coordinate → address)
final place = await search.reverseGeocode(AnyLatLng(17.3616, 78.4747));
print(place?.address);  // "Charminar, Old City, Hyderabad, Telangana, India"
```

---

## Place Details

```dart
// Rich place information model
AnyPlaceDetails(
  id: 'place_123',
  name: 'Taj Falaknuma Palace',
  address: 'Engine Bowli, Falaknuma, Hyderabad',
  position: AnyLatLng(17.3312, 78.4677),
  phone: '+91 40 6629 8585',
  website: 'https://www.tajhotels.com/falaknuma',
  rating: 4.7,
  ratingCount: 12500,
  priceLevel: 4,            // 0=free, 1=cheap, 4=very expensive
  isOpenNow: true,
  categories: ['hotel', 'restaurant', 'heritage'],
  photoUrls: ['https://...'],
  openingHours: [
    AnyOpeningHours(dayOfWeek: 1, dayName: 'Monday', openTime: '06:00', closeTime: '23:00'),
    AnyOpeningHours(dayOfWeek: 7, dayName: 'Sunday', isClosed: true),
  ],
)
```

---

## Geofencing

```dart
final engine = AnyGeofenceEngine();

// Circular geofence
engine.addGeofence(AnyGeofence(
  id: 'office',
  label: 'HITEC City Office',
  center: AnyLatLng(17.4435, 78.3772),
  radius: 200,  // meters
  dwellTime: Duration(minutes: 5),
  metadata: {'type': 'work'},
));

// Polygon geofence (arbitrary shape)
engine.addGeofence(AnyGeofence(
  id: 'campus',
  label: 'University Campus',
  center: AnyLatLng(17.4, 78.5),  // approximate center
  polygon: [
    AnyLatLng(17.39, 78.49), AnyLatLng(17.41, 78.49),
    AnyLatLng(17.41, 78.51), AnyLatLng(17.39, 78.51),
  ],
));

// Listen for events
engine.events.listen((trigger) {
  switch (trigger.event) {
    case AnyGeofenceEvent.enter:
      print('Entered ${trigger.geofence.label}');
    case AnyGeofenceEvent.exit:
      print('Left ${trigger.geofence.label}');
    case AnyGeofenceEvent.dwell:
      print('Dwelling in ${trigger.geofence.label} for ${trigger.geofence.dwellTime}');
  }
});

// Feed location updates
engine.updateLocation(currentPosition);

// Check manually
final isInside = myGeofence.contains(AnyLatLng(17.44, 78.38));

// Cleanup
engine.removeGeofence('office');
engine.clearGeofences();
engine.dispose();
```

---

## Heatmap Layer

```dart
final heatmap = AnyHeatmapLayer(
  id: 'traffic-heatmap',
  points: [
    AnyHeatmapPoint(position: AnyLatLng(17.36, 78.47), intensity: 1.0),
    AnyHeatmapPoint(position: AnyLatLng(17.44, 78.38), intensity: 0.7),
    AnyHeatmapPoint(position: AnyLatLng(17.42, 78.47), intensity: 0.3),
  ],
  radius: 20.0,
  opacity: 0.7,
  maxIntensity: 1.0,
  gradient: [
    HeatmapGradientStop(0.0, Color(0xFF0000FF)),  // blue (cool)
    HeatmapGradientStop(0.4, Color(0xFF00FF00)),  // green
    HeatmapGradientStop(0.6, Color(0xFFFFFF00)),  // yellow
    HeatmapGradientStop(0.8, Color(0xFFFF8C00)),  // orange
    HeatmapGradientStop(1.0, Color(0xFFFF0000)),  // red (hot)
  ],
  minZoom: 10,
  maxZoom: 18,
);
```

---

## GeoJSON Layer

```dart
final layer = AnyGeoJsonLayer(
  id: 'my-geojson',
  geoJson: '{"type":"FeatureCollection","features":[...]}',
  pointColor: Color(0xFFFF5722),
  lineColor: Color(0xFF4285F4),
  lineWidth: 3.0,
  fillColor: Color(0x334285F4),
  strokeColor: Color(0xFF4285F4),
);

// Parse to typed features
final features = layer.parseFeatures();
for (final f in features) {
  print('${f.geometryType}: ${f.properties}');
}

// Convert to map overlays
final markers = layer.toMarkers();      // Point → AnyMarker
final lines = layer.toPolylines();      // LineString → AnyPolyline
final polys = layer.toPolygons();       // Polygon → AnyPolygon

await controller.addMarkers(markers);
await controller.addPolylines(lines);
await controller.addPolygons(polys);
```

---

## Animated & Gradient Polylines

```dart
// Animated polyline (progressive draw)
final animated = AnyAnimatedPolyline(
  id: 'draw-route',
  points: routeGeometry,
  width: 5.0,
  color: Color(0xFF4285F4),
  animationDuration: Duration(seconds: 3),
);

// Get polyline at specific progress (0.0 to 1.0)
final partial = animated.toPolylineAt(0.5);  // 50% drawn

// Gradient polyline (color changes along path)
final gradient = AnyAnimatedPolyline(
  id: 'gradient-route',
  points: routeGeometry,
  gradient: [
    AnyGradientStop(offset: 0.0, color: Colors.green),
    AnyGradientStop(offset: 0.5, color: Colors.yellow),
    AnyGradientStop(offset: 1.0, color: Colors.red),
  ],
);

final coloredSegments = gradient.toGradientPolylines();
await controller.addPolylines(coloredSegments);
```

---

## Voice Guidance

```dart
// Implement AnyVoiceGuidance with your TTS engine (e.g. flutter_tts)
class MyVoiceGuidance extends AnyVoiceGuidance {
  // ... implement speak(), stop(), etc.
}

final voice = MyVoiceGuidance();
voice.language = 'en-US';
voice.speechRate = 0.5;
voice.volume = 1.0;

// Generate instructions
final preAnnounce = voice.buildPreAnnouncement(step, 500);
// → "In 500 meters, Turn left onto NH 44"

final instruction = voice.buildInstruction(step);
// → "Turn left onto NH 44"

final arrival = voice.buildArrivalText();
// → "You have arrived at your destination."

// Speak
await voice.speak(AnyVoiceInstruction(
  text: preAnnounce,
  type: AnyAnnouncementType.preAnnouncement,
  step: step,
  distanceMeters: 500,
));
```

---

## Trip Analytics

```dart
final logger = AnyTripLogger(
  fuelConfig: AnyFuelConfig(
    fuelType: AnyFuelType.petrol,      // petrol, diesel, electric, hybrid, cng, lpg
    consumptionPer100km: 8.0,          // liters per 100km
  ),
);

// Start recording
logger.start();

// Feed GPS waypoints during trip
logger.addWaypoint(AnyTripWaypoint(
  position: AnyLatLng(17.3616, 78.4747),
  speed: 13.9,         // m/s (~50 km/h)
  heading: 45.0,
  timestamp: DateTime.now(),
));

// Stop and get summary
final summary = logger.stop();

print('Distance: ${summary.distanceKm.toStringAsFixed(1)} km');
print('Duration: ${summary.durationText}');
print('Avg speed: ${summary.averageSpeedKmh.toStringAsFixed(0)} km/h');
print('Max speed: ${(summary.maxSpeed * 3.6).toStringAsFixed(0)} km/h');
print('Fuel consumed: ${summary.fuelConsumedLiters?.toStringAsFixed(1)} L');
print('CO2 emitted: ${(summary.co2EmittedGrams! / 1000).toStringAsFixed(1)} kg');
print('Eco score: ${summary.ecoScore}/100');
print('Harsh braking: ${summary.harshBrakingCount}x');
print('Harsh acceleration: ${summary.harshAccelerationCount}x');

// Fuel estimation standalone
final fuel = AnyFuelConfig(fuelType: AnyFuelType.diesel, consumptionPer100km: 6.0);
print('Fuel for 100km: ${fuel.estimateFuelLiters(100000)} L');
print('CO2 for 100km: ${fuel.estimateCO2Grams(100000)} g');
```

---

## Location Tracking

```dart
// Implement AnyLocationProvider with platform services (geolocator, location package)
abstract class AnyLocationProvider {
  Stream<AnyUserLocation> get locationStream;
  Future<AnyUserLocation?> getLastLocation();
  Future<bool> requestPermission();
  Future<bool> isServiceEnabled();
  Future<void> startUpdates({Duration interval, double distanceFilter});
  Future<void> stopUpdates();
}

// Location data model
AnyUserLocation(
  position: AnyLatLng(17.36, 78.47),
  heading: 45.0,       // degrees from north
  accuracy: 5.0,       // meters
  altitude: 540.0,     // meters above sea level
  speed: 13.9,         // m/s
  timestamp: DateTime.now(),
)

// Follow modes
AnyFollowMode.none                  // don't follow
AnyFollowMode.followLocation        // camera follows, north up
AnyFollowMode.followLocationWithBearing  // camera follows + rotates with heading
```

---

## Offline Maps

```dart
// Implement AnyOfflineManager per backend
abstract class AnyOfflineManager {
  Future<AnyOfflineRegion> downloadRegion({
    required String name,
    required AnyLatLngBounds bounds,
    double minZoom = 0,
    double maxZoom = 16,
  });
  Future<void> deleteRegion(String id);
  Future<List<AnyOfflineRegion>> listRegions();
  Future<void> clearCache();
  Future<int> getCacheSize();
}

// Cache configuration
AnyTileCacheConfig(
  maxSizeBytes: 50 * 1024 * 1024,         // 50 MB
  expiration: Duration(days: 30),
  policy: AnyCachePolicy.cacheFirst,       // cacheFirst, networkFirst, cacheOnly
)
```

---

## Isochrone / Reachability

```dart
// "Show me everywhere I can reach in 15 minutes"
final provider = ValhallaIsochroneProvider(baseUrl: 'https://my-valhalla.example.com');

final isochrones = await provider.getIsochrones(AnyIsochroneRequest(
  center: AnyLatLng(17.3850, 78.4867),
  contourMinutes: [5, 10, 15, 30],  // time boundaries
  profile: 'driving',               // driving, walking, cycling
));

// Render as polygons on map
for (final iso in isochrones) {
  final polygon = iso.toPolygon(
    fillColor: Color(0x334285F4),
    strokeColor: Color(0xFF4285F4),
  );
  await controller.addPolygons([polygon]);
}
```

---

## Crowdsourced Reports

```dart
// Implement AnyReportProvider for your backend
abstract class AnyReportProvider {
  Future<List<AnyUserReport>> getReports(AnyLatLngBounds bounds, {Set<AnyReportType>? types});
  Future<AnyUserReport> submitReport({required AnyReportType type, required AnyLatLng position, String? description});
  Future<void> confirmReport(String reportId);
  Future<void> dismissReport(String reportId);
}

// Report types (Waze-style):
// trafficJam, accident, police, hazard, roadClosed, construction,
// weather, speedCamera, fuelPrice, other

// Report model
AnyUserReport(
  id: 'report_1',
  type: AnyReportType.hazard,
  severity: AnyReportSeverity.high,
  position: AnyLatLng(17.36, 78.47),
  description: 'Pothole on main road',
  reportedAt: DateTime.now(),
  expiresAt: DateTime.now().add(Duration(hours: 4)),
  confirmations: 12,
  dismissals: 2,
)

print(report.isActive);     // true if not expired
print(report.reliability);  // 0.86 (12 confirms / 14 total)
```

---

## Indoor Maps

```dart
// Venue model
AnyIndoorVenue(
  id: 'mall_1',
  name: 'Inorbit Mall',
  category: 'mall',
  center: AnyLatLng(17.4350, 78.3880),
  bounds: AnyLatLngBounds(...),
  floors: [
    AnyIndoorFloor(level: -1, label: 'Parking B1'),
    AnyIndoorFloor(level: 0, label: 'Ground Floor', isDefault: true),
    AnyIndoorFloor(level: 1, label: 'First Floor'),
    AnyIndoorFloor(level: 2, label: 'Food Court'),
  ],
  pois: [
    AnyIndoorPOI(id: 'store_1', name: 'Zara', position: ..., floorLevel: 1, category: 'store'),
    AnyIndoorPOI(id: 'rest_1', name: 'KFC', position: ..., floorLevel: 2, category: 'restaurant'),
    AnyIndoorPOI(id: 'elev_1', name: 'Elevator A', position: ..., floorLevel: 0, category: 'elevator'),
  ],
)

// Get floor by level
final groundFloor = venue.getFloor(0);

// Each floor can have:
// - GeoJSON layout (walls, rooms, corridors)
// - Floor plan image overlay (with bounds)

// Implement AnyIndoorMapProvider for your data source
abstract class AnyIndoorMapProvider {
  Future<AnyIndoorVenue?> getVenue(String venueId);
  Future<List<AnyIndoorVenue>> searchVenues(AnyLatLng near, {double radiusKm, String? category});
}
```

---

## EV & Truck Routing

```dart
// Electric Vehicle routing
AnyRouteRequest(
  origin: origin,
  destination: destination,
  vehicleType: AnyVehicleType.electricVehicle,
  evBatteryLevel: 0.8,           // 80% charge
  evBatteryCapacity: 75.0,       // 75 kWh battery
  evConsumptionPer100km: 18.0,   // 18 kWh per 100km
)

// Truck routing with restrictions
AnyRouteRequest(
  origin: origin,
  destination: destination,
  vehicleType: AnyVehicleType.truck,
  truckHeight: 4.0,   // meters (for bridge clearance)
  truckWeight: 12.0,  // metric tons
  truckWidth: 2.5,    // meters
  truckLength: 12.0,  // meters
)

// Vehicle types: car, truck, bicycle, pedestrian, electricVehicle
```

---

## Customization

**Everything is customizable:**

| What | How |
|---|---|
| Polyline color | `AnyPolyline(color: Color(0xFFFF0000))` |
| Polyline width | `AnyPolyline(width: 8.0)` |
| Dashed lines | `AnyPolyline(dashPattern: [10, 5])` |
| Traffic colors | `route.toTrafficPolylines()` or custom colors per segment |
| Gradient polylines | `AnyAnimatedPolyline(gradient: [...])` |
| Marker icon | `AnyMarker(iconAsset: 'assets/car.png')` |
| Marker rotation | `AnyMarker(rotation: 45.0)` |
| Marker opacity | `AnyMarker(opacity: 0.5)` |
| Polygon fill/stroke | `AnyPolygon(fillColor: ..., strokeColor: ...)` |
| Circle radius/color | `AnyCircle(radius: 500, fillColor: ...)` |
| Map style | URL-based or JSON |
| 3D building color | `enable3DBuildings(color: '#ff0000', opacity: 0.8)` |
| Heatmap gradient | Custom `HeatmapGradientStop` list |
| Geofence shape | Circular or polygon |
| Trip fuel config | Custom fuel type, consumption, CO2 factor |
| Cluster radius | `ClusterConfig(radius: 100)` |
| Voice language | `voice.language = 'hi-IN'` |
| Reroute threshold | `AnyRerouteConfig(deviationThreshold: 100)` |

---

## Architecture

```
any_map (core)
├── Models
│   ├── AnyLatLng, AnyLatLngBounds
│   ├── AnyCameraPosition (target, zoom, tilt, bearing)
│   ├── AnyMarker (icon, rotation, drag, tap)
│   ├── AnyPolyline (color, width, dash, geodesic)
│   ├── AnyPolygon (fill, stroke, holes)
│   ├── AnyCircle (center, radius, styling)
│   └── AnyMapStyle (JSON, URL, presets)
│
├── Controller — AnyMapController (abstract)
│   ├── Camera: animate, move, fitBounds, getPosition
│   ├── Overlays: add/remove/update markers, polylines, polygons, circles
│   ├── Conversion: screenToLatLng, latLngToScreen
│   └── Style: setStyle at runtime
│
├── Widget — AnyMapWidget (unified map)
│
├── Clustering
│   ├── AnyClusterEngine (grid-based, Supercluster-inspired)
│   └── AnyClusterLayer (widget overlay)
│
├── Routing
│   ├── AnyRoute, AnyRouteStep, AnyRouteSegment
│   ├── AnyLaneInfo, AnySpeedLimit, AnyRouteAnnotation
│   ├── AnyCongestionLevel, AnyRoadClass
│   ├── OsrmRoutingProvider (free)
│   ├── ValhallaRoutingProvider (free, self-hosted)
│   └── GraphHopperRoutingProvider (API key)
│
├── Search
│   ├── AnyPlace, AnyPlaceDetails, AnyOpeningHours
│   ├── NominatimSearchProvider (free)
│   └── AnySearchProvider (interface)
│
├── Traffic
│   ├── AnyTrafficIncident, AnyTrafficFlow
│   └── AnyTrafficProvider (interface)
│
├── Location
│   ├── AnyUserLocation, AnyFollowMode
│   └── AnyLocationProvider (interface)
│
├── Geofencing
│   ├── AnyGeofence (circular + polygon)
│   └── AnyGeofenceEngine (enter/exit/dwell events)
│
├── Layers
│   ├── AnyHeatmapLayer, AnyHeatmapPoint
│   ├── AnyGeoJsonLayer, AnyGeoJsonFeature
│   └── AnyAnimatedPolyline, AnyGradientStop
│
├── Navigation
│   ├── AnyVoiceGuidance, AnyVoiceInstruction
│   └── AnyRerouteEngine, AnyRerouteConfig
│
├── Offline
│   ├── AnyOfflineManager, AnyOfflineRegion
│   └── AnyTileCacheConfig, AnyCachePolicy
│
├── Isochrone
│   ├── AnyIsochrone, AnyIsochroneRequest
│   └── ValhallaIsochroneProvider
│
├── Analytics
│   ├── AnyTripLogger, AnyTripSummary
│   ├── AnyFuelConfig, AnyFuelType
│   └── AnyDrivingBehaviorEvent
│
├── Social
│   ├── AnyUserReport, AnyReportType
│   └── AnyReportProvider (interface)
│
└── Indoor
    ├── AnyIndoorVenue, AnyIndoorFloor, AnyIndoorPOI
    └── AnyIndoorMapProvider (interface)

Adapters:
├── any_map_maplibre → MapLibreController (3D buildings, native access, reactive sync)
├── any_map_osm     → OsmController (flutter_map, declarative overlays)
└── any_map_google  → GoogleMapController (Google Maps SDK)
```

---

## Routing Providers

| Provider | Free | Self-Hostable | API Key | Modes |
|----------|------|---------------|---------|-------|
| OSRM | Yes | Yes | No | driving, walking, cycling |
| Valhalla | Yes | Yes | Optional | driving, walking, cycling, transit |
| GraphHopper | Free tier | No | Required | driving, walking, cycling |

---

## License

MIT
