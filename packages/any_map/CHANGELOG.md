## 1.0.0

### New features

* **Reactive streams** — `cameraPositionStream` and `visibleBoundsStream` on `AnyMapController` for live camera updates
* **User location layer** — `AnyUserLocationLayer` widget with pulsing accuracy ring, heading wedge, and blue dot
* **Marker popup** — `AnyMarkerPopup` widget that tracks camera movement and floats above any marker
* **Animated polyline drawing** — `animatePolyline()` progressively reveals a route over a configurable duration
* **Bounds with insets** — `fitBoundsWithInsets()` supports per-edge padding (top/right/bottom/left)
* **GeoJSON improvements** — `AnyGeoJsonLayer.fromString()` factory and `fromAsset()` async loader
* **Tile caching** — `AnyCachingTileProvider` with LRU in-memory cache, optional `AnyTileStore` for durable storage, TTL expiry, and hit/miss stats
* **Snapshot / screenshot** — `takeSnapshot()` returns a `dart:ui Image` of the current map view
* **Error handling** — `AnyMapError` typed errors with `AnyMapErrorType` enum; `onError` callback on `AnyMapWidget`
* **Fake adapter for testing** — `AnyMapFakeAdapter` and `AnyMapFakeController` record all calls for widget tests without a real map view
* **Distance matrix** — `AnyDistanceMatrix` computes travel time and distance for multiple origin→destination pairs via OSRM Table API (free, no API key)
* **Map matching / GPS snapping** — `AnyMapMatcher` snaps noisy GPS traces to the road network via OSRM Match API
* **Route optimization** — `AnyRouteOptimizer` solves multi-stop TSP via OSRM Trip API and returns the optimal stop order
* **Nearby POI search** — `AnyPlaces.search()` queries Overpass API for restaurants, hospitals, ATMs, parks, and more (free, no API key)
* **Photon geocoding provider** — `PhotonSearchProvider` backed by Komoot's free public Photon server (no API key, self-hostable)
* **Pelias geocoding provider** — `PeliasSearchProvider` for self-hosted Pelias instances (free and open-source)
* **OpenCage geocoding provider** — `OpenCageSearchProvider` with 2,500 requests/day free tier
* **Places search field widget** — `AnyPlacesSearchField` drop-in search bar with debounce, loading indicator, overlay dropdown, clear button, and custom item builder

### Breaking changes

* `AnyMapController` now declares five new abstract members that all adapters must implement: `cameraPositionStream`, `visibleBoundsStream`, `fitBoundsWithInsets()`, `animatePolyline()`, `takeSnapshot()`

### Testing

* 85 unit tests covering `AnyLatLng`, `AnyLatLngBounds`, `PolylineCodec`, `AnyClusterEngine`, `AnyMatrixCell`, `AnyOptimizedRoute`, `AnyMapMatchResult`, `AnyRoute`, `AnySpeedLimit`, `AnyFuelConfig`, `AnyTripLogger`, `AnyTripSummary`, `AnyGeofence`, `AnyGeofenceEngine`, `AnyCachingTileProvider`, `AnyGeoJsonLayer`, and `AnyCacheStats`

---

## 0.1.0

* Initial release
* Unified map abstraction — one API for Google Maps, MapLibre, and OSM
* Core models: AnyLatLng, AnyLatLngBounds, AnyCameraPosition, AnyMapStyle
* Overlay models: AnyMarker, AnyPolyline, AnyPolygon, AnyCircle
* AnyMapController interface with camera, overlays, conversion, style methods
* AnyMapWidget with full gesture and callback support
* Marker clustering: AnyClusterEngine (grid-based) and AnyClusterLayer widget
* Routing: AnyRoute, AnyRouteStep with turn-by-turn navigation
* Route options: avoidTolls, avoidHighways, avoidFerries, departure time
* Lane guidance: AnyLaneInfo with active/inactive lane directions
* Speed limits: AnySpeedLimit with km/h and mph
* Road annotations: bridge/flyover, tunnel, toll, ferry, motorway detection
* Traffic-colored routes: per-segment congestion coloring (green/yellow/red)
* Traffic models: AnyTrafficIncident, AnyTrafficFlow, AnyTrafficProvider
* Routing providers: OsrmRoutingProvider, ValhallaRoutingProvider, GraphHopperRoutingProvider
* Polyline codec: encode/decode Google polyline format (precision 5 and 6)
* Places search: NominatimSearchProvider (free, no API key)
* Reverse geocoding support
* Place details model: hours, rating, phone, website, photos, price level
* Geofencing: circular and polygon geofences with enter/exit/dwell events
* Heatmap layer: weighted points with configurable gradient
* GeoJSON layer: parse FeatureCollections to markers, polylines, polygons
* Animated polylines: progressive draw animation with progress control
* Gradient polylines: color interpolation along path
* Voice guidance: TTS abstraction with pre-announcement and instruction generation
* Automatic rerouting: deviation detection with configurable threshold
* Location tracking: AnyUserLocation model with heading, accuracy, altitude, speed
* Follow modes: none, followLocation, followLocationWithBearing
* Offline maps: AnyOfflineManager interface with region download and cache config
* Isochrone: reachability contours with ValhallaIsochroneProvider
* Trip analytics: distance, duration, fuel, CO2, eco score, harsh event detection
* Fuel estimation: petrol, diesel, electric, hybrid, CNG, LPG
* Crowdsourced reports: Waze-style incident reporting (jam, accident, police, hazard)
* Indoor maps: venue, floor, and POI models with provider interface
* EV routing: battery level, capacity, consumption in route requests
* Truck routing: height, weight, width, length restrictions
* Vehicle types: car, truck, bicycle, pedestrian, electric vehicle
