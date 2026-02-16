import 'package:velox_cache/src/models/cache_entry.dart';

/// A Least Recently Used (LRU) cache.
///
/// When the cache reaches [maxSize], the least recently accessed entry
/// is evicted to make room for new entries.
///
/// ```dart
/// final cache = LruCache<String>(maxSize: 100);
/// cache.put('user:1', 'John');
/// final value = cache.get('user:1'); // 'John'
/// ```
class LruCache<T> {
  /// Creates an [LruCache] with the given [maxSize].
  LruCache({required this.maxSize}) : assert(maxSize > 0, 'maxSize must be positive');

  /// Maximum number of entries in the cache.
  final int maxSize;

  final Map<String, CacheEntry<T>> _entries = {};

  /// Returns the number of entries in the cache.
  int get size => _entries.length;

  /// Returns `true` if the cache is empty.
  bool get isEmpty => _entries.isEmpty;

  /// Returns `true` if the cache is not empty.
  bool get isNotEmpty => _entries.isNotEmpty;

  /// Returns `true` if the cache is full.
  bool get isFull => size >= maxSize;

  /// Gets a value by [key], or `null` if not found.
  T? get(String key) {
    final entry = _entries[key];
    if (entry == null) return null;
    entry.touch();
    return entry.value;
  }

  /// Puts a [value] in the cache with the given [key].
  void put(String key, T value) {
    if (_entries.containsKey(key)) {
      _entries[key] = CacheEntry(
        key: key,
        value: value,
        createdAt: DateTime.now(),
      );
      return;
    }

    if (isFull) {
      _evictLru();
    }

    _entries[key] = CacheEntry(
      key: key,
      value: value,
      createdAt: DateTime.now(),
    );
  }

  /// Removes a value by [key].
  T? remove(String key) {
    final entry = _entries.remove(key);
    return entry?.value;
  }

  /// Returns `true` if the cache contains [key].
  bool containsKey(String key) => _entries.containsKey(key);

  /// Returns all keys in the cache.
  Iterable<String> get keys => _entries.keys;

  /// Clears all entries from the cache.
  void clear() => _entries.clear();

  /// Gets a value or computes it if absent.
  T getOrPut(String key, T Function() ifAbsent) {
    final existing = get(key);
    if (existing != null) return existing;

    final value = ifAbsent();
    put(key, value);
    return value;
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
      _entries.remove(lruKey);
    }
  }
}
