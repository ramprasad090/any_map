## 1.0.0

* Updated to `any_map: ^1.0.0`
* Implements new `AnyMapController` abstract members: `cameraPositionStream`, `visibleBoundsStream`, `fitBoundsWithInsets()`, `animatePolyline()`, `takeSnapshot()`
* `cameraPositionStream` and `visibleBoundsStream` emit live updates on every camera move via broadcast `StreamController`
* `fitBoundsWithInsets()` passes per-edge padding to `maplibre_gl` `CameraUpdate.newLatLngBounds`
* `animatePolyline()` progressively reveals polyline points using a periodic `Timer`
* `takeSnapshot()` calls `maplibreController.takeSnapshot()`

---

## 0.1.0

* Initial release
* MapLibre GL adapter for any_map
* Full AnyMapController implementation with imperative overlay management
* 3D building extrusions via enable3DBuildings()
* Exposed nativeController for advanced MapLibre operations
* Runtime style switching via setStyle()
* Reactive overlay sync — markers, polylines, polygons, circles update on widget rebuild
* Safe disposal handling on style/backend switches
* Alpha-aware opacity for polygons and circles
* Symbol-based markers with rotation, opacity, drag support
* Line-based polylines with color, width, opacity
* Fill-based polygons with fill/stroke colors and holes
* Circle annotations with radius conversion
* Screen-to-LatLng and LatLng-to-screen coordinate conversion
