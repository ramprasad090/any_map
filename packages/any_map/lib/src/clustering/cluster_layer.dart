import 'package:flutter/widgets.dart';

import '../controllers/map_controller.dart';
import '../models/models.dart';
import 'cluster.dart';
import 'cluster_engine.dart';

/// Builder for rendering a cluster on the map.
///
/// Return a widget that represents the cluster. For single markers,
/// [cluster.isSingle] is true and you can use the marker's own icon.
typedef ClusterWidgetBuilder = Widget Function(
  BuildContext context,
  AnyCluster cluster,
);

/// A widget layer that adds automatic marker clustering to any [AnyMapWidget].
///
/// Wrap your map in a [Stack] and add this layer on top:
/// ```dart
/// Stack(
///   children: [
///     AnyMapWidget(..., onMapCreated: (c) => _ctrl = c, onCameraIdle: _refresh),
///     AnyClusterLayer(
///       controller: _ctrl,
///       markers: allMarkers,
///       builder: (ctx, cluster) => ClusterBubble(count: cluster.count),
///     ),
///   ],
/// )
/// ```
class AnyClusterLayer extends StatefulWidget {
  final AnyMapController controller;
  final List<AnyMarker> markers;
  final ClusterWidgetBuilder builder;
  final ClusterConfig config;

  /// Called when a cluster is tapped.
  final ValueChanged<AnyCluster>? onClusterTap;

  const AnyClusterLayer({
    super.key,
    required this.controller,
    required this.markers,
    required this.builder,
    this.config = const ClusterConfig(),
    this.onClusterTap,
  });

  @override
  State<AnyClusterLayer> createState() => _AnyClusterLayerState();
}

class _AnyClusterLayerState extends State<AnyClusterLayer> {
  late final AnyClusterEngine _engine;
  List<AnyCluster> _clusters = [];

  @override
  void initState() {
    super.initState();
    _engine = AnyClusterEngine(config: widget.config);
    _engine.load(widget.markers);
    _refresh();
  }

  @override
  void didUpdateWidget(AnyClusterLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.markers != widget.markers) {
      _engine.load(widget.markers);
      _refresh();
    }
  }

  Future<void> _refresh() async {
    final bounds = await widget.controller.getVisibleBounds();
    final camera = await widget.controller.getCameraPosition();
    if (!mounted) return;
    setState(() {
      _clusters = _engine.getClusters(bounds, zoom: camera.zoom);
    });
  }

  @override
  Widget build(BuildContext context) {
    // This layer renders clusters as Flutter widgets positioned over the map.
    // For production, you'd convert lat/lng to screen coords via controller.
    // This is a simplified version — full implementation converts positions.
    return IgnorePointer(
      ignoring: _clusters.isEmpty,
      child: Stack(
        children: _clusters.map((cluster) {
          return FutureBuilder(
            future: widget.controller.latLngToScreen(cluster.position),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data == null) {
                return const SizedBox.shrink();
              }
              final offset = snapshot.data!;
              return Positioned(
                left: offset.dx - 20,
                top: offset.dy - 20,
                child: GestureDetector(
                  onTap: () => widget.onClusterTap?.call(cluster),
                  child: widget.builder(context, cluster),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }
}
