import 'dart:async';

import 'package:velox_cache/src/models/cache_entry.dart';
import 'package:velox_cache/src/models/cache_stats.dart';

/// A combined cache with both LRU eviction and TTL expiration.
///
/// Features:
/// - LRU eviction when cache reaches [maxSize]
/// - TTL-based expiration per entry
/// - Reactive cache change streams via [onChange]
/// - Cache statistics via [stats]
/// - Tag-based grouping and invalidation
/// - Bulk operations ([putAll], [getAll], [removeAll])
/// - Auto-loading via [getOrLoad]
/// - Stale-while-revalidate via [getStale]
///
/// ```dart
/// final cache = VeloxCache<String>(
///   maxSize: 100,
///   defaultTtl: Duration(minutes: 5),
/// );
///
/// cache.put('user:1', 'John', tags: {'user'});
/// final value = cache.get('user:1'); // 'John'
///
/// // Listen for changes
/// cache.onChange.listen((event) {
///   print('${event.key}: ${event.type}');
/// });
///
/// // Invalidate by tag
/// cache.invalidateByTag('user');
/// ```
class VeloxCache<T> {
  /// Creates a [VeloxCache].
  VeloxCache({
    required this.maxSize,
    required this.defaultTtl,
  }) : assert(maxSize > 0, 'maxSize must be positive');

  /// Maximum number of entries.
  final int maxSize;

  /// Default time-to-live for entries.
  final Duration defaultTtl;

  final Map<String, CacheEntry<T>> _entries = {};
  final StreamController<CacheEvent<T>> _changeController =
      StreamController<CacheEvent<T>>.broadcast();

  /// Cache statistics tracker.
  final VeloxCacheStats stats = VeloxCacheStats();

  /// Stream of cache change events.
  Stream<CacheEvent<T>> get onChange => _changeController.stream;

  /// Returns the number of valid entries.
  int get size {
    _removeExpired();
    return _entries.length;
  }

  /// Returns `true` if the cache is empty.
  bool get isEmpty => size == 0;

  /// Returns all keys of valid entries.
  Iterable<String> get keys {
    _removeExpired();
    return _entries.keys;
  }

  /// Gets a value by [key], or `null` if not found or expired.
  T? get(String key) {
    final entry = _entries[key];
    if (entry == null) {
      stats.recordMiss();
      _changeController.add(CacheEvent<T>.miss(key));
      return null;
    }

    if (entry.isExpired) {
      _entries.remove(key);
      stats
        ..recordMiss()
        ..recordExpiration();
      _changeController.add(CacheEvent.expired(key, entry.value));
      return null;
    }

    entry.touch();
    stats.recordHit();
    _changeController.add(CacheEvent.hit(key, entry.value));
    return entry.value;
  }

  /// Puts a [value] with optional custom [ttl] and [tags].
  void put(String key, T value, {Duration? ttl, Set<String>? tags}) {
    _removeExpired();

    if (!_entries.containsKey(key) && _entries.length >= maxSize) {
      _evictLru();
    }

    final now = DateTime.now();
    _entries[key] = CacheEntry(
      key: key,
      value: value,
      createdAt: now,
      expiresAt: now.add(ttl ?? defaultTtl),
      tags: tags,
    );

    stats.recordWrite();
    _changeController.add(CacheEvent.put(key, value));
  }

  /// Puts multiple entries at once.
  ///
  /// Each entry shares the same optional [ttl] and [tags].
  void putAll(
    Map<String, T> entries, {
    Duration? ttl,
    Set<String>? tags,
  }) {
    for (final entry in entries.entries) {
      put(entry.key, entry.value, ttl: ttl, tags: tags);
    }
  }

  /// Gets multiple values by [keys].
  ///
  /// Returns a map of keys to values. Keys with missing or expired entries
  /// are omitted from the result.
  Map<String, T> getAll(Iterable<String> keys) {
    final results = <String, T>{};
    for (final key in keys) {
      final value = get(key);
      if (value != null) {
        results[key] = value;
      }
    }
    return results;
  }

  /// Removes multiple entries by [keys].
  ///
  /// Returns a map of keys to the removed values.
  Map<String, T> removeAll(Iterable<String> keys) {
    final results = <String, T>{};
    for (final key in keys) {
      final value = remove(key);
      if (value != null) {
        results[key] = value;
      }
    }
    return results;
  }

