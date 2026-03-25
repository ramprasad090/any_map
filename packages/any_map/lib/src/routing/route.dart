import 'dart:ui' show Color;

import '../models/models.dart';

/// Congestion level for a route segment.
enum AnyCongestionLevel {
  /// Congestion level is not known.
  unknown,

  /// Traffic is flowing freely.
  freeFlow,

  /// Traffic is moving slowly.
  slow,

  /// Traffic is heavily congested.
  congested,

  /// Road segment is blocked.
  blocked,
}

/// Road class for a route segment.
enum AnyRoadClass {
  /// High-speed divided highway (e.g. interstate / autobahn).
  motorway,

  /// Major arterial road just below motorway level.
  trunk,

  /// Primary road connecting major towns.
  primary,

  /// Secondary road connecting smaller towns.
  secondary,

  /// Tertiary road connecting villages.
  tertiary,

  /// Residential / neighborhood street.
  residential,

  /// Service road (parking lots, driveways, alleys).
  service,

  /// Road class that does not fit the other categories.
  other,
}

/// A lane indication for a navigation step.
class AnyLaneInfo {
  /// Whether this lane is recommended for the maneuver.
  final bool isActive;

  /// Directions this lane allows (e.g. "left", "straight", "right").
  final List<String> directions;

  const AnyLaneInfo({
    required this.isActive,
    required this.directions,
  });
}

/// Speed limit for a route segment.
class AnySpeedLimit {
  /// Speed limit in km/h.
  final double speedKmh;

  /// Whether this is an explicit sign or inferred.
  final bool isExplicit;

  const AnySpeedLimit({
    required this.speedKmh,
    this.isExplicit = true,
  });

  /// Speed in mph.
  double get speedMph => speedKmh * 0.621371;
}

/// Annotation for a route segment (bridge, tunnel, toll, etc.).
class AnyRouteAnnotation {
  /// Whether this segment is on a bridge / flyover.
  final bool isBridge;

  /// Whether this segment is in a tunnel.
  final bool isTunnel;

  /// Whether this segment is a toll road.
  final bool isToll;

  /// Whether this segment is a ferry.
  final bool isFerry;

  /// Whether this segment is a motorway.
  final bool isMotorway;

  /// Congestion level on this segment.
  final AnyCongestionLevel congestion;

  /// Speed limit on this segment (if available).
  final AnySpeedLimit? speedLimit;

  /// Road name.
  final String? roadName;

  /// Road class.
  final AnyRoadClass roadClass;

  const AnyRouteAnnotation({
    this.isBridge = false,
    this.isTunnel = false,
    this.isToll = false,
    this.isFerry = false,
    this.isMotorway = false,
    this.congestion = AnyCongestionLevel.unknown,
    this.speedLimit,
    this.roadName,
    this.roadClass = AnyRoadClass.other,
  });
}

/// A single segment of a route with congestion coloring info.
class AnyRouteSegment {
  /// Start coordinate.
  final AnyLatLng start;

  /// End coordinate.
  final AnyLatLng end;

  /// Congestion level.
  final AnyCongestionLevel congestion;

  /// Speed on this segment in m/s.
  final double? speed;

  /// Duration of this segment in seconds.
  final double? duration;

  /// Annotation for this segment.
  final AnyRouteAnnotation? annotation;

  const AnyRouteSegment({
    required this.start,
    required this.end,
    this.congestion = AnyCongestionLevel.unknown,
    this.speed,
    this.duration,
    this.annotation,
  });
}

/// A computed route between two or more points.
class AnyRoute {
  /// Ordered list of coordinates forming the route geometry.
  final List<AnyLatLng> geometry;

  /// Total distance in meters.
  final double distanceMeters;

  /// Estimated duration in seconds.
  final double durationSeconds;

  /// Bounding box of the route.
  final AnyLatLngBounds bounds;

  /// Turn-by-turn navigation steps.
  final List<AnyRouteStep> steps;

