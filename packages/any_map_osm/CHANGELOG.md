## 1.0.0

* Updated to `any_map: ^1.0.0`
* Implements new `AnyMapController` abstract members: `cameraPositionStream`, `visibleBoundsStream`, `fitBoundsWithInsets()`, `animatePolyline()`, `takeSnapshot()`
* `cameraPositionStream` and `visibleBoundsStream` emit live updates on every camera move via broadcast `StreamController`
* `fitBoundsWithInsets()` passes `EdgeInsets` directly to `flutter_map` `CameraFit.bounds`

---

## 0.1.0

* Initial release
* OpenStreetMap adapter for any_map using flutter_map
* Declarative overlay rendering (markers, polylines, polygons, circles)
* Camera control: animateCamera, moveCamera, fitBounds
* Custom tile URL template support
* Polygon holes support
* Gesture configuration (zoom, scroll, rotate)
