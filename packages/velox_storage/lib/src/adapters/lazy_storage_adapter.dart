import 'package:velox_storage/src/adapters/storage_adapter.dart';

/// A storage adapter that defers initialization until first access.
///
/// Useful when adapter creation is expensive (e.g., opening a database
/// or loading from disk) and you want to delay it until actually needed.
///
/// ```dart
/// final adapter = LazyStorageAdapter(
///   factory: () async => await HiveStorageAdapter.open('box'),
/// );
///
/// // The adapter is not created until the first read/write.
/// await adapter.read('key');
/// ```
class LazyStorageAdapter implements StorageAdapter {
  /// Creates a [LazyStorageAdapter].
  ///
  /// [factory] is called once to create the underlying adapter on first access.
  LazyStorageAdapter({required Future<StorageAdapter> Function() factory})
      : _factory = factory;

  final Future<StorageAdapter> Function() _factory;
  StorageAdapter? _adapter;
  Future<StorageAdapter>? _initFuture;

  /// Returns true if the underlying adapter has been initialized.
  bool get isInitialized => _adapter != null;

  /// Ensures the underlying adapter is initialized.
  Future<StorageAdapter> _ensureInitialized() async {
    if (_adapter != null) return _adapter!;

    // Prevent multiple simultaneous initializations
    final future = _initFuture ??= _factory();
    _adapter = await future;
    return _adapter!;
  }

  @override
  Future<String?> read(String key) async {
    final adapter = await _ensureInitialized();
    return adapter.read(key);
  }

  @override
  Future<void> write(String key, String value) async {
    final adapter = await _ensureInitialized();
    await adapter.write(key, value);
  }

  @override
  Future<void> remove(String key) async {
    final adapter = await _ensureInitialized();
    await adapter.remove(key);
  }

  @override
  Future<List<String>> keys() async {
    final adapter = await _ensureInitialized();
    return adapter.keys();
  }

  @override
  Future<void> clear() async {
    final adapter = await _ensureInitialized();
    await adapter.clear();
  }

  @override
  Future<bool> containsKey(String key) async {
    final adapter = await _ensureInitialized();
    return adapter.containsKey(key);
  }

  @override
  Future<void> dispose() async {
    if (_adapter != null) {
      await _adapter!.dispose();
      _adapter = null;
    }
    _initFuture = null;
  }
}
