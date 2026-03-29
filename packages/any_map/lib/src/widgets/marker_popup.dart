import 'dart:async';

import 'package:flutter/material.dart';

import '../controllers/map_controller.dart';
import '../models/lat_lng.dart';
import '../models/marker.dart';

/// A floating info-window that tracks a map marker's screen position.
///
/// Place it in a [Stack] on top of [AnyMapWidget]. It listens to the
/// [AnyMapController.cameraPositionStream] and re-projects the marker's
/// lat/lng to screen coordinates on each camera move.
///
/// ```dart
/// Stack(
///   children: [
///     AnyMapWidget(adapter: ..., onMapCreated: (c) => _controller = c),
///     if (_selectedMarker != null)
///       AnyMarkerPopup(
///         controller: _controller,
///         marker: _selectedMarker!,
///         onClose: () => setState(() => _selectedMarker = null),
///       ),
///   ],
/// )
/// ```
class AnyMarkerPopup extends StatefulWidget {
  /// The map controller used to project lat/lng → screen coordinates.
  final AnyMapController? controller;

  /// The marker whose position the popup tracks.
  final AnyMarker marker;

  /// Called when the user taps the close button.
  final VoidCallback? onClose;

  /// Custom popup content. If omitted, the default card with [AnyMarker.title]
  /// and [AnyMarker.snippet] is shown.
  final Widget? child;

  /// Vertical offset (in logical pixels) above the marker dot.
  final double offsetY;

  const AnyMarkerPopup({
    super.key,
    required this.controller,
    required this.marker,
    this.onClose,
    this.child,
    this.offsetY = 60,
  });

  @override
  State<AnyMarkerPopup> createState() => _AnyMarkerPopupState();
}

class _AnyMarkerPopupState extends State<AnyMarkerPopup>
    with SingleTickerProviderStateMixin {
  Offset? _screenPos;
  StreamSubscription? _cameraSub;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _attach(widget.controller);
  }

  void _attach(AnyMapController? ctrl) {
    _cameraSub?.cancel();
    if (ctrl == null) return;
    _updatePos(widget.marker.position, ctrl);
    _cameraSub = ctrl.cameraPositionStream.listen((_) {
      _updatePos(widget.marker.position, ctrl);
    });
  }

  Future<void> _updatePos(AnyLatLng latLng, AnyMapController ctrl) async {
    final pos = await ctrl.latLngToScreen(latLng);
    if (mounted) setState(() => _screenPos = pos);
  }

  @override
  void didUpdateWidget(AnyMarkerPopup old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      _attach(widget.controller);
    } else if (old.marker.position != widget.marker.position) {
      if (widget.controller != null) {
        _updatePos(widget.marker.position, widget.controller!);
      }
    }
  }

  @override
  void dispose() {
    _cameraSub?.cancel();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_screenPos == null) return const SizedBox.shrink();

    final content = widget.child ??
        _DefaultPopupCard(
          title: widget.marker.title,
          snippet: widget.marker.snippet,
          onClose: widget.onClose,
        );

    return Positioned(
      left: _screenPos!.dx,
      top: _screenPos!.dy - widget.offsetY,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -1),
        child: FadeTransition(
          opacity: _fadeAnim,
          child: content,
        ),
      ),
    );
  }
}

class _DefaultPopupCard extends StatelessWidget {
  final String? title;
  final String? snippet;
  final VoidCallback? onClose;

  const _DefaultPopupCard({this.title, this.snippet, this.onClose});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        constraints: const BoxConstraints(minWidth: 120, maxWidth: 220),
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null)
                    Text(title!, style: theme.textTheme.titleSmall),
                  if (snippet != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      snippet!,
                      style: theme.textTheme.bodySmall,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (onClose != null)
              GestureDetector(
                onTap: onClose,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close, size: 14),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
