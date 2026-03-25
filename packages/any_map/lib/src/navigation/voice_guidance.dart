import '../routing/route.dart';

/// Voice instruction for TTS.
class AnyVoiceInstruction {
  /// The text to speak.
  final String text;

  /// Distance until the maneuver (for pre-announcements).
  final double? distanceMeters;

  /// The step this instruction relates to.
  final AnyRouteStep? step;

  /// Type of announcement.
  final AnyAnnouncementType type;

  const AnyVoiceInstruction({
    required this.text,
    this.distanceMeters,
    this.step,
    this.type = AnyAnnouncementType.instruction,
  });
}

/// Types of voice announcements.
enum AnyAnnouncementType {
  /// Standard turn instruction.
  instruction,

  /// Pre-announcement ("In 500 meters, turn left").
  preAnnouncement,

  /// Arrival at destination.
  arrival,

  /// Speed limit warning.
  speedWarning,

  /// Reroute notification.
  reroute,

  /// Traffic ahead notification.
  traffic,
}

/// Abstract voice guidance engine.
///
/// Implement with platform TTS (e.g. flutter_tts).
abstract class AnyVoiceGuidance {
  /// Whether voice is enabled.
  bool get isEnabled;

  /// Enable/disable voice guidance.
  set isEnabled(bool value);

  /// Language for TTS (e.g. "en-US", "hi-IN").
  String get language;

  /// Set TTS language.
  set language(String value);

  /// Speech rate (0.0 to 1.0).
  double get speechRate;
  set speechRate(double value);

  /// Volume (0.0 to 1.0).
  double get volume;
  set volume(double value);

  /// Speak an instruction.
  Future<void> speak(AnyVoiceInstruction instruction);

  /// Stop any current speech.
  Future<void> stop();

  /// Generate the pre-announcement text for a step.
  ///
  /// E.g. "In 500 meters, turn left onto NH 44"
  String buildPreAnnouncement(AnyRouteStep step, double distanceMeters) {
    final dist = distanceMeters >= 1000
        ? '${(distanceMeters / 1000).toStringAsFixed(1)} kilometers'
        : '${distanceMeters.round()} meters';
    return 'In $dist, ${step.instruction}';
  }

  /// Generate the immediate instruction text.
  ///
  /// E.g. "Turn left onto NH 44"
  String buildInstruction(AnyRouteStep step) {
    return step.instruction;
  }

  /// Generate arrival text.
  String buildArrivalText() => 'You have arrived at your destination.';

  /// Dispose resources.
  void dispose();
}
