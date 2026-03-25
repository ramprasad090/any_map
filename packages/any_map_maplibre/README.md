# any_map_maplibre

MapLibre GL adapter for [any_map](https://pub.dev/packages/any_map). Free, open-source map rendering with 3D buildings, vector tiles, and no API key required.

## Features

- Full `AnyMapController` implementation with imperative overlay management
- 3D building extrusions via `enable3DBuildings()`
- Runtime style switching (Streets, Dark, Satellite, etc.)
- Reactive overlay sync — markers, polylines, polygons, circles update on widget rebuild
- Screen-to-LatLng and LatLng-to-screen coordinate conversion
- Supports Android, iOS, Web, macOS, Windows, Linux

## Usage

```dart
import 'package:any_map/any_map.dart';
import 'package:any_map_maplibre/any_map_maplibre.dart';

AnyMapWidget(
  adapter: MapLibreAdapter(
    styleUrl: 'https://tiles.openfreemap.org/styles/liberty',
  ),
  initialCamera: AnyCameraPosition(
    target: AnyLatLng(17.3850, 78.4867),
    zoom: 12,
    tilt: 45,
  ),
  onMapCreated: (controller) {
    if (controller is MapLibreController) {
      controller.enable3DBuildings();
    }
  },
)
```

## License

MIT
