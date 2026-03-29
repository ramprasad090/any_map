import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../controllers/map_controller.dart';
import 'location_provider.dart';

/// A Flutter overlay widget that renders the user's current location on an
/// [AnyMapWidget].
///
/// Place it in a [Stack] on top of [AnyMapWidget]. It uses [AnyLocationProvider]
/// to receive location updates and converts them to screen coordinates via
/// [AnyMapController.latLngToScreen].
///
/// Features:
/// - Pulsing accuracy circle
/// - Heading / bearing wedge (when [showHeading] is `true`)
/// - Blue dot with white border
///
/// ```dart
/// Stack(
///   children: [
///     AnyMapWidget(adapter: ..., onMapCreated: (c) => _controller = c),
///     AnyUserLocationLayer(
///       controller: _controller,
///       locationProvider: MyLocationProvider(),
///     ),
///   ],
/// )
/// ```
class AnyUserLocationLayer extends StatefulWidget {
  /// The map controller used to convert lat/lng to screen coordinates.
  final AnyMapController? controller;

  /// Location provider that emits [AnyUserLocation] updates.
  final AnyLocationProvider locationProvider;

  /// Whether to show a heading wedge when heading data is available.
  final bool showHeading;

  /// Whether to show the pulsing accuracy circle.
  final bool showAccuracyCircle;

  /// Color of the location dot.
  final Color dotColor;

  /// Color of the heading wedge and accuracy circle.
  final Color accentColor;

  const AnyUserLocationLayer({
    super.key,
    required this.controller,
    required this.locationProvider,
    this.showHeading = true,
    this.showAccuracyCircle = true,
    this.dotColor = const Color(0xFF1A73E8),
    this.accentColor = const Color(0x331A73E8),
  });

  @override
  State<AnyUserLocationLayer> createState() => _AnyUserLocationLayerState();
}

class _AnyUserLocationLayerState extends State<AnyUserLocationLayer>
    with SingleTickerProviderStateMixin {
  StreamSubscription<AnyUserLocation>? _locationSub;
  AnyUserLocation? _location;
  Offset? _screenPos;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _pulseAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
    _locationSub = widget.locationProvider.locationStream.listen(_onLocation);
  }

  Future<void> _onLocation(AnyUserLocation loc) async {
    if (!mounted) return;
    _location = loc;
    await _updateScreenPos();
  }

  Future<void> _updateScreenPos() async {
    if (!mounted || widget.controller == null || _location == null) return;
    final pos = await widget.controller!.latLngToScreen(_location!.position);
    if (mounted) setState(() => _screenPos = pos);
  }

  @override
  void didUpdateWidget(AnyUserLocationLayer old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      _updateScreenPos();
    }
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_screenPos == null) return const SizedBox.shrink();
    return Positioned(
      left: _screenPos!.dx - 40,
      top: _screenPos!.dy - 40,
      width: 80,
      height: 80,
      child: _LocationDot(
        heading: _location?.heading,
        showHeading: widget.showHeading,
        showAccuracyCircle: widget.showAccuracyCircle,
        pulseAnim: _pulseAnim,
        dotColor: widget.dotColor,
        accentColor: widget.accentColor,
      ),
    );
  }
}

class _LocationDot extends AnimatedWidget {
  final double? heading;
  final bool showHeading;
  final bool showAccuracyCircle;
  final Color dotColor;
  final Color accentColor;

  const _LocationDot({
    required Animation<double> pulseAnim,
    this.heading,
    required this.showHeading,
    required this.showAccuracyCircle,
    required this.dotColor,
    required this.accentColor,
  }) : super(listenable: pulseAnim);

  @override
  Widget build(BuildContext context) {
    final t = (listenable as Animation<double>).value;
    return CustomPaint(
      painter: _LocationPainter(
        heading: heading,
        showHeading: showHeading,
        showAccuracyCircle: showAccuracyCircle,
        pulseScale: t,
        dotColor: dotColor,
        accentColor: accentColor,
      ),
    );
  }
}

class _LocationPainter extends CustomPainter {
  final double? heading;
  final bool showHeading;
  final bool showAccuracyCircle;
  final double pulseScale;
  final Color dotColor;
  final Color accentColor;

  _LocationPainter({
    required this.heading,
    required this.showHeading,
    required this.showAccuracyCircle,
    required this.pulseScale,
    required this.dotColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Accuracy pulse ring
    if (showAccuracyCircle) {
      final pulsePaint = Paint()
        ..color = accentColor.withAlpha((accentColor.a * (1 - pulseScale)).round())
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, 32 * pulseScale, pulsePaint);
    }

    // Heading wedge
    if (showHeading && heading != null) {
      final rad = (heading! - 90) * math.pi / 180;
      final wedgePaint = Paint()
        ..color = dotColor.withAlpha(160)
        ..style = PaintingStyle.fill;
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(
          Rect.fromCircle(center: center, radius: 22),
          rad - 0.4,
          0.8,
          false,
        )
        ..close();
      canvas.drawPath(path, wedgePaint);
    }

    // White border
    canvas.drawCircle(
      center,
      9,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );

    // Blue dot
    canvas.drawCircle(
      center,
      7,
      Paint()
        ..color = dotColor
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_LocationPainter old) =>
      old.pulseScale != pulseScale ||
      old.heading != heading ||
      old.dotColor != dotColor;
}
