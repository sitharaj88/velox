import 'dart:async';
import 'dart:convert';

import 'package:velox_core/velox_core.dart';
import 'package:velox_storage/src/adapters/storage_adapter.dart';
import 'package:velox_storage/src/models/storage_entry.dart';

/// A type-safe key-value storage with reactive change notifications.
///
/// ```dart
/// final storage = VeloxStorage(adapter: MemoryStorageAdapter());
///
/// await storage.setString('name', 'John');
/// final name = await storage.getString('name'); // 'John'
///
/// // Listen for changes
/// storage.onChange.listen((entry) {
///   print('${entry.key} changed to ${entry.value}');
/// });
/// ```
class VeloxStorage {
  /// Creates a [VeloxStorage] with the given [adapter].
  VeloxStorage({required this.adapter});

  /// The underlying storage adapter.
  final StorageAdapter adapter;

  final StreamController<StorageEntry> _changeController =
      StreamController<StorageEntry>.broadcast();

  /// A stream of storage change events.
  Stream<StorageEntry> get onChange => _changeController.stream;

  // --- String ---

  /// Reads a string value.
  Future<String?> getString(String key) => adapter.read(key);

  /// Writes a string value.
  Future<void> setString(String key, String value) async {
    await adapter.write(key, value);
    _changeController.add(StorageEntry(key: key, value: value));
  }

  // --- Int ---

  /// Reads an integer value.
  Future<int?> getInt(String key) async {
    final value = await adapter.read(key);
    return value != null ? int.tryParse(value) : null;
  }

  /// Writes an integer value.
  Future<void> setInt(String key, int value) =>
      setString(key, value.toString());

  // --- Double ---

  /// Reads a double value.
  Future<double?> getDouble(String key) async {
    final value = await adapter.read(key);
    return value != null ? double.tryParse(value) : null;
  }

  /// Writes a double value.
  Future<void> setDouble(String key, double value) =>
      setString(key, value.toString());

  // --- Bool ---

  /// Reads a boolean value.
  Future<bool?> getBool(String key) async {
    final value = await adapter.read(key);
    if (value == null) return null;
    return value == 'true';
  }

  /// Writes a boolean value.
  Future<void> setBool(String key, {required bool value}) =>
      setString(key, value.toString());

  // --- JSON ---

  /// Reads a JSON-decoded value.
  Future<Map<String, dynamic>?> getJson(String key) async {
    final value = await adapter.read(key);
    if (value == null) return null;
    try {
      return jsonDecode(value) as Map<String, dynamic>;
    } on FormatException {
      return null;
    }
  }

  /// Writes a JSON-encoded value.
  Future<void> setJson(String key, Map<String, dynamic> value) =>
      setString(key, jsonEncode(value));

  // --- List ---

  /// Reads a list of strings.
  Future<List<String>?> getStringList(String key) async {
    final value = await adapter.read(key);
    if (value == null) return null;
    try {
      final decoded = jsonDecode(value) as List<dynamic>;
      return decoded.cast<String>();
    } on FormatException {
      return null;
    }
  }

  /// Writes a list of strings.
  Future<void> setStringList(String key, List<String> value) =>
      setString(key, jsonEncode(value));

  // --- General ---

  /// Removes a value by [key].
  Future<void> remove(String key) async {
    await adapter.remove(key);
    _changeController.add(StorageEntry(key: key));
  }

  /// Returns `true` if [key] exists in storage.
  Future<bool> containsKey(String key) => adapter.containsKey(key);

  /// Returns all keys in storage.
  Future<List<String>> keys() => adapter.keys();

  /// Clears all values from storage.
  Future<void> clear() async {
    await adapter.clear();
    _changeController.add(const StorageEntry(key: '*'));
  }

  /// Reads a string or returns [defaultValue] if not found.
  Future<Result<String, VeloxStorageException>> getOrFail(String key) async {
    final value = await adapter.read(key);
    if (value == null) {
      return Failure(
        VeloxStorageException(
          message: 'Key not found: $key',
          key: key,
          code: 'KEY_NOT_FOUND',
        ),
      );
    }
    return Success(value);
  }

  /// Disposes of the storage and its adapter.
  Future<void> dispose() async {
    await _changeController.close();
    await adapter.dispose();
  }
}
