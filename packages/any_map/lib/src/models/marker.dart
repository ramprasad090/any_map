import 'package:flutter/widgets.dart';

import 'lat_lng.dart';

/// Anchor point for a marker icon relative to its position.
enum AnyMarkerAnchor { top, center, bottom }

/// A marker to be placed on the map.
class AnyMarker {
  /// Unique identifier for this marker.
  final String id;

  /// Geographic position of this marker.
  final AnyLatLng position;

  /// Optional title shown in info window.
  final String? title;

  /// Optional snippet shown below the title in info window.
  final String? snippet;

  /// Custom icon widget. If null, default pin is used.
  final Widget? icon;

  /// Asset path for marker icon (alternative to widget icon).
  final String? iconAsset;

  /// Icon anchor point.
  final AnyMarkerAnchor anchor;

  /// Rotation in degrees clockwise from north.
  final double rotation;

  /// Opacity from 0.0 (invisible) to 1.0 (fully opaque).
  final double opacity;

  /// Whether the marker is draggable.
  final bool draggable;

  /// Whether the marker is visible.
  final bool visible;

  /// Z-index for draw order.
  final int zIndex;

  /// Arbitrary data attached to this marker.
  final Map<String, dynamic>? metadata;

  /// Callback when this marker is tapped.
  final VoidCallback? onTap;

  /// Callback when this marker is dragged to a new position.
  final ValueChanged<AnyLatLng>? onDragEnd;

  const AnyMarker({
    required this.id,
    required this.position,
    this.title,
    this.snippet,
    this.icon,
    this.iconAsset,
    this.anchor = AnyMarkerAnchor.bottom,
    this.rotation = 0.0,
    this.opacity = 1.0,
    this.draggable = false,
    this.visible = true,
    this.zIndex = 0,
    this.metadata,
    this.onTap,
    this.onDragEnd,
  });

  AnyMarker copyWith({
    String? id,
    AnyLatLng? position,
    String? title,
    String? snippet,
    Widget? icon,
    String? iconAsset,
    AnyMarkerAnchor? anchor,
    double? rotation,
    double? opacity,
    bool? draggable,
    bool? visible,
    int? zIndex,
    Map<String, dynamic>? metadata,
    VoidCallback? onTap,
    ValueChanged<AnyLatLng>? onDragEnd,
  }) {
    return AnyMarker(
      id: id ?? this.id,
      position: position ?? this.position,
      title: title ?? this.title,
      snippet: snippet ?? this.snippet,
      icon: icon ?? this.icon,
      iconAsset: iconAsset ?? this.iconAsset,
      anchor: anchor ?? this.anchor,
      rotation: rotation ?? this.rotation,
      opacity: opacity ?? this.opacity,
      draggable: draggable ?? this.draggable,
      visible: visible ?? this.visible,
      zIndex: zIndex ?? this.zIndex,
      metadata: metadata ?? this.metadata,
      onTap: onTap ?? this.onTap,
      onDragEnd: onDragEnd ?? this.onDragEnd,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AnyMarker && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