  /// Removes a value by [key].
  T? remove(String key) {
    final entry = _entries.remove(key);
    if (entry != null) {
      _changeController.add(CacheEvent.removed(key, entry.value));
    }
    return entry?.value;
  }

  /// Returns `true` if the cache contains a valid [key].
  bool containsKey(String key) {
    final entry = _entries[key];
    if (entry == null) return false;
    if (entry.isExpired) {
      _entries.remove(key);
      return false;
    }
    return true;
  }

  /// Gets a value or computes it if absent/expired.
  T getOrPut(String key, T Function() ifAbsent, {Duration? ttl}) {
    final existing = get(key);
    if (existing != null) return existing;

    final value = ifAbsent();
    put(key, value, ttl: ttl);
    return value;
  }

  /// Gets a value or computes it asynchronously if absent/expired.
  Future<T> getOrPutAsync(
    String key,
    Future<T> Function() ifAbsent, {
    Duration? ttl,
  }) async {
    final existing = get(key);
    if (existing != null) return existing;

    final value = await ifAbsent();
    put(key, value, ttl: ttl);
    return value;
  }

  /// Gets a value or loads it via [loader] if absent/expired.
  ///
  /// This is an alias for [getOrPutAsync] with a clearer semantic name.
  /// Commonly used for the "cache loader" pattern where data is
  /// automatically fetched and cached on a miss.
  Future<T> getOrLoad(
    String key,
    Future<T> Function() loader, {
    Duration? ttl,
    Set<String>? tags,
  }) async {
    final existing = get(key);
    if (existing != null) return existing;

    final value = await loader();
    put(key, value, ttl: ttl, tags: tags);
    return value;
  }

  /// Returns the stale value for [key] while triggering a background refresh.
  ///
  /// If the entry exists but is expired (or within the [staleTolerance]
  /// window), it returns the stale value immediately and calls [refresh]
  /// in the background to update the cache.
  ///
  /// If the entry does not exist at all, returns `null`.
  ///
  /// The [staleTolerance] controls how long past expiry a stale value
  /// is still considered servable. Defaults to 1 minute.
  T? getStale(
    String key, {
    required Future<T> Function() refresh,
    Duration staleTolerance = const Duration(minutes: 1),
    Duration? ttl,
  }) {
    final entry = _entries[key];
    if (entry == null) {
      stats.recordMiss();
      _changeController.add(CacheEvent<T>.miss(key));
      return null;
    }

    if (!entry.isExpired) {
      entry.touch();
      stats.recordHit();
      _changeController.add(CacheEvent.hit(key, entry.value));
      return entry.value;
    }

    // Entry is expired - check if it's within stale tolerance
    final staleDeadline = entry.expiresAt!.add(staleTolerance);
    if (DateTime.now().isAfter(staleDeadline)) {
      // Beyond stale tolerance - remove and return null
      _entries.remove(key);
      stats
        ..recordMiss()
        ..recordExpiration();
      _changeController.add(CacheEvent.expired(key, entry.value));
      return null;
    }

    // Serve stale value and refresh in background
    stats.recordHit();
    _changeController.add(CacheEvent.stale(key, entry.value));

    // Fire-and-forget background refresh
    _backgroundRefresh(key, refresh, ttl: ttl, tags: entry.tags);

    return entry.value;
  }

  Future<void> _backgroundRefresh(
    String key,
    Future<T> Function() refresh, {
    Duration? ttl,
    Set<String>? tags,
  }) async {
    try {
      final freshValue = await refresh();
      put(key, freshValue, ttl: ttl, tags: tags);
    } on Object {
      // Silently ignore refresh errors - stale data was already served
    }
  }

  /// Invalidates all entries with the given [tag].
  ///
  /// Returns the number of entries removed.
  int invalidateByTag(String tag) {
    final keysToRemove = <String>[];
    for (final entry in _entries.entries) {
      if (entry.value.hasTag(tag)) {
        keysToRemove.add(entry.key);
      }
    }

    for (final key in keysToRemove) {
      final entry = _entries.remove(key);
      if (entry != null) {
        _changeController.add(CacheEvent.removed(key, entry.value));
      }
    }

    return keysToRemove.length;
  }