  /// Per-segment annotations (congestion, speed, bridge/tunnel).
  final List<AnyRouteSegment> segments;

  /// Raw response from the routing provider (for advanced use).
  final Map<String, dynamic>? rawResponse;

  const AnyRoute({
    required this.geometry,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.bounds,
    this.steps = const [],
    this.segments = const [],
    this.rawResponse,
  });

  /// Distance formatted as a human-readable string.
  String get distanceText {
    if (distanceMeters >= 1000) {
      return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
    }
    return '${distanceMeters.round()} m';
  }

  /// Duration formatted as a human-readable string.
  String get durationText {
    final minutes = (durationSeconds / 60).round();
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return '${hours}h ${mins}m';
    }
    return '$minutes min';
  }

  /// Convert this route to an [AnyPolyline] for easy drawing on the map.
  AnyPolyline toPolyline({
    String id = 'route',
    Color? color,
    double width = 5.0,
  }) {
    return AnyPolyline(
      id: id,
      points: geometry,
      color: color ?? const Color(0xFF4285F4),
      width: width,
    );
  }

  /// Convert segments to traffic-colored polylines (green/yellow/red).
  List<AnyPolyline> toTrafficPolylines({
    String idPrefix = 'traffic',
    double width = 6.0,
  }) {
    if (segments.isEmpty) return [toPolyline(id: '${idPrefix}_0', width: width)];

    final polylines = <AnyPolyline>[];
    for (int i = 0; i < segments.length; i++) {
      final seg = segments[i];
      polylines.add(AnyPolyline(
        id: '${idPrefix}_$i',
        points: [seg.start, seg.end],
        color: _congestionColor(seg.congestion),
        width: width,
      ));
    }
    return polylines;
  }

  static Color _congestionColor(AnyCongestionLevel level) {
    return switch (level) {
      AnyCongestionLevel.freeFlow => const Color(0xFF4CAF50),
      AnyCongestionLevel.slow => const Color(0xFFFFC107),
      AnyCongestionLevel.congested => const Color(0xFFFF5722),
      AnyCongestionLevel.blocked => const Color(0xFF8B0000),
      AnyCongestionLevel.unknown => const Color(0xFF4285F4),
    };
  }

  /// Whether this route passes over any bridges/flyovers.
  bool get hasBridges => segments.any((s) => s.annotation?.isBridge == true);

  /// Whether this route goes through any tunnels.
  bool get hasTunnels => segments.any((s) => s.annotation?.isTunnel == true);

  /// Whether this route includes any toll roads.
  bool get hasTolls => segments.any((s) => s.annotation?.isToll == true);
}

/// A single step in turn-by-turn navigation.
class AnyRouteStep {
  /// Human-readable instruction (e.g. "Turn left on Main St").
  final String instruction;

  /// Distance of this step in meters.
  final double distanceMeters;

  /// Duration of this step in seconds.
  final double durationSeconds;

  /// The maneuver type (e.g. "turn-left", "straight", "arrive").
  final String? maneuver;

  /// Starting coordinate of this step.
  final AnyLatLng startLocation;

  /// Geometry for this step only.
  final List<AnyLatLng> geometry;

  /// Lane guidance information (which lanes to use).
  final List<AnyLaneInfo> lanes;

  /// Speed limit on this step.
  final AnySpeedLimit? speedLimit;

  /// Road annotations (bridge, tunnel, toll, etc.).
  final AnyRouteAnnotation? annotation;

  /// Road name / street name.
  final String? roadName;

  /// Road reference (e.g. "NH 44", "I-95").
  final String? roadRef;

  const AnyRouteStep({
    required this.instruction,
    required this.distanceMeters,
    required this.durationSeconds,
    this.maneuver,
    required this.startLocation,
    this.geometry = const [],
    this.lanes = const [],
    this.speedLimit,
    this.annotation,
    this.roadName,
    this.roadRef,
  });
}
