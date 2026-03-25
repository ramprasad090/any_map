# any_map_osm

OpenStreetMap adapter for [any_map](https://pub.dev/packages/any_map) using flutter_map. Free, open-source tile rendering with no API key required.

## Features

- Declarative overlay rendering (markers, polylines, polygons, circles)
- Camera control: animateCamera, moveCamera, fitBounds
- Custom tile URL template support
- Polygon holes support
- Supports Android, iOS, Web, macOS, Windows, Linux

## Usage

```dart
import 'package:any_map/any_map.dart';
import 'package:any_map_osm/any_map_osm.dart';

AnyMapWidget(
  adapter: OsmAdapter(),
  initialCamera: AnyCameraPosition(
    target: AnyLatLng(17.3850, 78.4867),
    zoom: 12,
  ),
  markers: [
    AnyMarker(id: 'pin', position: AnyLatLng(17.3616, 78.4747), title: 'Charminar'),
  ],
)
```

## License

MIT
