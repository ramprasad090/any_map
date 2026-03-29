import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:any_map/any_map.dart';
import 'package:any_map_maplibre/any_map_maplibre.dart';
import 'package:any_map_osm/any_map_osm.dart';

void main() => runApp(const AnyMapExampleApp());

class AnyMapExampleApp extends StatelessWidget {
  const AnyMapExampleApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'any_map Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo), useMaterial3: true),
      home: const MapDemoPage(),
    );
  }
}

// ── Constants ──

enum MapStyle {
  streets('Streets', 'https://tiles.openfreemap.org/styles/liberty'),
  dark('Dark', 'https://tiles.openfreemap.org/styles/dark'),
  satellite('Satellite', 'https://tiles.openfreemap.org/styles/positron'),
  bright('Bright', 'https://tiles.openfreemap.org/styles/bright');
  final String label; final String url;
  const MapStyle(this.label, this.url);
}

enum MapBackend { maplibre, osm }

const _hyderabadCenter = AnyLatLng(17.3850, 78.4867);
const _landmarks = [
  AnyMarker(id: 'charminar', position: AnyLatLng(17.3616, 78.4747), title: 'Charminar'),
  AnyMarker(id: 'hitech', position: AnyLatLng(17.4435, 78.3772), title: 'HITEC City'),
  AnyMarker(id: 'hussain_sagar', position: AnyLatLng(17.4239, 78.4738), title: 'Hussain Sagar'),
  AnyMarker(id: 'golconda', position: AnyLatLng(17.3833, 78.4011), title: 'Golconda Fort'),
  AnyMarker(id: 'ramoji', position: AnyLatLng(17.2543, 78.6808), title: 'Ramoji Film City'),
];

class _RouteOption {
  final String label; final AnyLatLng origin; final AnyLatLng destination;
  const _RouteOption(this.label, this.origin, this.destination);
}

const _routeOptions = [
  _RouteOption('Charminar \u2192 HITEC City', AnyLatLng(17.3616, 78.4747), AnyLatLng(17.4435, 78.3772)),
  _RouteOption('Golconda \u2192 Ramoji', AnyLatLng(17.3833, 78.4011), AnyLatLng(17.2543, 78.6808)),
  _RouteOption('Hussain Sagar \u2192 Charminar', AnyLatLng(17.4239, 78.4738), AnyLatLng(17.3616, 78.4747)),
];

// ── Main Page ──

class MapDemoPage extends StatefulWidget {
  const MapDemoPage({super.key});
  @override
  State<MapDemoPage> createState() => _MapDemoPageState();
}

class _MapDemoPageState extends State<MapDemoPage> with TickerProviderStateMixin {
  // Map state
  MapBackend _backend = MapBackend.maplibre;
  MapStyle _mapStyle = MapStyle.streets;
  AnyMapController? _controller;
  bool _is3DView = false;

  // Route state
  AnyRoute? _route;
  bool _isRouting = false;
  List<AnyPolyline> _polylines = [];
  List<AnyMarker> _allMarkers = List.of(_landmarks);
  bool _showTrafficColors = true;
  AnyTravelMode _travelMode = AnyTravelMode.driving;

  // Search
  final _searchCtrl = TextEditingController();
  List<AnyPlace> _searchResults = [];
  bool _isSearching = false;
  bool _showSearch = false;

  // Navigation
  Timer? _navTimer;
  int _navIndex = 0;
  bool _isNavigating = false;
  int _currentStepIndex = 0;
  double _navBearing = 0;
  int _uiTick = 0;

  // Trip analytics
  AnyTripLogger? _tripLogger;

  // Geofencing
  final _geoEngine = AnyGeofenceEngine();
  StreamSubscription? _geoSub;
  String? _lastGeoEvent;

  // Rerouting
  late final AnyRerouteEngine _rerouter;

  // Layer toggles
  bool _showCircles = false;
  bool _showPolygons = false;
  bool _showClustering = false;
  bool _showGeoJson = false;
  bool _animatingPolyline = false;
  Timer? _animTimer;
  double _animProgress = 0;

  // Marker popup
  AnyMarker? _selectedMarker;

  // Camera stream — live zoom display
  StreamSubscription<AnyCameraPosition>? _cameraSub;
  double _liveZoom = 12.0;

  // Simulated location (Feature 2 demo)
  bool _showLocationLayer = false;
  Timer? _simLocTimer;
  _SimLocationProvider? _simLocProvider;

  // Distance Matrix demo
  bool _matrixLoading = false;
  String? _matrixResult;

  // Nearby POI demo
  bool _nearbyLoading = false;
  List<AnyMarker> _nearbyMarkers = [];

  // Route Optimizer demo
  bool _optimizerLoading = false;
  AnyOptimizedRoute? _optimizedRoute;

  // Map Matching demo
  bool _matcherLoading = false;
  List<AnyPolyline> _matchedPolylines = [];

  // Demo circles around landmarks
  final _demoCircles = const [
    AnyCircle(id: 'circle_charminar', center: AnyLatLng(17.3616, 78.4747), radius: 400, fillColor: Color(0x3300BCD4), strokeColor: Color(0xFF00BCD4), strokeWidth: 2),
    AnyCircle(id: 'circle_hitech', center: AnyLatLng(17.4435, 78.3772), radius: 600, fillColor: Color(0x33FF9800), strokeColor: Color(0xFFFF9800), strokeWidth: 2),
    AnyCircle(id: 'circle_golconda', center: AnyLatLng(17.3833, 78.4011), radius: 500, fillColor: Color(0x339C27B0), strokeColor: Color(0xFF9C27B0), strokeWidth: 2),
  ];

  // Demo polygon — Old City Hyderabad
  final _demoPolygons = const [
    AnyPolygon(
      id: 'old_city',
      points: [AnyLatLng(17.370, 78.460), AnyLatLng(17.370, 78.490), AnyLatLng(17.350, 78.490), AnyLatLng(17.345, 78.475), AnyLatLng(17.350, 78.460)],
      fillColor: Color(0x22E91E63), strokeColor: Color(0xFFE91E63), strokeWidth: 3,
    ),
  ];

  // Cluster markers — random points around Hyderabad
  late final List<AnyMarker> _clusterMarkers = _generateClusterMarkers();
  List<AnyMarker> _generateClusterMarkers() {
    final rng = math.Random(42);
    return List.generate(60, (i) {
      final lat = 17.3 + rng.nextDouble() * 0.2;
      final lng = 78.35 + rng.nextDouble() * 0.3;
      return AnyMarker(id: 'cluster_$i', position: AnyLatLng(lat, lng), title: 'Point $i');
    });
  }

