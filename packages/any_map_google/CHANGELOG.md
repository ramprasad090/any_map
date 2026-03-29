## 1.0.0

* Updated to `any_map: ^1.0.0`
* Implements new `AnyMapController` abstract members: `cameraPositionStream`, `visibleBoundsStream`, `fitBoundsWithInsets()`, `animatePolyline()`, `takeSnapshot()`
* `cameraPositionStream` and `visibleBoundsStream` emit live updates on every camera move via broadcast `StreamController`
* `fitBoundsWithInsets()` averages all four inset sides into a single padding value (Google Maps API limitation)
* `takeSnapshot()` calls `googleMapController.takeSnapshot()`

---

## 0.1.0

* Initial release
* Google Maps adapter for any_map
* Declarative overlay rendering (markers, polylines, polygons, circles)
* Camera control with tilt and bearing support
* JSON style support for custom map themes
* Screen-to-LatLng and LatLng-to-screen coordinate conversion
* Info window support for markers (title + snippet)
