import '../models/lat_lng.dart';
import '../models/lat_lng_bounds.dart';
import '../routing/route.dart';

/// A traffic incident on the road.
class AnyTrafficIncident {
  /// Unique identifier for the incident.
  final String id;

  /// Type of incident.
  final AnyIncidentType type;

  /// Severity (0 = minor, 3 = critical).
  final int severity;

  /// Human-readable description.
  final String description;

  /// Location of the incident.
  final AnyLatLng position;

  /// Start of the affected road segment.
  final AnyLatLng? from;

  /// End of the affected road segment.
  final AnyLatLng? to;

  /// Estimated delay in seconds caused by this incident.
  final double? delaySeconds;

  /// Road name where the incident occurs.
  final String? roadName;

  /// When the incident was reported.
  final DateTime? reportedAt;

  /// When the incident is expected to clear.
  final DateTime? expectedClearAt;

  const AnyTrafficIncident({
    required this.id,
    required this.type,
    this.severity = 1,
    required this.description,
    required this.position,
    this.from,
    this.to,
    this.delaySeconds,
    this.roadName,
    this.reportedAt,
    this.expectedClearAt,
  });
}

/// Types of traffic incidents.
enum AnyIncidentType {
  /// Traffic jam or congestion.
  jam,

  /// Vehicle accident.
  accident,

  /// Road construction or maintenance.
  roadwork,

  /// Road closure.
  closure,

  /// Road hazard (debris, obstacle, etc.).
  hazard,

  /// Weather-related incident.
  weather,

  /// Other or unclassified incident.
  other,
}

/// Traffic flow data for a road segment.
class AnyTrafficFlow {
  /// Segment start.
  final AnyLatLng start;

  /// Segment end.
  final AnyLatLng end;

  /// Current speed in km/h.
  final double currentSpeedKmh;

  /// Free flow speed in km/h.
  final double freeFlowSpeedKmh;

  /// Congestion level.
  final AnyCongestionLevel congestion;

  /// Road name.
  final String? roadName;

  const AnyTrafficFlow({
    required this.start,
    required this.end,
    required this.currentSpeedKmh,
    required this.freeFlowSpeedKmh,
    required this.congestion,
    this.roadName,
  });

  /// Congestion ratio (0.0 = blocked, 1.0 = free flow).
  double get flowRatio =>
      freeFlowSpeedKmh > 0 ? currentSpeedKmh / freeFlowSpeedKmh : 0;
}

/// Abstract traffic data provider.
///
/// Implement this for real-time traffic backends (TomTom, HERE, etc.).
abstract class AnyTrafficProvider {
  /// Human-readable name of the traffic provider.
  String get name;

  /// Fetch traffic incidents within the given bounds.
  Future<List<AnyTrafficIncident>> getIncidents(AnyLatLngBounds bounds);

  /// Fetch traffic flow data within the given bounds.
  Future<List<AnyTrafficFlow>> getFlow(AnyLatLngBounds bounds);
}
