import 'dart:async';

import 'package:velox_cache/src/models/cache_entry.dart';

/// A combined cache with both LRU eviction and TTL expiration.
///
/// ```dart
/// final cache = VeloxCache<String>(
///   maxSize: 100,
///   defaultTtl: Duration(minutes: 5),
/// );
///
/// cache.put('user:1', 'John');
/// final value = cache.get('user:1'); // 'John'
///
/// // Listen for changes
/// cache.onChange.listen((event) {
///   print('${event.key}: ${event.type}');
/// });
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

  /// Stream of cache change events.
  Stream<CacheEvent<T>> get onChange => _changeController.stream;

  /// Returns the number of valid entries.
  int get size {
    _removeExpired();
    return _entries.length;
  }

  /// Returns `true` if the cache is empty.
  bool get isEmpty => size == 0;

  /// Gets a value by [key], or `null` if not found or expired.
  T? get(String key) {
    final entry = _entries[key];
    if (entry == null) return null;

    if (entry.isExpired) {
      _entries.remove(key);
      _changeController.add(CacheEvent.expired(key, entry.value));
      return null;
    }

    entry.touch();
    return entry.value;
  }

  /// Puts a [value] with optional custom [ttl].
  void put(String key, T value, {Duration? ttl}) {
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
    );

    _changeController.add(CacheEvent.put(key, value));
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
        _changeController.add(CacheEvent.expired(key, entry.value));
      }
    }
  }
}

/// Types of cache events.
enum CacheEventType {
  /// An entry was added or updated.
  put,

  /// An entry was manually removed.
  removed,

  /// An entry was evicted due to size limits.
  evicted,

  /// An entry expired.
  expired,

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

  /// An entry was put into the cache.
  const CacheEvent.put(String this.key, T this.value) : type = CacheEventType.put;

  /// An entry was manually removed.
  const CacheEvent.removed(String this.key, T this.value) : type = CacheEventType.removed;

  /// An entry was evicted.
  const CacheEvent.evicted(String this.key, T this.value) : type = CacheEventType.evicted;

  /// An entry expired.
  const CacheEvent.expired(String this.key, T this.value) : type = CacheEventType.expired;

  /// The cache was cleared.
  const CacheEvent.cleared() : type = CacheEventType.cleared, key = null, value = null;

  /// The type of event.
  final CacheEventType type;

  /// The affected key (null for cleared events).
  final String? key;

  /// The affected value (null for cleared events).
  final T? value;

  @override
  String toString() => 'CacheEvent($type, $key)';
}
