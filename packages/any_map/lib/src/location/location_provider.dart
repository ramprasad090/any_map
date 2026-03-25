import 'dart:async';
import '../models/lat_lng.dart';

/// A user location fix with heading and accuracy.
class AnyUserLocation {
  /// Geographic position.
  final AnyLatLng position;

  /// Heading / bearing in degrees from north (0-360). Null if unavailable.
  final double? heading;

  /// Horizontal accuracy in meters.
  final double accuracy;

  /// Altitude in meters above sea level. Null if unavailable.
  final double? altitude;

  /// Speed in m/s. Null if unavailable.
  final double? speed;

  /// Timestamp of the fix.
  final DateTime timestamp;

  const AnyUserLocation({
    required this.position,
    this.heading,
    this.accuracy = 0,
    this.altitude,
    this.speed,
    required this.timestamp,
  });

  /// Speed in km/h.
  double? get speedKmh => speed != null ? speed! * 3.6 : null;
}

/// Camera follow mode for location tracking.
enum AnyFollowMode {
  /// Don't follow user location.
  none,

  /// Follow location, keep north up.
  followLocation,

  /// Follow location and rotate map to match heading.
  followLocationWithBearing,
}

/// Abstract location provider.
///
/// Wraps platform location services. Use with the `geolocator` or
/// `location` Flutter packages.
abstract class AnyLocationProvider {
  /// Stream of location updates.
  Stream<AnyUserLocation> get locationStream;

  /// Get the last known location.
  Future<AnyUserLocation?> getLastLocation();

  /// Request location permissions if needed.
  Future<bool> requestPermission();

  /// Check if location services are enabled.
  Future<bool> isServiceEnabled();

  /// Start continuous location updates.
  Future<void> startUpdates({
    Duration interval = const Duration(seconds: 1),
    double distanceFilter = 5.0,
  });

  /// Stop continuous location updates.
  Future<void> stopUpdates();

  /// Dispose resources.
  void dispose();
}
