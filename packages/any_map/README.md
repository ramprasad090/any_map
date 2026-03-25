# any_map

**One API. Any map backend.** Swap between Google Maps, MapLibre, and OpenStreetMap at config level.

[![pub package](https://img.shields.io/pub/v/any_map.svg)](https://pub.dev/packages/any_map)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

## Why any_map?

The Flutter maps ecosystem is fragmented. Each map provider has its own API, its own widget, its own marker/polyline classes. Switching providers means rewriting your entire map layer.

**any_map** solves this with a single unified API:

- **One `AnyMapWidget`** — works with any backend
- **Built-in marker clustering** — no extra package needed
- **Turn-by-turn routing** — OSRM, Valhalla, GraphHopper out of the box
- **JSON style support** — custom map themes from JSON, just like Google Maps
- **Zero vendor lock-in** — swap backends in one line

## Quick Start

```yaml
# pubspec.yaml
dependencies:
  any_map: ^0.1.0
  any_map_maplibre: ^0.1.0  # Free, no API key!
  # OR
  any_map_google: ^0.1.0    # Requires Google Maps API key
  # OR
  any_map_osm: ^0.1.0       # Free, uses OpenStreetMap tiles
```

```dart
import 'package:any_map/any_map.dart';
import 'package:any_map_maplibre/any_map_maplibre.dart';

AnyMapWidget(
  adapter: MapLibreAdapter(
    styleUrl: 'https://demotiles.maplibre.org/style.json',
  ),
  initialCamera: AnyCameraPosition(
    target: AnyLatLng(37.7749, -122.4194),
    zoom: 12,
  ),
  markers: [
    AnyMarker(
      id: 'sf',
      position: AnyLatLng(37.7749, -122.4194),
      title: 'San Francisco',
    ),
  ],
  onMapCreated: (controller) {
    // Same controller API regardless of backend
    controller.animateCamera(AnyCameraPosition(
      target: AnyLatLng(34.0522, -118.2437),
      zoom: 10,
    ));
  },
  onTap: (latLng) => print('Tapped $latLng'),
)
```

## Swap Backends in One Line

```dart
// MapLibre (free, open source)
adapter: MapLibreAdapter(styleUrl: 'https://...')

// Google Maps (requires API key)
adapter: GoogleMapsAdapter()

// OpenStreetMap (free, no API key)
adapter: OsmAdapter()
```

**That's it.** Your markers, polylines, polygons, circles, callbacks — everything else stays the same.

## Marker Clustering

Built-in grid-based clustering engine (inspired by Supercluster):

```dart
final engine = AnyClusterEngine(
  config: ClusterConfig(radius: 80, maxZoom: 18),
);
engine.load(myMarkers);

// Get clusters for current viewport
final clusters = engine.getClusters(visibleBounds, zoom: currentZoom);

for (final cluster in clusters) {
  if (cluster.isSingle) {
    // Render as normal marker
  } else {
    // Render as cluster bubble: "${cluster.count} markers"
  }
}
```

Or use the `AnyClusterLayer` widget for automatic clustering on top of any map.

## Turn-by-Turn Routing

Three providers included — all with the same API:

```dart
// OSRM (free, self-hostable, no API key)
final provider = OsrmRoutingProvider();

// Valhalla (free, self-hostable)
final provider = ValhallaRoutingProvider(baseUrl: 'https://your-valhalla.com');

// GraphHopper (free tier available)
final provider = GraphHopperRoutingProvider(apiKey: 'YOUR_KEY');

// Same API for all:
final result = await provider.getRoute(AnyRouteRequest(
  origin: AnyLatLng(37.7749, -122.4194),
  destination: AnyLatLng(34.0522, -118.2437),
  mode: AnyTravelMode.driving,
));

if (result.isSuccess) {
  final route = result.route!;
  print('${route.distanceText} • ${route.durationText}');
  print('${route.steps.length} turn-by-turn steps');

  // Draw on map instantly:
  controller.addPolylines([route.toPolyline()]);
}
```

## Custom Map Styles (JSON)

```dart
// Google Maps JSON style
AnyMapWidget(
  style: AnyMapStyle.fromJson(myGoogleStyleJson),
  ...
)

// MapLibre style URL
AnyMapWidget(
  style: AnyMapStyle.fromUrl('https://my-style-server.com/style.json'),
  ...
)

// Built-in presets
AnyMapWidget(
  style: AnyMapStyle.fromPreset(AnyMapStylePreset.dark),
  ...
)
```

## Full API Surface

| Feature | API |
|---------|-----|
| Map widget | `AnyMapWidget` |
| Camera control | `AnyMapController.animateCamera()`, `moveCamera()`, `fitBounds()` |
| Markers | `AnyMarker` — title, snippet, custom icon widget, rotation, drag |
| Polylines | `AnyPolyline` — color, width, dash pattern, geodesic |
| Polygons | `AnyPolygon` — fill, stroke, holes |
| Circles | `AnyCircle` — center, radius in meters |
| Clustering | `AnyClusterEngine`, `AnyClusterLayer` |
| Routing | `OsrmRoutingProvider`, `ValhallaRoutingProvider`, `GraphHopperRoutingProvider` |
| Styles | `AnyMapStyle.fromJson()`, `.fromUrl()`, `.fromPreset()` |
| Callbacks | `onTap`, `onLongPress`, `onCameraMove`, `onCameraIdle` |
| Conversion | `screenToLatLng()`, `latLngToScreen()` |

## Packages

| Package | Description | Free? |
|---------|-------------|-------|
| `any_map` | Core abstractions, clustering, routing | - |
| `any_map_maplibre` | MapLibre GL adapter | Yes |
| `any_map_google` | Google Maps adapter | API key required |
| `any_map_osm` | OpenStreetMap (flutter_map) adapter | Yes |

## License

MIT
