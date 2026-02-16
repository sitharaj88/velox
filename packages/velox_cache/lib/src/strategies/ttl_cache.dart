import 'package:velox_cache/src/models/cache_entry.dart';

/// A cache with Time-To-Live (TTL) expiration.
///
/// Entries are automatically considered invalid after their TTL expires.
/// Expired entries are removed lazily on access.
///
/// ```dart
/// final cache = TtlCache<String>(defaultTtl: Duration(minutes: 5));
/// cache.put('token', 'abc123');
/// // After 5 minutes, cache.get('token') returns null
/// ```
class TtlCache<T> {
  /// Creates a [TtlCache] with the given [defaultTtl].
  TtlCache({required this.defaultTtl});

  /// Default time-to-live for entries.
  final Duration defaultTtl;

  final Map<String, CacheEntry<T>> _entries = {};

  /// Returns the number of valid (non-expired) entries.
  int get size {
    _removeExpired();
    return _entries.length;
  }

  /// Returns `true` if the cache is empty (all entries expired or removed).
  bool get isEmpty {
    _removeExpired();
    return _entries.isEmpty;
  }

  /// Gets a value by [key], or `null` if not found or expired.
  T? get(String key) {
    final entry = _entries[key];
    if (entry == null) return null;

    if (entry.isExpired) {
      _entries.remove(key);
      return null;
    }

    entry.touch();
    return entry.value;
  }

  /// Puts a [value] with optional custom [ttl].
  void put(String key, T value, {Duration? ttl}) {
    final now = DateTime.now();
    _entries[key] = CacheEntry(
      key: key,
      value: value,
      createdAt: now,
      expiresAt: now.add(ttl ?? defaultTtl),
    );
  }

  /// Removes a value by [key].
  T? remove(String key) {
    final entry = _entries.remove(key);
    return entry?.value;
  }

  /// Returns `true` if the cache contains a valid (non-expired) [key].
  bool containsKey(String key) {
    final entry = _entries[key];
    if (entry == null) return false;
    if (entry.isExpired) {
      _entries.remove(key);
      return false;
    }
    return true;
  }

  /// Returns all valid (non-expired) keys.
  Iterable<String> get keys {
    _removeExpired();
    return _entries.keys;
  }

  /// Clears all entries.
  void clear() => _entries.clear();

  /// Gets a value or computes it if absent or expired.
  T getOrPut(String key, T Function() ifAbsent, {Duration? ttl}) {
    final existing = get(key);
    if (existing != null) return existing;

    final value = ifAbsent();
    put(key, value, ttl: ttl);
    return value;
  }

  /// Removes all expired entries.
  void removeExpired() => _removeExpired();

  void _removeExpired() {
    _entries.removeWhere((_, entry) => entry.isExpired);
  }
}