  // GeoJSON — Hyderabad metro line (simplified)
  final _demoGeoJson = AnyGeoJsonLayer(
    id: 'metro',
    geoJson: '{"type":"FeatureCollection","features":['
        '{"type":"Feature","properties":{"name":"Metro Blue Line"},"geometry":{"type":"LineString","coordinates":[[78.3772,17.4435],[78.4100,17.4400],[78.4400,17.4300],[78.4600,17.4200],[78.4747,17.3616]]}},'
        '{"type":"Feature","properties":{"name":"Miyapur Station"},"geometry":{"type":"Point","coordinates":[78.3772,17.4435]}},'
        '{"type":"Feature","properties":{"name":"Ameerpet Station"},"geometry":{"type":"Point","coordinates":[78.4400,17.4300]}},'
        '{"type":"Feature","properties":{"name":"Charminar Station"},"geometry":{"type":"Point","coordinates":[78.4747,17.3616]}}'
        ']}',
    lineColor: const Color(0xFF2196F3),
    lineWidth: 4.0,
    pointColor: const Color(0xFFFF5722),
  );

  AnyMapAdapter get _adapter => switch (_backend) {
    MapBackend.maplibre => MapLibreAdapter(styleUrl: _mapStyle.url),
    MapBackend.osm => OsmAdapter(),
  };

