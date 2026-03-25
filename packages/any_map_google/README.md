# any_map_google

Google Maps adapter for [any_map](https://pub.dev/packages/any_map). Uses google_maps_flutter under the hood for Android and iOS.

## Features

- Declarative overlay rendering (markers, polylines, polygons, circles)
- Camera control with tilt and bearing support
- JSON style support for custom map themes
- Screen-to-LatLng and LatLng-to-screen coordinate conversion
- Info windows for markers (title + snippet)
- Supports Android, iOS

## Setup

Requires a Google Maps API key. Add it to:
- **Android**: `android/app/src/main/AndroidManifest.xml`
- **iOS**: `ios/Runner/AppDelegate.swift`

See [google_maps_flutter setup](https://pub.dev/packages/google_maps_flutter) for details.

## Usage

```dart
import 'package:any_map/any_map.dart';
import 'package:any_map_google/any_map_google.dart';

AnyMapWidget(
  adapter: GoogleMapsAdapter(),
  initialCamera: AnyCameraPosition(
    target: AnyLatLng(17.3850, 78.4867),
    zoom: 12,
  ),
)
```

## License

MIT
