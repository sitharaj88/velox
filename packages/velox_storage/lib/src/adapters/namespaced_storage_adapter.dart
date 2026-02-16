import 'package:velox_storage/src/adapters/storage_adapter.dart';

/// A storage adapter that prefixes all keys with a namespace.
///
/// Useful for separating different logical areas of storage
/// (e.g., user settings vs. app cache).
///
/// ```dart
/// final adapter = MemoryStorageAdapter();
/// final userAdapter = NamespacedStorageAdapter(
///   adapter: adapter,
///   namespace: 'user',
/// );
///
/// await userAdapter.write('name', 'John');
/// // Stored as 'user.name' in the underlying adapter
/// ```
class NamespacedStorageAdapter implements StorageAdapter {
  /// Creates a [NamespacedStorageAdapter].
  ///
  /// [adapter] is the underlying storage adapter.
  /// [namespace] is the prefix applied to all keys.
  /// [separator] is the character between namespace and key (default: '.').
  NamespacedStorageAdapter({
    required this.adapter,
    required this.namespace,
    this.separator = '.',
  });

  /// The underlying storage adapter.
  final StorageAdapter adapter;

  /// The namespace prefix.
  final String namespace;

  /// The separator between namespace and key.
  final String separator;

  /// Returns the prefixed key.
  String prefixedKey(String key) => '$namespace$separator$key';

  /// Returns true if the key belongs to this namespace.
  bool _isOwnKey(String key) => key.startsWith('$namespace$separator');

  /// Strips the namespace prefix from a key.
  String _stripPrefix(String key) =>
      key.substring(namespace.length + separator.length);

  @override
  Future<String?> read(String key) => adapter.read(prefixedKey(key));

  @override
  Future<void> write(String key, String value) =>
      adapter.write(prefixedKey(key), value);

  @override
  Future<void> remove(String key) => adapter.remove(prefixedKey(key));

  @override
  Future<List<String>> keys() async {
    final allKeys = await adapter.keys();
    return allKeys.where(_isOwnKey).map(_stripPrefix).toList();
  }

  @override
  Future<void> clear() async {
    final ownKeys = await keys();
    for (final key in ownKeys) {
      await adapter.remove(prefixedKey(key));
    }
  }

  @override
  Future<bool> containsKey(String key) =>
      adapter.containsKey(prefixedKey(key));

  @override
  Future<void> dispose() async {
    // Do NOT dispose the underlying adapter, as it may be shared.
  }
}
