import 'dart:convert';

import 'package:velox_cache/src/models/cache_entry.dart';
import 'package:velox_cache/src/models/cache_stats.dart';
import 'package:velox_storage/velox_storage.dart';

/// A two-level cache with a fast L1 (in-memory) and persistent L2 (storage).
///
/// Reads cascade: L1 is checked first, then L2. On an L2 hit, the value
/// is promoted back to L1 for faster subsequent access.
///
/// Writes go to both L1 and L2 simultaneously.
///
/// ```dart
/// final cache = VeloxMultiLevelCache<String>(
///   l1MaxSize: 50,
///   l1Ttl: Duration(minutes: 5),
///   l2Storage: VeloxStorage(adapter: MemoryStorageAdapter()),
///   l2Ttl: Duration(hours: 1),
///   serialize: (v) => v,
///   deserialize: (s) => s,
/// );
///
/// await cache.put('key', 'value');
/// final value = await cache.get('key'); // L1 hit
/// ```
class VeloxMultiLevelCache<T> {
  /// Creates a [VeloxMultiLevelCache].
  VeloxMultiLevelCache({
    required this.l1MaxSize,
    required this.l1Ttl,
    required this.l2Storage,
    required this.l2Ttl,
    required this.serialize,
    required this.deserialize,
    this.storagePrefix = 'mlc:',
  }) : assert(l1MaxSize > 0, 'l1MaxSize must be positive');

  /// Maximum entries in the L1 (memory) cache.
  final int l1MaxSize;

  /// Default TTL for L1 entries.
  final Duration l1Ttl;

  /// The L2 backing storage.
  final VeloxStorage l2Storage;

  /// Default TTL for L2 entries.
  final Duration l2Ttl;

  /// Serializes a value to a string for L2 storage.
  final String Function(T value) serialize;

  /// Deserializes a string from L2 storage back to a value.
  final T Function(String data) deserialize;

  /// Prefix for L2 storage keys.
  final String storagePrefix;

  final Map<String, CacheEntry<T>> _l1 = {};

  /// Statistics for L1 cache.
  final VeloxCacheStats l1Stats = VeloxCacheStats();

  /// Statistics for L2 cache.
  final VeloxCacheStats l2Stats = VeloxCacheStats();

  /// Returns the number of L1 entries.
  int get l1Size => _l1.length;

  /// Gets a value by [key] with cascading read (L1 -> L2).
  Future<T?> get(String key) async {
    // Check L1
    final l1Entry = _l1[key];
    if (l1Entry != null && !l1Entry.isExpired) {
      l1Entry.touch();
      l1Stats.recordHit();
      return l1Entry.value;
    }

    // Remove expired L1 entry
    if (l1Entry != null) {
      _l1.remove(key);
      l1Stats.recordExpiration();
    }

    l1Stats.recordMiss();

    // Check L2
    final stored = await l2Storage.getString('$storagePrefix$key');
    if (stored == null) {
      l2Stats.recordMiss();
      return null;
    }

    try {
      final decoded = jsonDecode(stored) as Map<String, dynamic>;
      final expiresAtMs = decoded['expiresAt'] as int?;

      if (expiresAtMs != null &&
          DateTime.now().millisecondsSinceEpoch > expiresAtMs) {
        await l2Storage.remove('$storagePrefix$key');
        l2Stats
          ..recordMiss()
          ..recordExpiration();
        return null;
      }

      final value = deserialize(decoded['value'] as String);
      l2Stats.recordHit();

      // Promote to L1
      _putL1(key, value);

      return value;
    } on Object {
      l2Stats.recordMiss();
      return null;
    }
  }

  /// Puts a [value] in both L1 and L2.
  Future<void> put(String key, T value) async {
    _putL1(key, value);
    l1Stats.recordWrite();

    final expiresAt = DateTime.now().add(l2Ttl);
    final envelope = jsonEncode({
      'value': serialize(value),
      'expiresAt': expiresAt.millisecondsSinceEpoch,
    });
    await l2Storage.setString('$storagePrefix$key', envelope);
    l2Stats.recordWrite();
  }

  /// Removes a value from both L1 and L2.
  Future<T?> remove(String key) async {
    final entry = _l1.remove(key);
    await l2Storage.remove('$storagePrefix$key');
    return entry?.value;
  }

  /// Returns `true` if [key] exists in L1 or L2.
  Future<bool> containsKey(String key) async {
    final l1Entry = _l1[key];
    if (l1Entry != null && !l1Entry.isExpired) return true;

    return l2Storage.containsKey('$storagePrefix$key');
  }

  /// Clears both L1 and L2 caches.
  Future<void> clear() async {
    _l1.clear();
    final allKeys = await l2Storage.keys();
    for (final key in allKeys) {
      if (key.startsWith(storagePrefix)) {
        await l2Storage.remove(key);
      }
    }
  }

  /// Clears only the L1 (memory) cache.
  void clearL1() => _l1.clear();

  void _putL1(String key, T value) {
    if (!_l1.containsKey(key) && _l1.length >= l1MaxSize) {
      _evictLruFromL1();
    }

    final now = DateTime.now();
    _l1[key] = CacheEntry(
      key: key,
      value: value,
      createdAt: now,
      expiresAt: now.add(l1Ttl),
    );
  }

  void _evictLruFromL1() {
    if (_l1.isEmpty) return;

    String? lruKey;
    DateTime? lruTime;

    for (final entry in _l1.entries) {
      if (lruTime == null ||
          entry.value.lastAccessedAt.isBefore(lruTime)) {
        lruKey = entry.key;
        lruTime = entry.value.lastAccessedAt;
      }
    }

    if (lruKey != null) {
      _l1.remove(lruKey);
      l1Stats.recordEviction();
    }
  }
}
