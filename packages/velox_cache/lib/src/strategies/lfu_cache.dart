import 'package:velox_cache/src/models/cache_entry.dart';

/// A Least Frequently Used (LFU) cache.
///
/// When the cache reaches [maxSize], the entry with the fewest accesses
/// is evicted. If multiple entries have the same access count, the least
/// recently accessed among them is evicted (LRU tiebreaker).
///
/// ```dart
/// final cache = LfuCache<String>(maxSize: 100);
/// cache.put('user:1', 'John');
/// cache.get('user:1'); // access count = 1
/// cache.get('user:1'); // access count = 2
/// ```
class LfuCache<T> {
  /// Creates an [LfuCache] with the given [maxSize].
  LfuCache({required this.maxSize})
      : assert(maxSize > 0, 'maxSize must be positive');

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
      _evictLfu();
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

  /// Returns the access count for [key], or `null` if not found.
  int? accessCount(String key) => _entries[key]?.accessCount;

  void _evictLfu() {
    if (_entries.isEmpty) return;

    String? lfuKey;
    int? minFrequency;
    DateTime? lfuTime;

    for (final entry in _entries.entries) {
      final count = entry.value.accessCount;
      final lastAccess = entry.value.lastAccessedAt;

      if (minFrequency == null ||
          count < minFrequency ||
          (count == minFrequency && lastAccess.isBefore(lfuTime!))) {
        lfuKey = entry.key;
        minFrequency = count;
        lfuTime = lastAccess;
      }
    }

    if (lfuKey != null) {
      _entries.remove(lfuKey);
    }
  }
}
