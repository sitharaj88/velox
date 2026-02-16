import 'dart:async';
import 'dart:convert';

import 'package:velox_core/velox_core.dart';
import 'package:velox_storage/src/adapters/storage_adapter.dart';
import 'package:velox_storage/src/models/batch_operation.dart';
import 'package:velox_storage/src/models/storage_entry.dart';
import 'package:velox_storage/src/models/storage_statistics.dart';
import 'package:velox_storage/src/observers/storage_observer.dart';

/// A type-safe key-value storage with reactive change notifications.
///
/// Supports:
/// - Type-safe read/write for String, int, double, bool, JSON, and List
/// - Reactive change streams via [onChange]
/// - Batch operations with rollback on failure
/// - Import/export for backup and restore
/// - Storage observers for monitoring operations
/// - Storage statistics for hit/miss rates and operation counts
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
///
/// // Batch operations
/// await storage.batch([
///   BatchOperation.write(key: 'a', value: '1'),
///   BatchOperation.write(key: 'b', value: '2'),
///   BatchOperation.remove(key: 'old'),
/// ]);
/// ```
class VeloxStorage {
  /// Creates a [VeloxStorage] with the given [adapter].
  VeloxStorage({required this.adapter});

  /// The underlying storage adapter.
  final StorageAdapter adapter;

  final StreamController<StorageEntry> _changeController =
      StreamController<StorageEntry>.broadcast();

  final List<StorageObserver> _observers = [];

  final StorageStatistics _statistics = StorageStatistics();

  /// A stream of storage change events.
  Stream<StorageEntry> get onChange => _changeController.stream;

  /// Storage statistics for monitoring read/write patterns.
  StorageStatistics get statistics => _statistics;

  // --- Observers ---

  /// Adds an observer to monitor storage operations.
  void addObserver(StorageObserver observer) {
    _observers.add(observer);
  }

  /// Removes a previously added observer.
  void removeObserver(StorageObserver observer) {
    _observers.remove(observer);
  }

  // --- String ---

  /// Reads a string value.
  Future<String?> getString(String key) async {
    final value = await adapter.read(key);
    _statistics.recordRead(hit: value != null);
    for (final observer in _observers) {
      observer.onRead(key, value: value);
    }
    return value;
  }

  /// Writes a string value.
  Future<void> setString(String key, String value) async {
    await adapter.write(key, value);
    _statistics.recordWrite();
    for (final observer in _observers) {
      observer.onWrite(key, value);
    }
    _changeController.add(StorageEntry(key: key, value: value));
  }

  // --- Int ---

  /// Reads an integer value.
  Future<int?> getInt(String key) async {
    final value = await adapter.read(key);
    _statistics.recordRead(hit: value != null);
    for (final observer in _observers) {
      observer.onRead(key, value: value);
    }
    return value != null ? int.tryParse(value) : null;
  }

  /// Writes an integer value.
  Future<void> setInt(String key, int value) =>
      setString(key, value.toString());

  // --- Double ---

  /// Reads a double value.
  Future<double?> getDouble(String key) async {
    final value = await adapter.read(key);
    _statistics.recordRead(hit: value != null);
    for (final observer in _observers) {
      observer.onRead(key, value: value);
    }
    return value != null ? double.tryParse(value) : null;
  }

  /// Writes a double value.
  Future<void> setDouble(String key, double value) =>
      setString(key, value.toString());

  // --- Bool ---

  /// Reads a boolean value.
  Future<bool?> getBool(String key) async {
    final value = await adapter.read(key);
    _statistics.recordRead(hit: value != null);
    for (final observer in _observers) {
      observer.onRead(key, value: value);
    }
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
    _statistics.recordRead(hit: value != null);
    for (final observer in _observers) {
      observer.onRead(key, value: value);
    }
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
    _statistics.recordRead(hit: value != null);
    for (final observer in _observers) {
      observer.onRead(key, value: value);
    }
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
    _statistics.recordRemove();
    for (final observer in _observers) {
      observer.onRemove(key);
    }
    _changeController.add(StorageEntry(key: key));
  }

