import 'dart:convert';

import 'package:velox_cache/src/models/cache_entry.dart';
import 'package:velox_storage/velox_storage.dart';

/// A write-through cache that persists entries to a [VeloxStorage] backend.
///
/// On every [put], the value is written to both the in-memory cache and the
/// backing storage. On [get], the in-memory cache is checked first; if the
/// key is not found, the backing storage is consulted.
///
/// Values are serialized to/from JSON strings using the provided [serialize]
/// and [deserialize] functions.
///
/// ```dart
/// final cache = WriteThroughCache<Map<String, dynamic>>(
///   storage: VeloxStorage(adapter: MemoryStorageAdapter()),
///   maxSize: 100,
///   defaultTtl: Duration(minutes: 10),
///   serialize: (v) => jsonEncode(v),
///   deserialize: (s) => jsonDecode(s) as Map<String, dynamic>,
/// );
///
/// await cache.put('user:1', {'name': 'John'});
/// final user = await cache.get('user:1');
/// ```
class WriteThroughCache<T> {
  /// Creates a [WriteThroughCache].
  WriteThroughCache({
    required this.storage,
    required this.maxSize,
    required this.defaultTtl,
    required this.serialize,
    required this.deserialize,
    this.storagePrefix = 'wtc:',
  }) : assert(maxSize > 0, 'maxSize must be positive');

  /// The backing storage.
  final VeloxStorage storage;

  /// Maximum number of entries in the memory cache.
  final int maxSize;

  /// Default time-to-live for entries.
  final Duration defaultTtl;

  /// Serializes a value to a string for storage.
  final String Function(T value) serialize;

  /// Deserializes a string from storage back to a value.
  final T Function(String data) deserialize;

  /// Prefix for storage keys to avoid collisions.
  final String storagePrefix;

  final Map<String, CacheEntry<T>> _entries = {};

  /// Returns the number of in-memory entries.
  int get size => _entries.length;

  /// Gets a value by [key].
  ///
  /// Checks the in-memory cache first. On a miss, falls through to
  /// the backing storage.
  Future<T?> get(String key) async {
    // Check memory cache first
    final entry = _entries[key];
    if (entry != null && !entry.isExpired) {
      entry.touch();
      return entry.value;
    }

    // Remove expired entry from memory
    if (entry != null && entry.isExpired) {
      _entries.remove(key);
    }

    // Fall through to storage
    final stored = await storage.getString('$storagePrefix$key');
    if (stored == null) return null;

    try {
      final decoded = jsonDecode(stored) as Map<String, dynamic>;
      final expiresAtMs = decoded['expiresAt'] as int?;

      if (expiresAtMs != null &&
          DateTime.now().millisecondsSinceEpoch > expiresAtMs) {
        // Expired in storage - clean up
        await storage.remove('$storagePrefix$key');
        return null;
      }

      final value = deserialize(decoded['value'] as String);

      // Re-populate memory cache
      final now = DateTime.now();
      final remainingTtl = expiresAtMs != null
          ? Duration(
              milliseconds: expiresAtMs - now.millisecondsSinceEpoch,
            )
          : defaultTtl;

      _putInMemory(key, value, ttl: remainingTtl);
      return value;
    } on Object {
      return null;
    }
  }

  /// Puts a [value] in both memory and backing storage.
  Future<void> put(String key, T value, {Duration? ttl}) async {
    final effectiveTtl = ttl ?? defaultTtl;
    _putInMemory(key, value, ttl: effectiveTtl);

    final expiresAt = DateTime.now().add(effectiveTtl);
    final envelope = jsonEncode({
      'value': serialize(value),
      'expiresAt': expiresAt.millisecondsSinceEpoch,
    });
    await storage.setString('$storagePrefix$key', envelope);
  }

  /// Removes a value from both memory and backing storage.
  Future<T?> remove(String key) async {
    final entry = _entries.remove(key);
    await storage.remove('$storagePrefix$key');
    return entry?.value;
  }

  /// Clears all entries from both memory and backing storage.
  ///
  /// Only clears storage keys with the [storagePrefix].
  Future<void> clear() async {
    _entries.clear();
    final allKeys = await storage.keys();
    for (final key in allKeys) {
      if (key.startsWith(storagePrefix)) {
        await storage.remove(key);
      }
    }
  }

  void _putInMemory(String key, T value, {Duration? ttl}) {
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
