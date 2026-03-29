/// Categories of errors that can occur in any_map.
enum AnyMapErrorType {
  /// The map style failed to load (bad URL, network error).
  styleLoadFailed,

  /// A tile failed to load (network timeout, 404, etc.).
  tileLoadFailed,

  /// The map could not be initialised (missing API key, unsupported platform).
  initializationFailed,

  /// A location permission was denied by the user.
  locationPermissionDenied,

  /// A requested routing/geocoding operation failed.
  operationFailed,

  /// An unknown / backend-specific error.
  unknown,
}

/// A typed error emitted by [AnyMapWidget.onError].
///
/// ```dart
/// AnyMapWidget(
///   adapter: ...,
///   onError: (err) {
///     if (err.type == AnyMapErrorType.styleLoadFailed) {
///       showSnackBar('Map style could not be loaded');
///     }
///   },
/// )
/// ```
class AnyMapError {
  /// Category of the error.
  final AnyMapErrorType type;

  /// Human-readable description.
  final String message;

  /// The underlying exception, if any.
  final Object? cause;

  /// Stack trace associated with [cause].
  final StackTrace? stackTrace;

  const AnyMapError({
    required this.type,
    required this.message,
    this.cause,
    this.stackTrace,
  });

  @override
  String toString() => 'AnyMapError(${type.name}): $message';
}
