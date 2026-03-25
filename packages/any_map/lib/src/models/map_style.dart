/// Map style configuration — supports JSON string styles (Google Maps style)
/// or URL-based styles (MapLibre/MapTiler style URLs).
class AnyMapStyle {
  /// A JSON string defining the map style (Google Maps format).
  final String? jsonStyle;

  /// A URL pointing to a style spec (MapLibre/MapTiler format).
  final String? styleUrl;

  /// A named preset style.
  final AnyMapStylePreset? preset;

  /// Create a style from a JSON string (Google Maps custom styling format).
  ///
  /// ```dart
  /// AnyMapStyle.fromJson('[{"featureType":"water","stylers":[{"color":"#0e171d"}]}]')
  /// ```
  const AnyMapStyle.fromJson(String json)
      : jsonStyle = json,
        styleUrl = null,
        preset = null;

  /// Create a style from a URL (MapLibre / MapTiler style spec).
  ///
  /// ```dart
  /// AnyMapStyle.fromUrl('https://demotiles.maplibre.org/style.json')
  /// ```
  const AnyMapStyle.fromUrl(String url)
      : jsonStyle = null,
        styleUrl = url,
        preset = null;

  /// Use a built-in preset style.
  ///
  /// ```dart
  /// AnyMapStyle.fromPreset(AnyMapStylePreset.dark)
  /// ```
  const AnyMapStyle.fromPreset(AnyMapStylePreset this.preset)
      : jsonStyle = null,
        styleUrl = null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnyMapStyle &&
          other.jsonStyle == jsonStyle &&
          other.styleUrl == styleUrl &&
          other.preset == preset;

  @override
  int get hashCode => Object.hash(jsonStyle, styleUrl, preset);
}

/// Built-in style presets available across all backends.
enum AnyMapStylePreset {
  /// Default light style.
  light,

  /// Dark / night mode style.
  dark,

  /// Satellite imagery.
  satellite,

  /// Satellite with road/label overlay.
  hybrid,

  /// Terrain / topographic.
  terrain,

  /// Minimal / clean style for data visualization overlays.
  minimal,
}
