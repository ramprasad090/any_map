import '../models/lat_lng.dart';

/// A recorded trip waypoint.
class AnyTripWaypoint {
  /// Geographic position of this waypoint.
  final AnyLatLng position;

  /// Speed in meters per second at this waypoint.
  final double? speed;

  /// Compass heading in degrees at this waypoint.
  final double? heading;

  /// Time at which this waypoint was recorded.
  final DateTime timestamp;

  const AnyTripWaypoint({
    required this.position,
    this.speed,
    this.heading,
    required this.timestamp,
  });
}

/// Driving behavior event type.
enum AnyDrivingEvent {
  /// Sudden hard braking detected.
  harshBraking,

  /// Sudden hard acceleration detected.
  harshAcceleration,

  /// Aggressive cornering detected.
  harshCornering,

  /// Driving above the speed limit.
  speeding,

  /// Vehicle stationary with engine running.
  idling,
}

/// A driving behavior event.
class AnyDrivingBehaviorEvent {
  /// Type of driving behavior event.
  final AnyDrivingEvent type;

  /// Location where the event occurred.
  final AnyLatLng position;

  /// Time at which the event occurred.
  final DateTime timestamp;

  /// Severity of the event (0.0 to 1.0).
  final double? severity;

  const AnyDrivingBehaviorEvent({
    required this.type,
    required this.position,
    required this.timestamp,
    this.severity,
  });
}

/// Summary of a completed trip.
class AnyTripSummary {
  /// Total distance in meters.
  final double distanceMeters;

  /// Total duration in seconds.
  final double durationSeconds;

  /// Average speed in m/s.
  final double averageSpeed;

  /// Maximum speed in m/s.
  final double maxSpeed;

  /// Estimated fuel consumed in liters.
  final double? fuelConsumedLiters;

  /// Estimated CO2 emitted in grams.
  final double? co2EmittedGrams;

  /// Driving behavior events.
  final List<AnyDrivingBehaviorEvent> events;

  /// Eco driving score (0 to 100).
  final int? ecoScore;

  /// All recorded waypoints.
  final List<AnyTripWaypoint> waypoints;

  /// Start time.
  final DateTime startTime;

  /// End time.
  final DateTime endTime;

  const AnyTripSummary({
    required this.distanceMeters,
    required this.durationSeconds,
    required this.averageSpeed,
    required this.maxSpeed,
    this.fuelConsumedLiters,
    this.co2EmittedGrams,
    this.events = const [],
    this.ecoScore,
    this.waypoints = const [],
    required this.startTime,
    required this.endTime,
  });

  /// Distance in km.
  double get distanceKm => distanceMeters / 1000;

  /// Duration as formatted text.
  String get durationText {
    final mins = (durationSeconds / 60).round();
    if (mins >= 60) {
      return '${mins ~/ 60}h ${mins % 60}m';
    }
    return '$mins min';
  }

  /// Average speed in km/h.
  double get averageSpeedKmh => averageSpeed * 3.6;

  /// Harsh braking count.
  int get harshBrakingCount =>
      events.where((e) => e.type == AnyDrivingEvent.harshBraking).length;

  /// Harsh acceleration count.
  int get harshAccelerationCount =>
      events.where((e) => e.type == AnyDrivingEvent.harshAcceleration).length;

  /// Speeding duration in seconds.
  int get speedingCount =>
      events.where((e) => e.type == AnyDrivingEvent.speeding).length;
}

/// Fuel estimation configuration.
class AnyFuelConfig {
  /// Fuel type.
  final AnyFuelType fuelType;

  /// Average consumption in liters per 100 km.
  final double consumptionPer100km;

  /// CO2 emission factor (grams per liter of fuel).
  final double co2GramsPerLiter;

  const AnyFuelConfig({
    this.fuelType = AnyFuelType.petrol,
    this.consumptionPer100km = 8.0,
    double? co2GramsPerLiter,
  }) : co2GramsPerLiter = co2GramsPerLiter ??
            (fuelType == AnyFuelType.diesel ? 2640.0 : 2310.0);

  /// Estimate fuel for a distance in meters.
  double estimateFuelLiters(double distanceMeters) {
    return (distanceMeters / 1000) * consumptionPer100km / 100;
  }

  /// Estimate CO2 emissions for a distance in meters.
  double estimateCO2Grams(double distanceMeters) {
    return estimateFuelLiters(distanceMeters) * co2GramsPerLiter;
  }
}

