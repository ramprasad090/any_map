import '../models/lat_lng_bounds.dart';

/// Status of an offline region download.
enum AnyOfflineStatus {
  /// Download has not yet started.
  pending,

  /// Download is in progress.
  downloading,

  /// Download completed successfully.
  complete,

  /// Download failed.
  failed,

  /// Download is paused.
  paused,
}

/// An offline map region.
class AnyOfflineRegion {
  /// Unique identifier.
  final String id;

  /// Display name.
  final String name;

  /// Geographic bounds of the region.
  final AnyLatLngBounds bounds;

  /// Minimum zoom level to cache.
  final double minZoom;

  /// Maximum zoom level to cache.
  final double maxZoom;

  /// Style URL to use for this region.
  final String? styleUrl;

  /// Current download status.
  final AnyOfflineStatus status;

  /// Download progress (0.0 to 1.0).
  final double progress;

  /// Size in bytes (0 if not yet known).
  final int sizeBytes;

  /// When the region was created.
  final DateTime? createdAt;

  const AnyOfflineRegion({
    required this.id,
    required this.name,
    required this.bounds,
    this.minZoom = 0,
    this.maxZoom = 16,
    this.styleUrl,
    this.status = AnyOfflineStatus.pending,
    this.progress = 0,
    this.sizeBytes = 0,
    this.createdAt,
  });

  /// Size formatted as human-readable string.
  String get sizeText {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Tile cache configuration.
class AnyTileCacheConfig {
  /// Maximum cache size in bytes.
  final int maxSizeBytes;

  /// Cache expiration duration.
  final Duration expiration;

  /// Cache policy.
  final AnyCachePolicy policy;

  const AnyTileCacheConfig({
    this.maxSizeBytes = 50 * 1024 * 1024, // 50 MB
    this.expiration = const Duration(days: 30),
    this.policy = AnyCachePolicy.cacheFirst,
  });
}

/// Cache policy for tile loading.
enum AnyCachePolicy {
  /// Try cache first, fall back to network.
  cacheFirst,

  /// Try network first, fall back to cache.
  networkFirst,

  /// Only use cached tiles (offline mode).
  cacheOnly,
}

/// Abstract offline map manager.
///
/// Implement per-backend for tile caching and region downloads.
abstract class AnyOfflineManager {
  /// Download a map region for offline use.
  Future<AnyOfflineRegion> downloadRegion({
    required String name,
    required AnyLatLngBounds bounds,
    double minZoom = 0,
    double maxZoom = 16,
    String? styleUrl,
  });

  /// Delete an offline region.
  Future<void> deleteRegion(String id);

  /// List all downloaded regions.
  Future<List<AnyOfflineRegion>> listRegions();

  /// Get status of a region download.
  Future<AnyOfflineRegion> getRegionStatus(String id);

  /// Pause a region download.
  Future<void> pauseDownload(String id);

  /// Resume a paused download.
  Future<void> resumeDownload(String id);

  /// Clear all cached tiles.
  Future<void> clearCache();

  /// Get total cache size in bytes.
  Future<int> getCacheSize();

  /// Dispose resources.
  void dispose();
}