  /// Returns `true` if [key] exists in storage.
  Future<bool> containsKey(String key) => adapter.containsKey(key);

  /// Returns all keys in storage.
  Future<List<String>> keys() => adapter.keys();

  /// Clears all values from storage.
  Future<void> clear() async {
    await adapter.clear();
    _statistics.recordClear();
    for (final observer in _observers) {
      observer.onClear();
    }
    _changeController.add(const StorageEntry(key: '*'));
  }

  /// Reads a string or returns a [Failure] if not found.
  Future<Result<String, VeloxStorageException>> getOrFail(String key) async {
    final value = await adapter.read(key);
    _statistics.recordRead(hit: value != null);
    for (final observer in _observers) {
      observer.onRead(key, value: value);
    }
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

  // --- Batch Operations ---

  /// Executes a list of operations atomically.
  ///
  /// If any operation fails, all previously applied operations in this batch
  /// are rolled back and a [VeloxStorageException] is thrown.
  ///
  /// ```dart
  /// await storage.batch([
  ///   BatchOperation.write(key: 'name', value: 'John'),
  ///   BatchOperation.write(key: 'age', value: '30'),
  ///   BatchOperation.remove(key: 'temp'),
  /// ]);
  /// ```
  Future<void> batch(List<BatchOperation> operations) async {
    for (final observer in _observers) {
      observer.onBatchStart();
    }

    // Snapshot current values for rollback
    final rollbackData = <String, String?>{};
    for (final op in operations) {
      final key = switch (op) {
        BatchWrite(:final key) => key,
        BatchRemove(:final key) => key,
      };
      rollbackData[key] = await adapter.read(key);
    }

    try {
      for (final op in operations) {
        switch (op) {
          case BatchWrite(:final key, :final value):
            await adapter.write(key, value);
            _statistics.recordWrite();
            for (final observer in _observers) {
              observer.onWrite(key, value);
            }
            _changeController.add(StorageEntry(key: key, value: value));
          case BatchRemove(:final key):
            await adapter.remove(key);
            _statistics.recordRemove();
            for (final observer in _observers) {
              observer.onRemove(key);
            }
            _changeController.add(StorageEntry(key: key));
        }
      }

      for (final observer in _observers) {
        observer.onBatchComplete(
          operationCount: operations.length,
          success: true,
        );
      }
    } on Exception catch (e) {
      // Rollback
      for (final entry in rollbackData.entries) {
        if (entry.value != null) {
          await adapter.write(entry.key, entry.value!);
        } else {
          await adapter.remove(entry.key);
        }
      }

      for (final observer in _observers) {
        observer.onBatchComplete(
          operationCount: operations.length,
          success: false,
        );
      }

      throw VeloxStorageException(
        message: 'Batch operation failed, rolled back',
        code: 'BATCH_FAILED',
        cause: e,
      );
    }
  }

  // --- Import / Export ---

  /// Exports all storage entries as a map.
  ///
  /// Useful for backup and debugging.
  Future<Map<String, String>> exportAll() async {
    final allKeys = await adapter.keys();
    final result = <String, String>{};
    for (final key in allKeys) {
      final value = await adapter.read(key);
      if (value != null) {
        result[key] = value;
      }
    }
    return result;
  }

  /// Imports entries from a map, overwriting existing values.
  ///
  /// Useful for restore and data migration.
  Future<void> importAll(Map<String, String> data) async {
    for (final entry in data.entries) {
      await adapter.write(entry.key, entry.value);
      _statistics.recordWrite();
      for (final observer in _observers) {
        observer.onWrite(entry.key, entry.value);
      }
      _changeController.add(
        StorageEntry(key: entry.key, value: entry.value),
      );
    }
  }

  /// Disposes of the storage and its adapter.
  Future<void> dispose() async {
    await _changeController.close();
    await adapter.dispose();
  }
}