/// Fuel type.
enum AnyFuelType {
  /// Petrol / gasoline fuel.
  petrol,

  /// Diesel fuel.
  diesel,

  /// Electric vehicle (battery-powered).
  electric,

  /// Hybrid (petrol + electric).
  hybrid,

  /// Compressed natural gas.
  cng,

  /// Liquefied petroleum gas.
  lpg,
}

/// Records trip data and computes analytics.
class AnyTripLogger {
  final List<AnyTripWaypoint> _waypoints = [];
  final List<AnyDrivingBehaviorEvent> _events = [];
  /// Optional fuel configuration for consumption and emissions estimates.
  final AnyFuelConfig? fuelConfig;

  DateTime? _startTime;
  double _totalDistance = 0;
  double _maxSpeed = 0;
  double? _prevSpeed;
  AnyLatLng? _prevPosition;
  DateTime? _prevTimestamp;

  /// Whether a trip is currently being recorded.
  bool get isRecording => _startTime != null;

  /// Creates a trip logger with an optional fuel configuration.
  AnyTripLogger({this.fuelConfig});

  /// Start recording.
  void start() {
    _startTime = DateTime.now();
    _waypoints.clear();
    _events.clear();
    _totalDistance = 0;
    _maxSpeed = 0;
    _prevSpeed = null;
    _prevPosition = null;
    _prevTimestamp = null;
  }

  /// Record a location update.
  void addWaypoint(AnyTripWaypoint waypoint) {
    if (_startTime == null) return;
    _waypoints.add(waypoint);

    // Update distance
    if (_prevPosition != null) {
      _totalDistance += _prevPosition!.distanceTo(waypoint.position);
    }

    // Update max speed
    if (waypoint.speed != null && waypoint.speed! > _maxSpeed) {
      _maxSpeed = waypoint.speed!;
    }

    // Detect harsh braking / acceleration
    if (_prevSpeed != null &&
        waypoint.speed != null &&
        _prevTimestamp != null) {
      final dt = waypoint.timestamp.difference(_prevTimestamp!).inMilliseconds /
          1000.0;
      if (dt > 0) {
        final accel = (waypoint.speed! - _prevSpeed!) / dt;
        if (accel < -4.0) {
          // > 4 m/s² deceleration
          _events.add(AnyDrivingBehaviorEvent(
            type: AnyDrivingEvent.harshBraking,
            position: waypoint.position,
            timestamp: waypoint.timestamp,
            severity: (accel.abs() / 10).clamp(0, 1),
          ));
        } else if (accel > 4.0) {
          _events.add(AnyDrivingBehaviorEvent(
            type: AnyDrivingEvent.harshAcceleration,
            position: waypoint.position,
            timestamp: waypoint.timestamp,
            severity: (accel / 10).clamp(0, 1),
          ));
        }
      }
    }

    _prevSpeed = waypoint.speed;
    _prevPosition = waypoint.position;
    _prevTimestamp = waypoint.timestamp;
  }

  /// Stop recording and return the trip summary.
  AnyTripSummary stop() {
    final endTime = DateTime.now();
    final duration = _startTime != null
        ? endTime.difference(_startTime!).inSeconds.toDouble()
        : 0.0;
    final avgSpeed = duration > 0 ? _totalDistance / duration : 0.0;

    final summary = AnyTripSummary(
      distanceMeters: _totalDistance,
      durationSeconds: duration,
      averageSpeed: avgSpeed,
      maxSpeed: _maxSpeed,
      fuelConsumedLiters: fuelConfig?.estimateFuelLiters(_totalDistance),
      co2EmittedGrams: fuelConfig?.estimateCO2Grams(_totalDistance),
      events: List.of(_events),
      ecoScore: _computeEcoScore(),
      waypoints: List.of(_waypoints),
      startTime: _startTime ?? endTime,
      endTime: endTime,
    );

    _startTime = null;
    return summary;
  }

  int _computeEcoScore() {
    // Simple scoring: start at 100, deduct for harsh events
    int score = 100;
    for (final e in _events) {
      switch (e.type) {
        case AnyDrivingEvent.harshBraking:
          score -= 5;
        case AnyDrivingEvent.harshAcceleration:
          score -= 5;
        case AnyDrivingEvent.harshCornering:
          score -= 3;
        case AnyDrivingEvent.speeding:
          score -= 2;
        case AnyDrivingEvent.idling:
          score -= 1;
      }
    }
    return score.clamp(0, 100);
  }
}