  @override
  void initState() {
    super.initState();
    _rerouter = AnyRerouteEngine(provider: OsrmRoutingProvider());
    // Setup geofences around landmarks
    _geoEngine.addGeofence(AnyGeofence(id: 'charminar_zone', label: 'Charminar', center: const AnyLatLng(17.3616, 78.4747), radius: 300));
    _geoEngine.addGeofence(AnyGeofence(id: 'hitech_zone', label: 'HITEC City', center: const AnyLatLng(17.4435, 78.3772), radius: 500));
    _geoSub = _geoEngine.events.listen((t) {
      if (!mounted) return;
      final msg = switch (t.event) {
        AnyGeofenceEvent.enter => 'Entered ${t.geofence.label} zone',
        AnyGeofenceEvent.exit => 'Left ${t.geofence.label} zone',
        AnyGeofenceEvent.dwell => 'Dwelling in ${t.geofence.label}',
      };
      setState(() => _lastGeoEvent = msg);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 2)));
    });
  }

  void _onMapCreated(AnyMapController c) {
    _controller = c;
    if (_backend == MapBackend.maplibre && c is MapLibreController) {
      c.enable3DBuildings();
    }
    // Feature 1: subscribe to camera stream for live zoom badge
    _cameraSub?.cancel();
    _cameraSub = c.cameraPositionStream.listen((pos) {
      if (mounted) setState(() => _liveZoom = pos.zoom);
    });
  }

  // ── Search ──

  Future<void> _performSearch(String q) async {
    if (q.trim().isEmpty) { setState(() => _searchResults = []); return; }
    setState(() => _isSearching = true);
    final r = await NominatimSearchProvider().search(q, near: _hyderabadCenter, radiusKm: 100, limit: 8);
    if (mounted) setState(() { _searchResults = r; _isSearching = false; });
  }

  void _goToPlace(AnyPlace p) {
    setState(() { _showSearch = false; _searchResults = []; _searchCtrl.clear(); });
    setState(() => _allMarkers = [..._landmarks, AnyMarker(id: 'search_${p.id}', position: p.position, title: p.name)]);
    _controller?.animateCamera(AnyCameraPosition(target: p.position, zoom: 16, tilt: _is3DView ? 45 : 0));
  }

  // ── Routing ──

  Future<void> _computeRoute(_RouteOption opt) async {
    if (_isRouting) return;
    _stopNavigation();
    setState(() => _isRouting = true);

    final result = await OsrmRoutingProvider().getRoute(AnyRouteRequest(
      origin: opt.origin, destination: opt.destination,
      mode: _travelMode,
      includeAnnotations: true, includeSpeedLimits: true,
    ));

    if (!mounted) return;
    if (result.isSuccess) {
      final route = result.route!;
      _rerouter.setRoute(route, AnyRouteRequest(origin: opt.origin, destination: opt.destination, mode: _travelMode, includeAnnotations: true, includeSpeedLimits: true));
      setState(() {
        _route = route; _currentStepIndex = 0;
        _polylines = _showTrafficColors && route.segments.isNotEmpty
            ? route.toTrafficPolylines(idPrefix: 'route')
            : [route.toPolyline(id: 'route', width: 6.0)];
        _allMarkers = [..._landmarks, AnyMarker(id: 'origin', position: opt.origin, title: 'Start'), AnyMarker(id: 'dest', position: opt.destination, title: 'End')];
      });
      _controller?.fitBounds(route.bounds, padding: 80);
      if (mounted) {
        final badges = <String>[]; if (route.hasBridges) badges.add('Flyover'); if (route.hasTunnels) badges.add('Tunnel'); if (route.hasTolls) badges.add('Toll');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${route.durationText} \u2022 ${route.distanceText}${badges.isNotEmpty ? ' \u2022 ${badges.join(", ")}' : ''}'), duration: const Duration(seconds: 3)));
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Routing failed: ${result.error}')));
    }
    setState(() => _isRouting = false);
  }

  void _clearRoute() {
    _stopNavigation(); _rerouter.clearRoute();
    setState(() { _route = null; _polylines = []; _allMarkers = List.of(_landmarks); _currentStepIndex = 0; });
  }

  void _toggleTrafficColors() {
    setState(() => _showTrafficColors = !_showTrafficColors);
    if (_route != null) {
      setState(() => _polylines = _showTrafficColors && _route!.segments.isNotEmpty ? _route!.toTrafficPolylines(idPrefix: 'route') : [_route!.toPolyline(id: 'route', width: 6.0)]);
    }
  }

  // ── Navigation Simulation ──

  void _startNavigation() {
    if (_route == null || _route!.geometry.isEmpty) return;
    final pts = _route!.geometry;
    _tripLogger = AnyTripLogger(fuelConfig: const AnyFuelConfig(fuelType: AnyFuelType.petrol, consumptionPer100km: 8.0));
    _tripLogger!.start();
    setState(() { _isNavigating = true; _navIndex = 0; _currentStepIndex = 0; });
    if (pts.length > 1) _navBearing = _bearing(pts[0], pts[1]);
    _controller?.moveCamera(AnyCameraPosition(target: pts.first, zoom: 17.5, tilt: 65, bearing: _navBearing));
    _updateNavMarker(pts.first);
    _navTimer = Timer.periodic(const Duration(milliseconds: 200), (t) {
      if (!mounted || _route == null) { t.cancel(); return; }
      final pts = _route!.geometry;
      double moved = 0; final start = _navIndex;
      while (_navIndex < pts.length - 1 && moved < 30) { moved += pts[_navIndex].distanceTo(pts[_navIndex + 1]); _navIndex++; }
      if (_navIndex >= pts.length - 1) { _finishNavigation(); return; }
      final cur = pts[_navIndex];
      _tripLogger?.addWaypoint(AnyTripWaypoint(position: cur, speed: moved / 0.2, heading: _navBearing, timestamp: DateTime.now()));
      _geoEngine.updateLocation(cur);
      final ahead = _lookAhead(pts, _navIndex, 100);
      _navBearing = _lerpAngle(_navBearing, _bearing(cur, pts[ahead]), 0.3);
      _uiTick++;
      if (_uiTick % 3 == 0 || start == 0) { _updateNavMarker(cur); _updateStep(cur); }
      _controller?.moveCamera(AnyCameraPosition(target: cur, zoom: 17.5, tilt: 65, bearing: _navBearing));
    });
  }

  void _finishNavigation() {
    final summary = _tripLogger?.stop();
    _stopNavigation();
    if (mounted && summary != null) _showTripSummary(summary);
  }

  void _stopNavigation() {
    _navTimer?.cancel(); _navTimer = null; _uiTick = 0;
    if (_isNavigating) setState(() { _isNavigating = false; _navIndex = 0; });
  }

  void _updateNavMarker(AnyLatLng pos) {
    final p = _navIndex / _route!.geometry.length;
    final d = _route!.distanceMeters * (1.0 - p);
    final t = _route!.durationSeconds * (1.0 - p);
    setState(() => _allMarkers = [..._landmarks, AnyMarker(id: 'origin', position: _route!.geometry.first, title: 'Start'), AnyMarker(id: 'dest', position: _route!.geometry.last, title: 'End'), AnyMarker(id: 'nav', position: pos, title: '${_fmtDist(d)} \u2022 ${_fmtTime(t)}', rotation: _navBearing)]);
  }

  void _updateStep(AnyLatLng cur) {
    if (_route == null) return;
    for (int i = _currentStepIndex; i < _route!.steps.length; i++) {
      if (cur.distanceTo(_route!.steps[i].startLocation) < 50 && i > _currentStepIndex) { setState(() => _currentStepIndex = i); break; }
    }
  }

  void _showTripSummary(AnyTripSummary s) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Trip Summary'), content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        _row(Icons.straighten, 'Distance', '${s.distanceKm.toStringAsFixed(1)} km'),
        _row(Icons.schedule, 'Duration', s.durationText),
        _row(Icons.speed, 'Avg Speed', '${s.averageSpeedKmh.toStringAsFixed(0)} km/h'),
        if (s.fuelConsumedLiters != null) _row(Icons.local_gas_station, 'Fuel', '${s.fuelConsumedLiters!.toStringAsFixed(1)} L'),
        if (s.co2EmittedGrams != null) _row(Icons.eco, 'CO\u2082', '${(s.co2EmittedGrams! / 1000).toStringAsFixed(1)} kg'),
        _row(Icons.star, 'Eco Score', '${s.ecoScore}/100'),
        if (s.harshBrakingCount > 0) _row(Icons.warning, 'Harsh Braking', '${s.harshBrakingCount}x'),
        if (s.harshAccelerationCount > 0) _row(Icons.warning_amber, 'Harsh Accel', '${s.harshAccelerationCount}x'),
      ]), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
    ));
  }

  Widget _row(IconData ic, String l, String v) => Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Row(children: [Icon(ic, size: 18, color: Colors.grey), const SizedBox(width: 8), Text('$l: ', style: const TextStyle(fontWeight: FontWeight.w500)), Text(v)]));

  // ── Helpers ──

  int _lookAhead(List<AnyLatLng> pts, int from, double dist) { double a = 0; int i = from; while (i < pts.length - 1 && a < dist) { a += pts[i].distanceTo(pts[i + 1]); i++; } return i; }
  double _lerpAngle(double f, double t, double a) { double d = (t - f) % 360; if (d > 180) d -= 360; if (d < -180) d += 360; return (f + d * a) % 360; }
  double _bearing(AnyLatLng f, AnyLatLng t) { final dL = (t.longitude - f.longitude) * math.pi / 180; final l1 = f.latitude * math.pi / 180; final l2 = t.latitude * math.pi / 180; return (math.atan2(math.sin(dL) * math.cos(l2), math.cos(l1) * math.sin(l2) - math.sin(l1) * math.cos(l2) * math.cos(dL)) * 180 / math.pi + 360) % 360; }
  String _fmtDist(double m) => m < 1000 ? '${m.round()} m' : '${(m / 1000).toStringAsFixed(1)} km';
  String _fmtTime(double s) { if (s < 60) return '${s.round()}s'; final m = (s / 60).round(); if (m < 60) return '$m min'; return '${m ~/ 60}h ${m % 60}m'; }
  IconData _maneuverIcon(String? m) { if (m == null) return Icons.circle_outlined; if (m.contains('left')) return Icons.turn_left; if (m.contains('right')) return Icons.turn_right; if (m.contains('uturn') || m.contains('u-turn')) return Icons.u_turn_left; if (m.contains('arrive') || m.contains('destination')) return Icons.flag; if (m.contains('depart') || m.contains('start')) return Icons.trip_origin; if (m.contains('roundabout')) return Icons.roundabout_left; if (m.contains('merge')) return Icons.merge; if (m.contains('ramp') || m.contains('exit')) return Icons.ramp_right; return Icons.straight; }
  IconData _placeIcon(String? c) { if (c == null) return Icons.place; if (c.contains('tourism')) return Icons.attractions; if (c.contains('amenity')) return Icons.restaurant; if (c.contains('shop')) return Icons.shopping_cart; return Icons.place; }
  IconData _modeIcon(AnyTravelMode m) => switch (m) { AnyTravelMode.driving => Icons.directions_car, AnyTravelMode.walking => Icons.directions_walk, AnyTravelMode.cycling => Icons.directions_bike, AnyTravelMode.transit => Icons.directions_bus };

  // ── Layer toggles ──

  void _toggleLayerSheet() {
    showModalBottomSheet(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setSheetState) {
      return Padding(padding: const EdgeInsets.all(16), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Map Layers', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SwitchListTile(title: const Text('Circles (landmark radius)'), subtitle: const Text('AnyCircle — 3 circles around landmarks'), value: _showCircles, onChanged: (v) { setSheetState(() {}); setState(() => _showCircles = v); }),
        SwitchListTile(title: const Text('Polygon (Old City area)'), subtitle: const Text('AnyPolygon — pink outlined region'), value: _showPolygons, onChanged: (v) { setSheetState(() {}); setState(() => _showPolygons = v); }),
        SwitchListTile(title: const Text('Clustering (60 markers)'), subtitle: const Text('AnyClusterEngine — grouped markers'), value: _showClustering, onChanged: (v) { setSheetState(() {}); setState(() => _showClustering = v); }),
        SwitchListTile(title: const Text('GeoJSON (Metro line)'), subtitle: const Text('AnyGeoJsonLayer — parsed from JSON'), value: _showGeoJson, onChanged: (v) { setSheetState(() {}); setState(() { _showGeoJson = v; _applyGeoJson(); }); }),
        SwitchListTile(title: const Text('User Location Layer'), subtitle: const Text('AnyUserLocationLayer — pulsing dot + heading'), value: _showLocationLayer, onChanged: (v) { setSheetState(() {}); _toggleLocationLayer(v); }),
        if (_route != null) SwitchListTile(title: const Text('Animate route drawing'), subtitle: const Text('AnyAnimatedPolyline — progressive draw'), value: _animatingPolyline, onChanged: (v) { setSheetState(() {}); setState(() => _animatingPolyline = v); if (v) { _startAnimatePolyline(); } else { _stopAnimatePolyline(); } }),
      ]));
    }));
  }

  void _applyGeoJson() {
    if (_showGeoJson) {
      final lines = _demoGeoJson.toPolylines();
      final markers = _demoGeoJson.toMarkers();
      setState(() {
        _polylines = [..._polylines, ...lines];
        _allMarkers = [..._allMarkers, ...markers];
      });
    } else {
      setState(() {
        _polylines = _polylines.where((p) => !p.id.startsWith('metro')).toList();
        _allMarkers = _allMarkers.where((m) => !m.id.startsWith('metro')).toList();
      });
    }
  }

  // ── Location Layer (Feature 2) ──

  void _toggleLocationLayer(bool v) {
    setState(() => _showLocationLayer = v);
    if (v) {
      _simLocProvider = _SimLocationProvider(center: _hyderabadCenter);
      _simLocProvider!.startUpdates();
    } else {
      _simLocTimer?.cancel();
      _simLocProvider?.dispose();
      _simLocProvider = null;
    }
  }

  // ── Distance Matrix ──

  Future<void> _showDistanceMatrix() async {
    setState(() { _matrixLoading = true; _matrixResult = null; });
    final matrix = AnyDistanceMatrix();
    final origins = _landmarks.take(3).map((m) => m.position).toList();
    final dests = _landmarks.skip(2).take(3).map((m) => m.position).toList();
    final result = await matrix.calculate(origins: origins, destinations: dests);
    if (!mounted) return;
    setState(() => _matrixLoading = false);
    if (!result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Matrix failed: ${result.error}')));
      return;
    }
    final rows = <String>[];
    for (var i = 0; i < origins.length; i++) {
      final cells = result.matrix[i].map((c) => c.durationText ?? '–').join(' | ');
      rows.add('${_landmarks[i].title}: $cells');
    }
    setState(() => _matrixResult = rows.join('\n'));
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Distance Matrix'),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Origins: Charminar, HITEC, Hussain Sagar\nDestinations: Hussain Sagar, Golconda, Ramoji', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        Text(_matrixResult ?? '', style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
    ));
  }

  // ── Nearby POI ──

  Future<void> _findNearbyPlaces(AnyPlaceType type) async {
    setState(() => _nearbyLoading = true);
    final places = AnyPlaces();
    final results = await places.nearby(location: _hyderabadCenter, type: type, radius: 1000, limit: 10);
    if (!mounted) return;
    final markers = results.map((p) => AnyMarker(
      id: 'poi_${p.id}',
      position: p.position,
      title: p.name,
      snippet: '${p.distanceText ?? ''} ${p.openingHours != null ? '• ${p.openingHours}' : ''}',
    )).toList();
    setState(() { _nearbyMarkers = markers; _nearbyLoading = false; _allMarkers = [..._landmarks, ...markers]; });
    if (markers.isEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No results found nearby')));
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Found ${markers.length} ${type.name} nearby')));
    }
  }

  void _clearNearby() => setState(() { _nearbyMarkers = []; _allMarkers = List.of(_landmarks); });

  // ── Route Optimizer ──

  Future<void> _optimizeRoute() async {
    setState(() { _optimizerLoading = true; _optimizedRoute = null; });
    final stops = _landmarks.take(4).map((m) => m.position).toList();
    final optimizer = AnyRouteOptimizer();
    final result = await optimizer.optimize(stops: stops);
    if (!mounted) return;
    setState(() => _optimizerLoading = false);
    if (!result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Optimizer failed: ${result.error}')));
      return;
    }
    setState(() {
      _optimizedRoute = result;
      _polylines = [..._polylines.where((p) => !p.id.startsWith('opt_')), result.toPolyline(id: 'opt_route')];
    });
    if (result.bounds != null) _controller?.fitBoundsWithInsets(result.bounds!, insets: const EdgeInsets.all(64));
    final orderStr = result.waypointOrder
        .where((i) => i < _landmarks.length)
        .map((i) => _landmarks[i].title ?? 'Stop $i')
        .join(' → ');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Optimized: ${result.durationText} • ${result.distanceText}\nOrder: $orderStr'),
      duration: const Duration(seconds: 4),
    ));
  }

  // ── Map Matching ──

  Future<void> _runMapMatching() async {
    setState(() => _matcherLoading = true);
    // Simulate noisy GPS trace along Charminar → HITEC City road
    final rawTrace = [
      AnyGpsPoint(position: const AnyLatLng(17.3620, 78.4750), timestamp: 1700000000, accuracy: 20),
      AnyGpsPoint(position: const AnyLatLng(17.3700, 78.4710), timestamp: 1700000030, accuracy: 25),
      AnyGpsPoint(position: const AnyLatLng(17.3800, 78.4680), timestamp: 1700000060, accuracy: 20),
      AnyGpsPoint(position: const AnyLatLng(17.3900, 78.4500), timestamp: 1700000090, accuracy: 30),
      AnyGpsPoint(position: const AnyLatLng(17.4000, 78.4200), timestamp: 1700000120, accuracy: 20),
      AnyGpsPoint(position: const AnyLatLng(17.4200, 78.4000), timestamp: 1700000150, accuracy: 25),
      AnyGpsPoint(position: const AnyLatLng(17.4400, 78.3800), timestamp: 1700000180, accuracy: 20),
    ];
    final matcher = AnyMapMatcher();
    final result = await matcher.match(rawTrace);
    if (!mounted) return;
    setState(() => _matcherLoading = false);
    if (!result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Matching failed: ${result.error}')));
      return;
    }
    final rawPoly = AnyPolyline(id: 'raw_gps', points: rawTrace.map((p) => p.position).toList(), color: const Color(0xFFFF9800), width: 3);
    final snappedPoly = result.toPolyline(id: 'snapped');
    setState(() => _matchedPolylines = [rawPoly, snappedPoly]);
    setState(() => _polylines = [..._polylines.where((p) => !p.id.startsWith('raw_') && !p.id.startsWith('snapped')), rawPoly, snappedPoly]);
    final conf = result.confidence != null ? ' (${(result.confidence! * 100).round()}% confidence)' : '';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Snapped to road$conf — orange=raw GPS, purple=snapped')));
  }

  void _clearMatching() {
    setState(() {
      _matchedPolylines = [];
      _polylines = _polylines.where((p) => !p.id.startsWith('raw_') && !p.id.startsWith('snapped') && !p.id.startsWith('opt_')).toList();
    });
  }

  // ── Advanced Features Sheet ──

  void _showAdvancedSheet() {
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (ctx) => StatefulBuilder(builder: (ctx, setSheetState) {
      return DraggableScrollableSheet(
        initialChildSize: 0.55,
        maxChildSize: 0.85,
        minChildSize: 0.3,
        expand: false,
        builder: (_, scrollCtrl) => SingleChildScrollView(
          controller: scrollCtrl,
          child: Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            Text('Advanced Features', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // Distance Matrix
            _advancedCard(
              icon: Icons.grid_on,
              title: 'Distance Matrix',
              subtitle: 'OSRM Table API — 3×3 travel-time grid in one call',
              isLoading: _matrixLoading,
              onTap: () { Navigator.pop(ctx); _showDistanceMatrix(); },
            ),

            // Nearby POI
            _advancedCard(
              icon: Icons.place_outlined,
              title: 'Nearby Places (Overpass)',
              subtitle: 'Find hospitals, restaurants, ATMs near Hyderabad',
              isLoading: _nearbyLoading,
              trailing: _nearbyMarkers.isNotEmpty ? IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () { Navigator.pop(ctx); _clearNearby(); }) : null,
              onTap: null,
              child: Wrap(spacing: 6, runSpacing: 4, children: [
                for (final type in [AnyPlaceType.hospital, AnyPlaceType.restaurant, AnyPlaceType.atm, AnyPlaceType.fuelStation, AnyPlaceType.pharmacy, AnyPlaceType.hotel])
                  ActionChip(
                    label: Text(type.name, style: const TextStyle(fontSize: 11)),
                    onPressed: _nearbyLoading ? null : () { Navigator.pop(ctx); _findNearbyPlaces(type); },
                  ),
              ]),
            ),

            // Route Optimizer
            _advancedCard(
              icon: Icons.route,
              title: 'Route Optimizer (TSP)',
              subtitle: 'OSRM Trip API — optimal order for 4 Hyderabad stops',
              isLoading: _optimizerLoading,
              trailing: _optimizedRoute != null ? IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () { Navigator.pop(ctx); _clearMatching(); }) : null,
              onTap: () { Navigator.pop(ctx); _optimizeRoute(); },
            ),

            // Map Matching
            _advancedCard(
              icon: Icons.timeline,
              title: 'GPS Map Matching',
              subtitle: 'OSRM Match API — snap noisy GPS trace to roads',
              isLoading: _matcherLoading,
              trailing: _matchedPolylines.isNotEmpty ? IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () { Navigator.pop(ctx); _clearMatching(); }) : null,
              onTap: () { Navigator.pop(ctx); _runMapMatching(); },
            ),

            // AnyPlacesSearchField demo
            const SizedBox(height: 4),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(radius: 18, backgroundColor: Theme.of(context).colorScheme.primaryContainer, child: Icon(Icons.search, size: 18, color: Theme.of(context).colorScheme.primary)),
              title: const Text('AnyPlacesSearchField'),
              subtitle: const Text('Tap the main search bar — it uses the full widget'),
            ),
          ])),
        ),
      );
    }));
  }

  Widget _advancedCard({
    required IconData icon,
    required String title,
    required String subtitle,
    bool isLoading = false,
    VoidCallback? onTap,
    Widget? trailing,
    Widget? child,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            CircleAvatar(radius: 18, backgroundColor: Theme.of(context).colorScheme.primaryContainer, child: isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ])),
                    if (trailing != null) trailing,
            if (onTap != null && trailing == null) const Icon(Icons.chevron_right, size: 18),
          ]),
          if (child != null) ...[const SizedBox(height: 8), child],
        ])),
      ),
    );
  }

  void _startAnimatePolyline() {
    if (_route == null) return;
    final animPoly = AnyAnimatedPolyline(id: 'anim_route', points: _route!.geometry, width: 6.0, color: const Color(0xFF4285F4), animationDuration: const Duration(seconds: 5));
    _animProgress = 0;
    // Clear existing route polylines and animate
    setState(() => _polylines = []);
    _animTimer = Timer.periodic(const Duration(milliseconds: 50), (t) {
      if (!mounted || _animProgress >= 1.0) { t.cancel(); setState(() => _animatingPolyline = false); return; }
      _animProgress += 0.01;
      setState(() => _polylines = [animPoly.toPolylineAt(_animProgress)]);
    });
  }

  void _stopAnimatePolyline() {
    _animTimer?.cancel();
    if (_route != null) {
      setState(() => _polylines = _showTrafficColors && _route!.segments.isNotEmpty ? _route!.toTrafficPolylines(idPrefix: 'route') : [_route!.toPolyline(id: 'route', width: 6.0)]);
    }
  }

  // Compute effective markers including cluster markers
  List<AnyMarker> get _effectiveMarkers {
    var markers = List.of(_allMarkers);
    if (_showClustering) markers = [...markers, ..._clusterMarkers];
    return markers;
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _animTimer?.cancel();
    _searchCtrl.dispose();
    _geoSub?.cancel();
    _cameraSub?.cancel();
    _simLocTimer?.cancel();
    _simLocProvider?.dispose();
    _geoEngine.dispose();
    _rerouter.dispose();
    super.dispose();
  }

  // ── BUILD ──

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Stack(children: [
      Column(children: [
        Expanded(child: AnyMapWidget(
          key: ValueKey('${_backend}_${_mapStyle.name}'),
          adapter: _adapter,
          initialCamera: AnyCameraPosition(target: _hyderabadCenter, zoom: 12, tilt: _is3DView ? 45 : 0),
          markers: _effectiveMarkers.map((m) => m.copyWith(onTap: () => setState(() => _selectedMarker = m))).toList(),
          polylines: _polylines,
          polygons: _showPolygons ? _demoPolygons : const [],
          circles: _showCircles ? _demoCircles : const [],
          onMapCreated: _onMapCreated,
          onTap: (_) { if (_showSearch) setState(() => _showSearch = false); setState(() => _selectedMarker = null); },
          onLongPress: (ll) { _controller?.animateCamera(AnyCameraPosition(target: ll, zoom: 18, tilt: 75)); setState(() => _is3DView = true); },
          myLocationEnabled: false, compassEnabled: true, tiltGesturesEnabled: true, rotateGesturesEnabled: true,
          onError: (err) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Map error: ${err.message}'), backgroundColor: Colors.red));
          },
        )),
        if (_route != null && !_showSearch && !_isNavigating) _buildDirectionsPanel(),
      ]),
      // Top bar
      SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [_buildTopBar(), if (_showSearch) _buildSearchPanel()])),
      // Controls
      Positioned(right: 12, bottom: _route != null && !_isNavigating ? 260 : 24, child: _buildControls()),
      // Nav overlay (Google Maps style)
      if (_isNavigating && _route != null) ...[
        Positioned(top: 0, left: 0, right: 0, child: _buildNavBanner()),
        Positioned(bottom: 0, left: 0, right: 0, child: _buildNavBottomBar()),
      ],
      // Feature 2: User location layer
      if (_showLocationLayer && _simLocProvider != null)
        AnyUserLocationLayer(controller: _controller, locationProvider: _simLocProvider!),
      // Feature 3: Marker popup
      if (_selectedMarker != null)
        AnyMarkerPopup(
          controller: _controller,
          marker: _selectedMarker!,
          onClose: () => setState(() => _selectedMarker = null),
        ),
      // Feature 1: Live zoom badge (camera stream demo)
      Positioned(
        left: 12, bottom: _route != null && !_isNavigating ? 270 : 90,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
          child: Text('z ${_liveZoom.toStringAsFixed(1)}', style: const TextStyle(color: Colors.white, fontSize: 11, fontFamily: 'monospace')),
        ),
      ),
      // Geofence chip
      if (_lastGeoEvent != null && !_isNavigating)
        Positioned(bottom: _route != null ? 290 : 110, left: 12, child: Chip(avatar: const Icon(Icons.fence, size: 16), label: Text(_lastGeoEvent!, style: const TextStyle(fontSize: 11)), onDeleted: () => setState(() => _lastGeoEvent = null))),
    ]));
  }

  // ── Top Bar ──

  Widget _buildTopBar() => Container(
    margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
    decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 8, offset: const Offset(0, 2))]),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      // Search
      Row(children: [
        const SizedBox(width: 12), Icon(Icons.search, color: Theme.of(context).colorScheme.outline), const SizedBox(width: 8),
        Expanded(child: TextField(controller: _searchCtrl, decoration: const InputDecoration(hintText: 'Search places in Hyderabad...', border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 14)), onTap: () => setState(() => _showSearch = true), onChanged: _performSearch)),
        if (_searchCtrl.text.isNotEmpty) IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () { _searchCtrl.clear(); setState(() { _searchResults = []; _showSearch = false; }); }),
        if (_backend == MapBackend.maplibre) PopupMenuButton<MapStyle>(icon: const Icon(Icons.layers_outlined), tooltip: 'Map Style', onSelected: (s) => setState(() { _mapStyle = s; _controller = null; }),
          itemBuilder: (_) => MapStyle.values.map((s) => PopupMenuItem(value: s, child: Row(children: [if (s == _mapStyle) Icon(Icons.check, size: 18, color: Theme.of(context).colorScheme.primary) else const SizedBox(width: 18), const SizedBox(width: 8), Text(s.label)]))).toList()),
        const SizedBox(width: 4),
      ]),
      // Backend + Travel mode
      Padding(padding: const EdgeInsets.fromLTRB(12, 0, 12, 8), child: Row(children: [
        Expanded(child: SegmentedButton<MapBackend>(
          segments: const [ButtonSegment(value: MapBackend.maplibre, label: Text('MapLibre'), icon: Icon(Icons.map, size: 16)), ButtonSegment(value: MapBackend.osm, label: Text('OSM'), icon: Icon(Icons.public, size: 16))],
          selected: {_backend}, onSelectionChanged: (v) => setState(() { _backend = v.first; _controller = null; }),
          style: const ButtonStyle(visualDensity: VisualDensity.compact, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
        )),
      ])),
    ]),
  );

  // ── Search Panel ──

  Widget _buildSearchPanel() => Container(
    margin: const EdgeInsets.fromLTRB(12, 4, 12, 0), constraints: const BoxConstraints(maxHeight: 350),
    decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)]),
    child: _isSearching ? const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
        : _searchResults.isEmpty ? _buildRouteChips()
        : ListView.builder(shrinkWrap: true, padding: EdgeInsets.zero, itemCount: _searchResults.length, itemBuilder: (_, i) {
            final p = _searchResults[i];
            return ListTile(dense: true, leading: Icon(_placeIcon(p.category), color: Theme.of(context).colorScheme.primary), title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis), subtitle: Text(p.address, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall), onTap: () => _goToPlace(p));
          }),
  );

  Widget _buildRouteChips() => Padding(padding: const EdgeInsets.all(12), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
    // Travel mode selector
    Text('Travel Mode', style: Theme.of(context).textTheme.titleSmall),
    const SizedBox(height: 6),
    SegmentedButton<AnyTravelMode>(
      segments: AnyTravelMode.values.map((m) => ButtonSegment(value: m, icon: Icon(_modeIcon(m), size: 18), label: Text(m.name[0].toUpperCase() + m.name.substring(1), style: const TextStyle(fontSize: 11)))).toList(),
      selected: {_travelMode}, onSelectionChanged: (v) => setState(() => _travelMode = v.first),
      style: const ButtonStyle(visualDensity: VisualDensity.compact, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
    ),
    const SizedBox(height: 12),
    // Routes
    Text('Popular Routes', style: Theme.of(context).textTheme.titleSmall),
    const SizedBox(height: 6),
    Wrap(spacing: 8, runSpacing: 8, children: _routeOptions.map((r) => ActionChip(avatar: const Icon(Icons.directions, size: 16), label: Text(r.label, style: const TextStyle(fontSize: 11)), onPressed: () { setState(() => _showSearch = false); _computeRoute(r); })).toList()),
    const SizedBox(height: 8),
    Text('Long-press map for street-level view', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline)),
  ]));

  // ── Controls ──

  Widget _buildControls() => Column(mainAxisSize: MainAxisSize.min, children: [
    // Advanced features sheet
    FloatingActionButton.small(heroTag: 'advanced', onPressed: _showAdvancedSheet, tooltip: 'Advanced Features', child: const Icon(Icons.science_outlined, size: 20)),
    const SizedBox(height: 8),
    // Layers toggle sheet
    FloatingActionButton.small(heroTag: 'layers_sheet', onPressed: _toggleLayerSheet, tooltip: 'Layers', child: const Icon(Icons.stacked_line_chart, size: 20)),
    const SizedBox(height: 8),
    if (_backend == MapBackend.maplibre) FloatingActionButton.small(heroTag: '3d', onPressed: () { setState(() => _is3DView = !_is3DView); _controller?.animateCamera(AnyCameraPosition(target: _hyderabadCenter, zoom: _is3DView ? 16 : 13, tilt: _is3DView ? 60 : 0, bearing: _is3DView ? 30 : 0)); }, child: Text(_is3DView ? '2D' : '3D', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
    const SizedBox(height: 8),
    if (_route != null) FloatingActionButton.small(heroTag: 'traffic', onPressed: _toggleTrafficColors, backgroundColor: _showTrafficColors ? Colors.green : null, child: const Icon(Icons.traffic, size: 20)),
    if (_route != null) const SizedBox(height: 8),
    FloatingActionButton.small(heroTag: 'fit', onPressed: () { if (_route != null) { _controller?.fitBounds(_route!.bounds, padding: 80); } else { _controller?.fitBounds(AnyLatLngBounds.fromPoints(_landmarks.map((m) => m.position).toList()), padding: 64); } }, child: const Icon(Icons.fit_screen, size: 20)),
    if (_route != null) ...[
      const SizedBox(height: 8),
      FloatingActionButton.small(heroTag: 'nav', backgroundColor: _isNavigating ? Colors.red : Theme.of(context).colorScheme.primary, foregroundColor: Colors.white, onPressed: _isNavigating ? _stopNavigation : _startNavigation, child: Icon(_isNavigating ? Icons.stop : Icons.navigation, size: 20)),
      const SizedBox(height: 8),
      FloatingActionButton.small(heroTag: 'clear', onPressed: _clearRoute, child: const Icon(Icons.close, size: 20)),
    ],
    if (_route == null) ...[
      const SizedBox(height: 8),
      FloatingActionButton.extended(heroTag: 'route', onPressed: _isRouting ? null : () => _computeRoute(_routeOptions.first),
        icon: _isRouting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.directions, size: 18),
        label: Text(_isRouting ? 'Loading...' : 'Route', style: const TextStyle(fontSize: 13))),
    ],
  ]);

  // ── Navigation Banner (Google Maps style green bar) ──

  Widget _buildNavBanner() {
    final steps = _route!.steps;
    final step = steps.isNotEmpty && _currentStepIndex < steps.length ? steps[_currentStepIndex] : null;
    final next = steps.isNotEmpty && _currentStepIndex + 1 < steps.length ? steps[_currentStepIndex + 1] : null;
    if (step == null) return const SizedBox.shrink();

    return SafeArea(child: Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      decoration: BoxDecoration(color: const Color(0xFF1B873B), borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))]),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Main instruction
        Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 8), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(_maneuverIcon(step.maneuver), size: 48, color: Colors.white),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (step.distanceMeters > 0) Text(_fmtDist(step.distanceMeters), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, height: 1.1)),
            const SizedBox(height: 2),
            Text(step.roadName?.isNotEmpty == true ? step.roadName! : step.instruction, style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis),
            if (step.roadRef != null) Text(step.roadRef!, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7))),
          ])),
          // Speed limit
          if (step.speedLimit != null) Container(width: 44, height: 44, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white, border: Border.all(color: Colors.red, width: 3)), child: Center(child: Text('${step.speedLimit!.speedKmh.round()}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))),
        ])),
        // Lane guidance
        if (step.lanes.isNotEmpty) Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), color: Colors.black.withValues(alpha: 0.15),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: step.lanes.map((l) => Container(margin: const EdgeInsets.symmetric(horizontal: 2), padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3), decoration: BoxDecoration(color: l.isActive ? Colors.white : Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
            child: Icon(l.directions.contains('left') ? Icons.arrow_back : l.directions.contains('right') ? Icons.arrow_forward : Icons.arrow_upward, size: 14, color: l.isActive ? const Color(0xFF1B873B) : Colors.white.withValues(alpha: 0.5)))).toList())),
        // Bridge/tunnel/toll alert
        if (step.annotation?.isBridge == true || step.annotation?.isTunnel == true || step.annotation?.isToll == true)
          Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), color: Colors.amber.shade700,
            child: Row(children: [const Icon(Icons.info_outline, size: 14, color: Colors.white), const SizedBox(width: 6),
              if (step.annotation?.isBridge == true) const Text('Flyover ahead  ', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
              if (step.annotation?.isTunnel == true) const Text('Tunnel ahead  ', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
              if (step.annotation?.isToll == true) const Text('Toll road  ', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold))])),
        // "Then" preview
        if (next != null) Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: const BoxDecoration(color: Color(0xFF145A28), borderRadius: BorderRadius.only(bottomLeft: Radius.circular(14), bottomRight: Radius.circular(14))),
          child: Row(children: [const Text('Then  ', style: TextStyle(fontSize: 13, color: Colors.white70)), Icon(_maneuverIcon(next.maneuver), size: 18, color: Colors.white70), const SizedBox(width: 6), Expanded(child: Text(next.roadName?.isNotEmpty == true ? next.roadName! : next.instruction, style: const TextStyle(fontSize: 13, color: Colors.white70), maxLines: 1, overflow: TextOverflow.ellipsis))])),
      ]),
    ));
  }

  // ── Navigation Bottom Bar ──

  Widget _buildNavBottomBar() {
    final p = _route!.geometry.isNotEmpty ? _navIndex / _route!.geometry.length : 0.0;
    final rd = _route!.distanceMeters * (1.0 - p);
    final rt = _route!.durationSeconds * (1.0 - p);
    final eta = DateTime.now().add(Duration(seconds: rt.round()));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 6, offset: const Offset(0, -2))]),
      child: SafeArea(top: false, child: Row(children: [
        IconButton(icon: const Icon(Icons.close), iconSize: 28, onPressed: _stopNavigation, style: IconButton.styleFrom(backgroundColor: Colors.grey.shade200)),
        const Spacer(),
        Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_fmtTime(rt), style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green.shade700)),
          Text('${_fmtDist(rd)}  \u2022  ${eta.hour}:${eta.minute.toString().padLeft(2, '0')}', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        ]),
        const Spacer(),
        IconButton(icon: const Icon(Icons.my_location), iconSize: 28, onPressed: () { if (_route != null && _navIndex < _route!.geometry.length) _controller?.moveCamera(AnyCameraPosition(target: _route!.geometry[_navIndex], zoom: 17.5, tilt: 65, bearing: _navBearing)); }, style: IconButton.styleFrom(backgroundColor: Colors.grey.shade200)),
      ])),
    );
  }

  // ── Directions Panel ──

  Widget _buildDirectionsPanel() {
    final r = _route!;
    return Container(
      constraints: const BoxConstraints(maxHeight: 220),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, -2))]),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Header
        Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), color: Theme.of(context).colorScheme.primaryContainer,
          child: Row(children: [
            Icon(_modeIcon(_travelMode), color: Theme.of(context).colorScheme.onPrimaryContainer, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${r.durationText}  \u2022  ${r.distanceText}', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold)),
              Row(children: [
                Text('${r.steps.length} steps \u2022 ${_travelMode.name}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.7))),
                if (r.hasBridges) _badge('Flyover', Colors.blue), if (r.hasTunnels) _badge('Tunnel', Colors.grey), if (r.hasTolls) _badge('Toll', Colors.orange),
              ]),
            ])),
            IconButton(icon: const Icon(Icons.navigation), onPressed: _startNavigation, color: Theme.of(context).colorScheme.onPrimaryContainer),
            IconButton(icon: const Icon(Icons.close, size: 20), onPressed: _clearRoute, color: Theme.of(context).colorScheme.onPrimaryContainer),
          ])),
        // Steps
        Flexible(child: ListView.separated(padding: EdgeInsets.zero, itemCount: r.steps.length, separatorBuilder: (_, _) => const Divider(height: 1), itemBuilder: (_, i) {
          final s = r.steps[i]; final active = i == _currentStepIndex && _isNavigating;
          return ListTile(dense: true, selected: active, selectedTileColor: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
            leading: CircleAvatar(radius: 14, backgroundColor: active ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5), child: Icon(_maneuverIcon(s.maneuver), size: 16, color: active ? Colors.white : Theme.of(context).colorScheme.primary)),
            title: Text(s.instruction, style: Theme.of(context).textTheme.bodyMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
            subtitle: Row(children: [
              if (s.annotation?.isBridge == true) const Padding(padding: EdgeInsets.only(right: 4), child: Icon(Icons.move_up, size: 12, color: Colors.blue)),
              if (s.annotation?.isTunnel == true) const Padding(padding: EdgeInsets.only(right: 4), child: Icon(Icons.subway, size: 12, color: Colors.grey)),
              if (s.speedLimit != null) Text('${s.speedLimit!.speedKmh.round()} km/h', style: const TextStyle(fontSize: 10, color: Colors.red)),
              if (s.lanes.isNotEmpty) Text(' \u2022 ${s.lanes.where((l) => l.isActive).length} lanes', style: const TextStyle(fontSize: 10, color: Colors.grey)),
              if (s.roadRef != null) Text(' \u2022 ${s.roadRef}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ]),
            trailing: s.distanceMeters > 0 ? Text(_fmtDist(s.distanceMeters), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline)) : null,
            onTap: () => _controller?.animateCamera(AnyCameraPosition(target: s.startLocation, zoom: 16, tilt: _is3DView ? 45 : 0)),
          );
        })),
      ]),
    );
  }

  Widget _badge(String t, Color c) => Container(margin: const EdgeInsets.only(left: 6), padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1), decoration: BoxDecoration(color: c.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)), child: Text(t, style: TextStyle(fontSize: 9, color: c, fontWeight: FontWeight.bold)));
}

