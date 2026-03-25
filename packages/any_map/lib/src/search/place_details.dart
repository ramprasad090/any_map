import '../models/lat_lng.dart';

/// Detailed information about a place.
class AnyPlaceDetails {
  /// Unique ID.
  final String id;

  /// Display name.
  final String name;

  /// Full address.
  final String address;

  /// Geographic position.
  final AnyLatLng position;

  /// Phone number.
  final String? phone;

  /// Website URL.
  final String? website;

  /// Opening hours (per day).
  final List<AnyOpeningHours>? openingHours;

  /// Average rating (0.0 to 5.0).
  final double? rating;

  /// Number of reviews/ratings.
  final int? ratingCount;

  /// Price level (0 = free, 1 = cheap, 4 = very expensive).
  final int? priceLevel;

  /// Place categories / types.
  final List<String> categories;

  /// Photo URLs.
  final List<String> photoUrls;

  /// Whether the place is currently open.
  final bool? isOpenNow;

  const AnyPlaceDetails({
    required this.id,
    required this.name,
    required this.address,
    required this.position,
    this.phone,
    this.website,
    this.openingHours,
    this.rating,
    this.ratingCount,
    this.priceLevel,
    this.categories = const [],
    this.photoUrls = const [],
    this.isOpenNow,
  });
}

/// Opening hours for one day.
class AnyOpeningHours {
  /// Day of week (1 = Monday, 7 = Sunday).
  final int dayOfWeek;

  /// Day name (e.g. "Monday").
  final String dayName;

  /// Opening time (e.g. "09:00").
  final String? openTime;

  /// Closing time (e.g. "18:00").
  final String? closeTime;

  /// Whether the place is closed on this day.
  final bool isClosed;

  const AnyOpeningHours({
    required this.dayOfWeek,
    required this.dayName,
    this.openTime,
    this.closeTime,
    this.isClosed = false,
  });

  @override
  String toString() =>
      isClosed ? '$dayName: Closed' : '$dayName: $openTime - $closeTime';
}
