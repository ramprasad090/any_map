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