// ── Simulated location provider for demo ──

/// A demo [AnyLocationProvider] that slowly moves a location around
/// Hyderabad for the [AnyUserLocationLayer] demonstration.
class _SimLocationProvider extends AnyLocationProvider {
  final AnyLatLng center;
  final _controller = StreamController<AnyUserLocation>.broadcast();
  Timer? _timer;
  double _angle = 0;

  _SimLocationProvider({required this.center});

  @override
  Stream<AnyUserLocation> get locationStream => _controller.stream;

  @override
  Future<void> startUpdates({Duration interval = const Duration(seconds: 1), double distanceFilter = 5.0}) async {
    _timer = Timer.periodic(const Duration(milliseconds: 800), (_) {
      _angle = (_angle + 3) % 360;
      final rad = _angle * math.pi / 180;
      final lat = center.latitude + math.sin(rad) * 0.005;
      final lng = center.longitude + math.cos(rad) * 0.005;
      _controller.add(AnyUserLocation(
        position: AnyLatLng(lat, lng),
        heading: _angle,
        accuracy: 12,
        speed: 8.3,
        timestamp: DateTime.now(),
      ));
    });
  }

  @override
  Future<void> stopUpdates() async => _timer?.cancel();

  @override
  Future<AnyUserLocation?> getLastLocation() async => null;

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<bool> isServiceEnabled() async => true;

  @override
  void dispose() {
    _timer?.cancel();
    _controller.close();
  }
}
