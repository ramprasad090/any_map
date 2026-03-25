import 'dart:async';
import '../models/lat_lng.dart';
import '../models/lat_lng_bounds.dart';

/// Type of user-submitted report.
enum AnyReportType {
  /// Traffic jam / slowdown.
  trafficJam,

  /// Accident / collision.
  accident,

  /// Police / speed trap.
  police,

  /// Road hazard (pothole, debris, animal).
  hazard,

  /// Road closure.
  roadClosed,

  /// Construction / roadwork.
  construction,

  /// Weather condition (flood, ice, fog).
  weather,

  /// Speed camera (fixed or mobile).
  speedCamera,

  /// Fuel prices.
  fuelPrice,

  /// Other.
  other,
}

/// Severity level for a report.
enum AnyReportSeverity {
  /// Minor impact.
  low,

  /// Moderate impact.
  medium,

  /// Significant impact.
  high,

  /// Severe or dangerous condition.
  critical,
}

/// A crowdsourced user report (Waze-style).
class AnyUserReport {
  /// Unique ID.
  final String id;

  /// Report type.
  final AnyReportType type;

  /// Severity.
  final AnyReportSeverity severity;

  /// Location of the report.
  final AnyLatLng position;

  /// Description text.
  final String? description;

  /// Who submitted it.
  final String? reportedBy;

  /// When it was reported.
  final DateTime reportedAt;

  /// When it's expected to expire / clear.
  final DateTime? expiresAt;

  /// Number of confirmations from other users.
  final int confirmations;

  /// Number of dismissals from other users.
  final int dismissals;

  /// Custom metadata (e.g. fuel price, hazard sub-type).
  final Map<String, dynamic>? metadata;

  const AnyUserReport({
    required this.id,
    required this.type,
    this.severity = AnyReportSeverity.medium,
    required this.position,
    this.description,
    this.reportedBy,
    required this.reportedAt,
    this.expiresAt,
    this.confirmations = 0,
    this.dismissals = 0,
    this.metadata,
  });

  /// Whether this report is still active (not expired).
  bool get isActive =>
      expiresAt == null || expiresAt!.isAfter(DateTime.now());

  /// Reliability score based on confirmations vs dismissals.
  double get reliability {
    final total = confirmations + dismissals;
    if (total == 0) return 0.5;
    return confirmations / total;
  }
}

/// Abstract provider for crowdsourced reports.
///
/// Implement this for your backend (Waze API, custom server, Firebase, etc.).
abstract class AnyReportProvider {
  /// Display name of this report provider.
  String get name;

  /// Fetch reports within the given bounds.
  Future<List<AnyUserReport>> getReports(
    AnyLatLngBounds bounds, {
    Set<AnyReportType>? types,
  });

  /// Submit a new report.
  Future<AnyUserReport> submitReport({
    required AnyReportType type,
    required AnyLatLng position,
    AnyReportSeverity severity = AnyReportSeverity.medium,
    String? description,
  });

  /// Confirm an existing report (thumbs up).
  Future<void> confirmReport(String reportId);

  /// Dismiss a report (not there anymore).
  Future<void> dismissReport(String reportId);
}
