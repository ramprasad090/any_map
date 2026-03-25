import 'dart:async';
import '../models/lat_lng.dart';

/// A geofence event type.
enum AnyGeofenceEvent {
  /// User entered the geofence region.
  enter,

  /// User exited the geofence region.
  exit,

  /// User has been dwelling inside the geofence region.
  dwell,
}

/// A geofence trigger.
class AnyGeofenceTrigger {
  /// The geofence that was triggered.
  final AnyGeofence geofence;

  /// What happened.
  final AnyGeofenceEvent event;

  /// Where the user was when the event triggered.
  final AnyLatLng position;

  /// When the event occurred.
  final DateTime timestamp;

  const AnyGeofenceTrigger({
    required this.geofence,
    required this.event,
    required this.position,
    required this.timestamp,
  });
}

/// A geofence region.
class AnyGeofence {
  /// Unique identifier.
  final String id;

  /// Display label.
  final String? label;

  /// Center of the geofence.
  final AnyLatLng center;

  /// Radius in meters (for circular geofences).
  final double radius;

  /// For polygon geofences, the boundary points.
  /// If non-empty, takes precedence over center/radius.
  final List<AnyLatLng> polygon;

  /// Minimum dwell time to trigger a dwell event.
  final Duration dwellTime;

  /// Custom metadata.
  final Map<String, dynamic>? metadata;

  const AnyGeofence({
    required this.id,
    this.label,
    required this.center,
    this.radius = 100,
    this.polygon = const [],
    this.dwellTime = const Duration(minutes: 2),
    this.metadata,
  });

  /// Check if a point is inside this geofence.
  bool contains(AnyLatLng point) {
    if (polygon.isNotEmpty) return _pointInPolygon(point, polygon);
    return center.distanceTo(point) <= radius;
  }

  static bool _pointInPolygon(AnyLatLng point, List<AnyLatLng> polygon) {
    bool inside = false;
    int j = polygon.length - 1;
    for (int i = 0; i < polygon.length; i++) {
      final pi = polygon[i];
      final pj = polygon[j];
      if ((pi.latitude > point.latitude) != (pj.latitude > point.latitude) &&
          point.longitude <
              (pj.longitude - pi.longitude) *
                      (point.latitude - pi.latitude) /
                      (pj.latitude - pi.latitude) +
                  pi.longitude) {
        inside = !inside;
      }
      j = i;
    }
    return inside;
  }
}

/// Monitors user location against registered geofences.
class AnyGeofenceEngine {
  final List<AnyGeofence> _geofences = [];
  final Set<String> _insideIds = {};
  final Map<String, DateTime> _enterTimes = {};
  final _controller = StreamController<AnyGeofenceTrigger>.broadcast();

  /// Stream of geofence events.
  Stream<AnyGeofenceTrigger> get events => _controller.stream;

  /// Register a geofence.
  void addGeofence(AnyGeofence geofence) {
    _geofences.add(geofence);
  }

  /// Remove a geofence by ID.
  void removeGeofence(String id) {
    _geofences.removeWhere((g) => g.id == id);
    _insideIds.remove(id);
    _enterTimes.remove(id);
  }

  /// Remove all geofences.
  void clearGeofences() {
    _geofences.clear();
    _insideIds.clear();
    _enterTimes.clear();
  }

  /// Call this with each new location update.
  void updateLocation(AnyLatLng position) {
    final now = DateTime.now();

    for (final fence in _geofences) {
      final isInside = fence.contains(position);
      final wasInside = _insideIds.contains(fence.id);

      if (isInside && !wasInside) {
        // Enter event
        _insideIds.add(fence.id);
        _enterTimes[fence.id] = now;
        _controller.add(AnyGeofenceTrigger(
          geofence: fence,
          event: AnyGeofenceEvent.enter,
          position: position,
          timestamp: now,
        ));
      } else if (!isInside && wasInside) {
        // Exit event
        _insideIds.remove(fence.id);
        _enterTimes.remove(fence.id);
        _controller.add(AnyGeofenceTrigger(
          geofence: fence,
          event: AnyGeofenceEvent.exit,
          position: position,
          timestamp: now,
        ));
      } else if (isInside && wasInside) {
        // Check for dwell
        final enterTime = _enterTimes[fence.id];
        if (enterTime != null &&
            now.difference(enterTime) >= fence.dwellTime) {
          _controller.add(AnyGeofenceTrigger(
            geofence: fence,
            event: AnyGeofenceEvent.dwell,
            position: position,
            timestamp: now,
          ));
          // Reset to avoid repeated dwell events
          _enterTimes[fence.id] = now;
        }
      }
    }
  }

  /// Dispose the engine.
  void dispose() {
    _controller.close();
  }
}
