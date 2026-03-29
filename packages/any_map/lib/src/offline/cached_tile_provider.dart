import 'dart:async';

/// A simple in-memory tile cache entry.
class _TileEntry {
  final List<int> bytes;
  final DateTime fetchedAt;
  _TileEntry(this.bytes, this.fetchedAt);
}

/// Statistics for the tile cache.
class AnyCacheStats {
  /// Number of tiles currently held in memory.
  final int memoryEntries;

  /// Total approximate bytes in memory.
  final int memoryBytes;

  /// Number of cache hits since last reset.
  final int hits;

  /// Number of cache misses since last reset.
  final int misses;

  const AnyCacheStats({
    required this.memoryEntries,
    required this.memoryBytes,
    required this.hits,
    required this.misses,
  });

  @override
  String toString() =>
      'AnyCacheStats(entries=$memoryEntries, bytes=$memoryBytes, hits=$hits, misses=$misses)';
}

/// A pluggable interface for persisting tile bytes (e.g. to SQLite or the
/// filesystem).
///
/// Implement this to back [AnyCachingTileProvider] with durable storage:
///
/// ```dart
/// class SqliteTileStore implements AnyTileStore {
///   @override
///   Future<List<int>?> get(String key) => _db.query(key);
///
///   @override
///   Future<void> put(String key, List<int> bytes) => _db.insert(key, bytes);
///
///   @override
///   Future<void> evict(String key) => _db.delete(key);
///
///   @override
///   Future<void> clear() => _db.clearAll();
/// }
/// ```
abstract class AnyTileStore {
  /// Return cached bytes for [key], or `null` if not present.
  Future<List<int>?> get(String key);

  /// Persist [bytes] under [key].
  Future<void> put(String key, List<int> bytes);

  /// Remove a single entry.
  Future<void> evict(String key);

  /// Remove all cached tiles.
  Future<void> clear();
}

/// Tile fetcher function: given a tile URL, return its raw bytes.
typedef AnyTileFetcher = Future<List<int>> Function(String url);

/// An in-memory + optional persistent tile cache.
///
/// Wraps a [AnyTileFetcher] (e.g. an HTTP client) and adds:
/// - LRU in-memory cache with a configurable [maxMemoryEntries] cap
/// - Optional [AnyTileStore] for durable disk / database storage
/// - TTL-based expiry via [maxAge]
///
/// Use [AnyCachingTileProvider.fetch] wherever your map backend needs tiles.
///
/// ```dart
/// final cache = AnyCachingTileProvider(
///   fetcher: (url) async {
///     final resp = await http.get(Uri.parse(url));
///     return resp.bodyBytes;
///   },
///   maxMemoryEntries: 256,
///   maxAge: Duration(days: 7),
/// );
///
/// final bytes = await cache.fetch('https://tile.openstreetmap.org/12/1234/2345.png');
/// ```
class AnyCachingTileProvider {
  /// Called when a tile is not in cache.
  final AnyTileFetcher fetcher;

  /// Optional durable store (SQLite, file system, etc.).
  final AnyTileStore? persistentStore;

  /// Maximum number of tiles to hold in the in-memory LRU cache.
  final int maxMemoryEntries;

  /// Maximum age of a cached tile before it is considered stale.
  final Duration maxAge;

  final _memory = <String, _TileEntry>{};
  int _hits = 0;
  int _misses = 0;

  AnyCachingTileProvider({
    required this.fetcher,
    this.persistentStore,
    this.maxMemoryEntries = 256,
    this.maxAge = const Duration(days: 7),
  });

  /// Fetch tile bytes, returning from cache if available.
  Future<List<int>> fetch(String url) async {
    final key = url;

    // 1. Memory cache
    final memEntry = _memory[key];
    if (memEntry != null &&
        DateTime.now().difference(memEntry.fetchedAt) < maxAge) {
      _hits++;
      // Move to end (LRU)
      _memory.remove(key);
      _memory[key] = memEntry;
      return memEntry.bytes;
    }

    // 2. Persistent store
    if (persistentStore != null) {
      final stored = await persistentStore!.get(key);
      if (stored != null) {
        _hits++;
        _promote(key, stored);
        return stored;
      }
    }

    // 3. Network
    _misses++;
    final bytes = await fetcher(url);
    _promote(key, bytes);
    await persistentStore?.put(key, bytes);
    return bytes;
  }

  void _promote(String key, List<int> bytes) {
    _memory.remove(key);
    if (_memory.length >= maxMemoryEntries) {
      _memory.remove(_memory.keys.first);
    }
    _memory[key] = _TileEntry(bytes, DateTime.now());
  }

  /// Remove a specific tile from all caches.
  Future<void> evict(String url) async {
    _memory.remove(url);
    await persistentStore?.evict(url);
  }

  /// Clear all in-memory cached tiles (does not touch persistent store).
  void clearMemory() => _memory.clear();

  /// Clear both memory and persistent store.
  Future<void> clearAll() async {
    _memory.clear();
    await persistentStore?.clear();
  }

  /// Reset hit/miss counters.
  void resetStats() {
    _hits = 0;
    _misses = 0;
  }

  /// Current cache statistics.
  AnyCacheStats get stats => AnyCacheStats(
        memoryEntries: _memory.length,
        memoryBytes: _memory.values.fold(0, (sum, e) => sum + e.bytes.length),
        hits: _hits,
        misses: _misses,
      );
}
