import 'dart:convert';

import 'package:velox_core/velox_core.dart';
import 'package:velox_storage/src/adapters/storage_adapter.dart';

/// A typed storage adapter that handles serialization/deserialization
/// for custom objects.
///
/// Wraps a [StorageAdapter] and provides type-safe read/write for
/// objects that can be converted to/from JSON maps.
///
/// ```dart
/// final adapter = TypedStorageAdapter<User>(
///   adapter: MemoryStorageAdapter(),
///   toJson: (user) => {'name': user.name, 'age': user.age},
///   fromJson: (json) => User(name: json['name'], age: json['age']),
/// );
///
/// await adapter.writeTyped('user1', User(name: 'John', age: 30));
/// final user = await adapter.readTyped('user1');
/// ```
class TypedStorageAdapter<T> {
  /// Creates a [TypedStorageAdapter].
  ///
  /// [adapter] is the underlying storage adapter.
  /// [toJson] converts a value of type [T] to a JSON map.
  /// [fromJson] converts a JSON map back to type [T].
  TypedStorageAdapter({
    required this.adapter,
    required Map<String, dynamic> Function(T value) toJson,
    required T Function(Map<String, dynamic> json) fromJson,
  })  : _toJson = toJson,
        _fromJson = fromJson;

  /// The underlying storage adapter.
  final StorageAdapter adapter;

  final Map<String, dynamic> Function(T value) _toJson;
  final T Function(Map<String, dynamic> json) _fromJson;

  /// Writes a typed value to storage.
  Future<void> writeTyped(String key, T value) async {
    final json = _toJson(value);
    await adapter.write(key, jsonEncode(json));
  }

  /// Reads a typed value from storage.
  ///
  /// Returns `null` if the key does not exist.
  /// Returns `null` if deserialization fails.
  Future<T?> readTyped(String key) async {
    final raw = await adapter.read(key);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return _fromJson(json);
    } on FormatException {
      return null;
    }
  }

  /// Reads a typed value or returns a [Failure] if not found.
  Future<Result<T, VeloxStorageException>> readTypedOrFail(String key) async {
    final value = await readTyped(key);
    if (value == null) {
      return Failure(
        VeloxStorageException(
          message: 'Key not found or deserialization failed: $key',
          key: key,
          code: 'TYPED_READ_FAILED',
        ),
      );
    }
    return Success(value);
  }

  /// Writes multiple typed values atomically.
  Future<void> writeAll(Map<String, T> entries) async {
    for (final entry in entries.entries) {
      await writeTyped(entry.key, entry.value);
    }
  }

  /// Reads all typed values for the given keys.
  ///
  /// Keys that don't exist or fail deserialization are excluded.
  Future<Map<String, T>> readAll(List<String> keys) async {
    final results = <String, T>{};
    for (final key in keys) {
      final value = await readTyped(key);
      if (value != null) {
        results[key] = value;
      }
    }
    return results;
  }

  /// Removes a key from storage.
  Future<void> remove(String key) => adapter.remove(key);

  /// Checks if a key exists in storage.
  Future<bool> containsKey(String key) => adapter.containsKey(key);
}