  /// Invalidates all entries with any of the given [tags].
  ///
  /// Returns the number of entries removed.
  int invalidateByTags(Set<String> tags) {
    final keysToRemove = <String>[];
    for (final entry in _entries.entries) {
      if (entry.value.hasAnyTag(tags)) {
        keysToRemove.add(entry.key);
      }
    }

    for (final key in keysToRemove) {
      final entry = _entries.remove(key);
      if (entry != null) {
        _changeController.add(CacheEvent.removed(key, entry.value));
      }
    }

    return keysToRemove.length;
  }

  /// Returns all keys that have the given [tag].
  List<String> keysByTag(String tag) {
    _removeExpired();
    return _entries.entries
        .where((e) => e.value.hasTag(tag))
        .map((e) => e.key)
        .toList();
  }

  /// Returns the [CacheEntry] for [key] if it exists and is valid.
  ///
  /// Useful for inspecting metadata (creation time, access count, tags).
  CacheEntry<T>? entry(String key) {
    final e = _entries[key];
    if (e == null || e.isExpired) return null;
    return e;
  }

  /// Clears all entries.
  void clear() {
    _entries.clear();
    _changeController.add(CacheEvent<T>.cleared());
  }

  /// Disposes the cache and its streams.
  void dispose() {
    _entries.clear();
    _changeController.close();
  }

  void _evictLru() {
    if (_entries.isEmpty) return;

    String? lruKey;
    DateTime? lruTime;

    for (final entry in _entries.entries) {
      if (lruTime == null ||
          entry.value.lastAccessedAt.isBefore(lruTime)) {
        lruKey = entry.key;
        lruTime = entry.value.lastAccessedAt;
      }
    }

    if (lruKey != null) {
      final evicted = _entries.remove(lruKey);
      if (evicted != null) {
        stats.recordEviction();
        _changeController.add(CacheEvent.evicted(lruKey, evicted.value));
      }
    }
  }

  void _removeExpired() {
    final expired = <String>[];
    for (final entry in _entries.entries) {
      if (entry.value.isExpired) {
        expired.add(entry.key);
      }
    }
    for (final key in expired) {
      final entry = _entries.remove(key);
      if (entry != null) {
        stats.recordExpiration();
        _changeController.add(CacheEvent.expired(key, entry.value));
      }
    }
  }
}

/// Types of cache events.
enum CacheEventType {
  /// A cache hit occurred.
  hit,

  /// A cache miss occurred.
  miss,

  /// An entry was added or updated.
  put,

  /// An entry was manually removed.
  removed,

  /// An entry was evicted due to size limits.
  evicted,

  /// An entry expired.
  expired,

  /// A stale entry was served while refreshing.
  stale,

  /// The cache was cleared.
  cleared,
}

/// A cache change event.
class CacheEvent<T> {
  /// Creates a [CacheEvent].
  const CacheEvent({
    required this.type,
    this.key,
    this.value,
  });

  /// A cache hit occurred.
  const CacheEvent.hit(String this.key, T this.value)
      : type = CacheEventType.hit;

  /// A cache miss occurred.
  const CacheEvent.miss(String this.key)
      : type = CacheEventType.miss,
        value = null;

  /// An entry was put into the cache.
  const CacheEvent.put(String this.key, T this.value)
      : type = CacheEventType.put;

  /// An entry was manually removed.
  const CacheEvent.removed(String this.key, T this.value)
      : type = CacheEventType.removed;

  /// An entry was evicted.
  const CacheEvent.evicted(String this.key, T this.value)
      : type = CacheEventType.evicted;

  /// An entry expired.
  const CacheEvent.expired(String this.key, T this.value)
      : type = CacheEventType.expired;

  /// A stale entry was served during revalidation.
  const CacheEvent.stale(String this.key, T this.value)
      : type = CacheEventType.stale;

  /// The cache was cleared.
  const CacheEvent.cleared()
      : type = CacheEventType.cleared,
        key = null,
        value = null;

  /// The type of event.
  final CacheEventType type;

  /// The affected key (null for cleared events).
  final String? key;

  /// The affected value (null for cleared/miss events).
  final T? value;

  @override
  String toString() => 'CacheEvent($type, $key)';
}
