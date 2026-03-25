import '../models/models.dart';
import 'route.dart';

/// Travel mode for routing.
enum AnyTravelMode {
  /// Route by car or motor vehicle.
  driving,

  /// Route on foot.
  walking,

  /// Route by bicycle.
  cycling,

  /// Route using public transit.
  transit,
}

/// Vehicle type for specialized routing (truck, EV, etc.).
enum AnyVehicleType {
  /// Standard passenger car.
  car,

  /// Heavy goods vehicle / truck (may use height/weight/width/length constraints).
  truck,

  /// Bicycle.
  bicycle,

  /// Pedestrian / on foot.
  pedestrian,

  /// Electric vehicle (may use battery and consumption parameters).
  electricVehicle,
}

/// Options for a routing request.
class AnyRouteRequest {
  /// Starting point.
  final AnyLatLng origin;

  /// Destination point.
  final AnyLatLng destination;

  /// Optional waypoints between origin and destination.
  final List<AnyLatLng> waypoints;

  /// Travel mode.
  final AnyTravelMode mode;

  /// Vehicle type for specialized routing.
  final AnyVehicleType vehicleType;

  /// Whether to request alternative routes.
  final bool alternatives;

  /// Language for instructions (e.g. "en", "es", "de").
  final String? language;

  /// Avoid toll roads.
  final bool avoidTolls;

  /// Avoid highways / motorways.
  final bool avoidHighways;

  /// Avoid ferries.
  final bool avoidFerries;

  /// Request speed limit annotations.
  final bool includeSpeedLimits;

  /// Request road class annotations (bridge, tunnel, toll, etc.).
  final bool includeAnnotations;

  /// Departure time for time-aware routing (traffic prediction).
  final DateTime? departureTime;

  // ── Truck-specific ──

  /// Truck height in meters (for bridge clearance).
  final double? truckHeight;

  /// Truck weight in metric tons.
  final double? truckWeight;

  /// Truck width in meters.
  final double? truckWidth;

  /// Truck length in meters.
  final double? truckLength;

  // ── EV-specific ──

  /// Current battery charge as percentage (0.0 to 1.0).
  final double? evBatteryLevel;

  /// Battery capacity in kWh.
  final double? evBatteryCapacity;

  /// Average consumption in kWh per 100 km.
  final double? evConsumptionPer100km;

  const AnyRouteRequest({
    required this.origin,
    required this.destination,
    this.waypoints = const [],
    this.mode = AnyTravelMode.driving,
    this.vehicleType = AnyVehicleType.car,
    this.alternatives = false,
    this.language,
    this.avoidTolls = false,
    this.avoidHighways = false,
    this.avoidFerries = false,
    this.includeSpeedLimits = false,
    this.includeAnnotations = false,
    this.departureTime,
    this.truckHeight,
    this.truckWeight,
    this.truckWidth,
    this.truckLength,
    this.evBatteryLevel,
    this.evBatteryCapacity,
    this.evConsumptionPer100km,
  });
}

/// Abstract routing provider. Implement this for each routing backend.
///
/// Built-in implementations:
/// - [OsrmRoutingProvider] — free, self-hostable
/// - [ValhallaRoutingProvider] — free, self-hostable
/// - [GraphHopperRoutingProvider] — API key required
abstract class AnyRoutingProvider {
  /// Compute a route for the given request.
  Future<AnyRouteResult> getRoute(AnyRouteRequest request);

  /// Human-readable name of this provider (e.g. "OSRM").
  String get name;
}

/// Result of a routing request.
class AnyRouteResult {
  /// The primary route (shortest/fastest).
  final AnyRoute? route;

  /// Alternative routes, if requested.
  final List<AnyRoute> alternatives;

  /// Error message if routing failed.
  final String? error;

  /// Whether the request was successful.
  bool get isSuccess => route != null;

  const AnyRouteResult({
    this.route,
    this.alternatives = const [],
    this.error,
  });

  /// Creates a successful result with a primary [route] and optional [alternatives].
  const AnyRouteResult.success({
    required AnyRoute this.route,
    this.alternatives = const [],
  }) : error = null;

  /// Creates a failed result with an [error] message.
  const AnyRouteResult.failure(String this.error)
      : route = null,
        alternatives = const [];
}
