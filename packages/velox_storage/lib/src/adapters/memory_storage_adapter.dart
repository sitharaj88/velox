import 'package:velox_storage/src/adapters/storage_adapter.dart';

/// An in-memory storage adapter. Useful for testing.
///
/// Data is not persisted across app restarts.
class MemoryStorageAdapter implements StorageAdapter {
  final Map<String, String> _store = {};

  @override
  Future<String?> read(String key) async => _store[key];

  @override
  Future<void> write(String key, String value) async {
    _store[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    _store.remove(key);
  }

  @override
  Future<List<String>> keys() async => _store.keys.toList();

  @override
  Future<void> clear() async => _store.clear();

  @override
  Future<bool> containsKey(String key) async => _store.containsKey(key);

  @override
  Future<void> dispose() async => _store.clear();
}
