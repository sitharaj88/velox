import 'package:velox_storage/src/adapters/storage_adapter.dart';
import 'package:velox_storage/src/models/ttl_entry.dart';

/// A storage adapter that supports time-to-live (TTL) on entries.
///
/// Wraps a [StorageAdapter] and stores values with an optional expiry time.
/// Expired entries are automatically removed when accessed.
///
/// ```dart
/// final adapter = TtlStorageAdapter(adapter: MemoryStorageAdapter());
///
/// // Write with 5-minute TTL
/// await adapter.writeWithTtl('session', 'token123',
///     ttl: Duration(minutes: 5));
///
/// // Read returns null if expired
/// final session = await adapter.read('session');
/// ```
class TtlStorageAdapter implements StorageAdapter {
  /// Creates a [TtlStorageAdapter].
  ///
  /// [adapter] is the underlying storage adapter.
  /// [defaultTtl] is applied to all writes unless overridden.
  TtlStorageAdapter({
    required this.adapter,
    this.defaultTtl,
  });

  /// The underlying storage adapter.
  final StorageAdapter adapter;

  /// Default TTL applied to all writes. `null` means no expiry by default.
  final Duration? defaultTtl;

  @override
  Future<String?> read(String key) async {
    final raw = await adapter.read(key);
    if (raw == null) return null;

    try {
      final entry = TtlEntry.fromJson(raw);
      if (entry.isExpired) {
        await adapter.remove(key);
        return null;
      }
      return entry.value;
    } on FormatException {
      // Not a TTL entry, return raw value for backwards compatibility
      return raw;
    }
  }

  @override
  Future<void> write(String key, String value) async {
    await writeWithTtl(key, value, ttl: defaultTtl);
  }

  /// Writes a value with a specific TTL.
  ///
  /// If [ttl] is null, the entry does not expire.
  Future<void> writeWithTtl(String key, String value, {Duration? ttl}) async {
    final expiresAt = ttl != null ? DateTime.now().add(ttl) : null;
    final entry = TtlEntry(value: value, expiresAt: expiresAt);
    await adapter.write(key, entry.toJson());
  }

  @override
  Future<void> remove(String key) => adapter.remove(key);

  @override
  Future<List<String>> keys() async {
    final allKeys = await adapter.keys();
    final validKeys = <String>[];

    for (final key in allKeys) {
      final raw = await adapter.read(key);
      if (raw == null) continue;

      try {
        final entry = TtlEntry.fromJson(raw);
        if (!entry.isExpired) {
          validKeys.add(key);
        } else {
          await adapter.remove(key);
        }
      } on FormatException {
        // Not a TTL entry, include it
        validKeys.add(key);
      }
    }

    return validKeys;
  }

  @override
  Future<void> clear() => adapter.clear();

  @override
  Future<bool> containsKey(String key) async {
    final value = await read(key);
    return value != null;
  }

  @override
  Future<void> dispose() => adapter.dispose();

  /// Removes all expired entries from storage.
  ///
  /// Returns the number of entries removed.
  Future<int> cleanupExpired() async {
    final allKeys = await adapter.keys();
    var removed = 0;

    for (final key in allKeys) {
      final raw = await adapter.read(key);
      if (raw == null) continue;

      try {
        final entry = TtlEntry.fromJson(raw);
        if (entry.isExpired) {
          await adapter.remove(key);
          removed++;
        }
      } on FormatException {
        // Not a TTL entry, skip it
      }
    }

    return removed;
  }
}
