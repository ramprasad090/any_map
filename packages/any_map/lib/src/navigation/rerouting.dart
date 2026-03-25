import 'dart:async';
import '../models/lat_lng.dart';
import '../routing/route.dart';
import '../routing/routing_provider.dart';

/// Rerouting configuration.
class AnyRerouteConfig {
  /// Distance from route in meters before triggering reroute.
  final double deviationThreshold;

  /// Minimum time between reroute attempts.
  final Duration cooldown;

  /// Maximum number of consecutive reroute attempts.
  final int maxAttempts;

  const AnyRerouteConfig({
    this.deviationThreshold = 50.0,
    this.cooldown = const Duration(seconds: 10),
    this.maxAttempts = 3,
  });
}

/// Event emitted when a reroute occurs.
class AnyRerouteEvent {
  /// The new route.
  final AnyRoute newRoute;

  /// The old route.
  final AnyRoute oldRoute;

  /// Where the user was when rerouted.
  final AnyLatLng position;

  /// Reason for rerouting.
  final String reason;

  const AnyRerouteEvent({
    required this.newRoute,
    required this.oldRoute,
    required this.position,
    required this.reason,
  });
}

/// Monitors user position and triggers rerouting when off-route.
class AnyRerouteEngine {
  final AnyRoutingProvider _provider;

  /// Configuration for rerouting behavior.
  final AnyRerouteConfig config;

  AnyRoute? _currentRoute;
  AnyRouteRequest? _currentRequest;
  DateTime? _lastRerouteTime;
  int _consecutiveAttempts = 0;

  final _controller = StreamController<AnyRerouteEvent>.broadcast();

  /// Stream of reroute events.
  Stream<AnyRerouteEvent> get events => _controller.stream;

  /// Creates a reroute engine with the given routing provider and config.
  AnyRerouteEngine({
    required AnyRoutingProvider provider,
    this.config = const AnyRerouteConfig(),
  }) : _provider = provider;

  /// Set the active route and request.
  void setRoute(AnyRoute route, AnyRouteRequest request) {
    _currentRoute = route;
    _currentRequest = request;
    _consecutiveAttempts = 0;
  }

  /// Clear the active route.
  void clearRoute() {
    _currentRoute = null;
    _currentRequest = null;
    _consecutiveAttempts = 0;
  }

  /// Call with each location update. Returns true if a reroute was triggered.
  Future<bool> updateLocation(AnyLatLng position) async {
    if (_currentRoute == null || _currentRequest == null) return false;

    // Check deviation from route
    final deviation = _minDistanceToRoute(position, _currentRoute!.geometry);
    if (deviation <= config.deviationThreshold) {
      _consecutiveAttempts = 0;
      return false;
    }

    // Check cooldown
    if (_lastRerouteTime != null &&
        DateTime.now().difference(_lastRerouteTime!) < config.cooldown) {
      return false;
    }

    // Check max attempts
    if (_consecutiveAttempts >= config.maxAttempts) return false;

    // Trigger reroute
    _consecutiveAttempts++;
    _lastRerouteTime = DateTime.now();

    final newRequest = AnyRouteRequest(
      origin: position,
      destination: _currentRequest!.destination,
      waypoints: _currentRequest!.waypoints,
      mode: _currentRequest!.mode,
      avoidTolls: _currentRequest!.avoidTolls,
      avoidHighways: _currentRequest!.avoidHighways,
      avoidFerries: _currentRequest!.avoidFerries,
      includeSpeedLimits: _currentRequest!.includeSpeedLimits,
      includeAnnotations: _currentRequest!.includeAnnotations,
      language: _currentRequest!.language,
    );

    final result = await _provider.getRoute(newRequest);
    if (result.isSuccess) {
      final oldRoute = _currentRoute!;
      _currentRoute = result.route;
      _currentRequest = newRequest;
      _consecutiveAttempts = 0;

      _controller.add(AnyRerouteEvent(
        newRoute: result.route!,
        oldRoute: oldRoute,
        position: position,
        reason: 'Deviated ${deviation.round()}m from route',
      ));
      return true;
    }

    return false;
  }

  double _minDistanceToRoute(AnyLatLng point, List<AnyLatLng> geometry) {
    double minDist = double.infinity;
    for (final p in geometry) {
      final d = point.distanceTo(p);
      if (d < minDist) minDist = d;
    }
    return minDist;
  }

  /// Dispose resources and close the event stream.
  void dispose() {
    _controller.close();
  }
}
