/// Statistics for cache usage monitoring.
///
/// Tracks hits, misses, evictions, and provides computed metrics like
/// hit rate. All counters can be reset via [reset].
///
/// ```dart
/// final stats = VeloxCacheStats();
/// stats.recordHit();
/// stats.recordMiss();
/// print(stats.hitRate); // 0.5
/// ```
class VeloxCacheStats {
  int _hits = 0;
  int _misses = 0;
  int _evictions = 0;
  int _expirations = 0;
  int _writes = 0;

  /// Total number of cache hits.
  int get hits => _hits;

  /// Total number of cache misses.
  int get misses => _misses;

  /// Total number of cache evictions.
  int get evictions => _evictions;

  /// Total number of cache expirations.
  int get expirations => _expirations;

  /// Total number of cache writes (puts).
  int get writes => _writes;

  /// Total number of lookups (hits + misses).
  int get totalLookups => _hits + _misses;

  /// Hit rate as a ratio between 0.0 and 1.0.
  ///
  /// Returns 0.0 if no lookups have been made.
  double get hitRate => totalLookups == 0 ? 0.0 : _hits / totalLookups;

  /// Miss rate as a ratio between 0.0 and 1.0.
  ///
  /// Returns 0.0 if no lookups have been made.
  double get missRate => totalLookups == 0 ? 0.0 : _misses / totalLookups;

  /// Records a cache hit.
  void recordHit() => _hits++;

  /// Records a cache miss.
  void recordMiss() => _misses++;

  /// Records a cache eviction.
  void recordEviction() => _evictions++;

  /// Records a cache expiration.
  void recordExpiration() => _expirations++;

  /// Records a cache write (put).
  void recordWrite() => _writes++;

  /// Resets all statistics to zero.
  void reset() {
    _hits = 0;
    _misses = 0;
    _evictions = 0;
    _expirations = 0;
    _writes = 0;
  }

  @override
  String toString() =>
      'VeloxCacheStats(hits: $_hits, misses: $_misses, '
      'evictions: $_evictions, expirations: $_expirations, '
      'writes: $_writes, hitRate: ${hitRate.toStringAsFixed(2)})';
}
